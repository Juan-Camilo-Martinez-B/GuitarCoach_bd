"""Pruebas de restricciones contra PostgreSQL."""

from __future__ import annotations

import os
import sys
from pathlib import Path

import psycopg
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from migration_lib import connect, reset  # noqa: E402
from verify import missing_objects  # noqa: E402

pytestmark = pytest.mark.skipif(
    not os.environ.get("DATABASE_URL"),
    reason="DATABASE_URL no está definida",
)


@pytest.fixture()
def database():
    connection = connect()
    reset(connection)
    try:
        yield connection
    finally:
        connection.close()


def test_el_esquema_tiene_las_tablas_y_extensiones(database) -> None:
    assert missing_objects(database) == []


def test_rechaza_un_correo_duplicado_sin_importar_mayusculas(database) -> None:
    database.execute(
        """
        INSERT INTO users (email, password_hash, display_name)
        VALUES ('alumno@example.com', 'hash', 'Ana')
        """
    )
    with pytest.raises(psycopg.Error):
        database.execute(
            """
            INSERT INTO users (email, password_hash, display_name)
            VALUES ('Alumno@example.com', 'hash', 'Ana')
            """
        )
        database.commit()
    database.rollback()


def test_rechaza_un_nivel_desconocido(database) -> None:
    with pytest.raises(psycopg.Error):
        database.execute(
            """
            INSERT INTO users (email, password_hash, display_name, level)
            VALUES ('otro@example.com', 'hash', 'Ana', 'expert')
            """
        )
    database.rollback()


def test_permite_oauth_sin_contrasena_y_rechaza_un_usuario_sin_metodo(database) -> None:
    database.execute(
        """
        INSERT INTO users (email, display_name, oauth_subject)
        VALUES ('oauth@example.com', 'OAuth', 'google-subject-1')
        """
    )
    database.commit()
    with pytest.raises(psycopg.Error):
        database.execute(
            """
            INSERT INTO users (email, display_name)
            VALUES ('nadie@example.com', 'Nadie')
            """
        )
    database.rollback()


def test_rechaza_acordes_mal_formados_y_un_bpm_imposible(database) -> None:
    with pytest.raises(psycopg.Error):
        database.execute(
            """
            INSERT INTO songs (title, artist, bpm, chords)
            VALUES ('Mala', 'Nadie', 80, '[{"bar": 1}]'::jsonb)
            """
        )
    database.rollback()
    with pytest.raises(psycopg.Error):
        database.execute(
            """
            INSERT INTO songs (title, artist, bpm, chords)
            VALUES ('Rapida', 'Nadie', 400, '[{"bar": 1, "beat": 1, "chord": "C"}]'::jsonb)
            """
        )
    database.rollback()


def test_impide_borrar_una_cancion_con_intentos(database) -> None:
    database.execute(
        """
        INSERT INTO users (id, email, password_hash, display_name)
        VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'a@example.com', 'hash', 'Ana')
        """
    )
    database.execute(
        """
        INSERT INTO songs (title, artist, bpm, chords, content_hash)
        VALUES (
            'Canción',
            'Autor',
            90,
            '[{"bar": 1, "beat": 1, "chord": "Am"}]'::jsonb,
            'hash-cancion'
        )
        """
    )
    database.execute(
        """
        INSERT INTO attempts (user_id, song_id, bpm, accuracy, avg_delta_ms, raw_summary)
        SELECT
            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            id,
            90,
            50,
            10,
            '{"events": []}'::jsonb
        FROM songs
        WHERE content_hash = 'hash-cancion'
        """
    )
    database.commit()
    with pytest.raises(psycopg.Error):
        database.execute("DELETE FROM songs WHERE content_hash = 'hash-cancion'")
    database.rollback()


def test_la_ultima_migracion_se_puede_revertir_y_volver_a_aplicar(database) -> None:
    from migration_lib import applied_versions, migrate, rollback

    before = applied_versions(database)
    assert before
    rollback(database, 1)
    after_rollback = applied_versions(database)
    assert after_rollback == before[:-1]
    migrate(database)
    assert applied_versions(database) == before
