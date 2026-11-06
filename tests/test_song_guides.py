"""La guía es privada, idempotente por contenido y nunca guarda la letra."""

from __future__ import annotations

import os
import sys
from pathlib import Path

import psycopg
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from migration_lib import connect, reset  # noqa: E402

pytestmark = pytest.mark.skipif(
    not os.environ.get("DATABASE_URL"),
    reason="DATABASE_URL no está definida",
)

GUIDE = '{"version": 1, "sections": []}'


@pytest.fixture()
def owner():
    connection = connect()
    reset(connection)
    row = connection.execute(
        """
        INSERT INTO users (email, password_hash, display_name)
        VALUES ('guia@example.com', 'hash', 'Ana')
        RETURNING id
        """
    ).fetchone()
    connection.commit()
    try:
        yield connection, row[0]
    finally:
        connection.close()


def _insert(connection, owner_id, guide: str = GUIDE, content_hash: str = "hash-1") -> None:
    connection.execute(
        """
        INSERT INTO song_guides (owner_id, title, artist, source_kind, guide, content_hash)
        VALUES (%s, 'Patio', 'Ana', 'pegado', %s::jsonb, %s)
        """,
        (owner_id, guide, content_hash),
    )


def test_guarda_una_guia_en_borrador(owner) -> None:
    connection, owner_id = owner
    _insert(connection, owner_id)
    status = connection.execute("SELECT status FROM song_guides").fetchone()[0]
    assert status == "borrador"


def test_rechaza_el_mismo_contenido_dos_veces_para_el_mismo_dueno(owner) -> None:
    connection, owner_id = owner
    _insert(connection, owner_id)
    with pytest.raises(psycopg.Error):
        _insert(connection, owner_id)
    connection.rollback()


def test_rechaza_una_guia_con_letra(owner) -> None:
    connection, owner_id = owner
    with pytest.raises(psycopg.Error):
        _insert(connection, owner_id, '{"version": 1, "sections": [], "lyrics": "la la"}')
    connection.rollback()


def test_rechaza_un_origen_desconocido(owner) -> None:
    connection, owner_id = owner
    with pytest.raises(psycopg.Error):
        connection.execute(
            """
            INSERT INTO song_guides (owner_id, title, artist, source_kind, guide, content_hash)
            VALUES (%s, 'Patio', 'Ana', 'scraping', %s::jsonb, 'hash-2')
            """,
            (owner_id, GUIDE),
        )
    connection.rollback()


def test_borrar_al_usuario_borra_sus_guias(owner) -> None:
    connection, owner_id = owner
    _insert(connection, owner_id)
    connection.execute("DELETE FROM users WHERE id = %s", (owner_id,))
    assert connection.execute("SELECT count(*) FROM song_guides").fetchone()[0] == 0


def _tab_guide(connection, owner_id) -> str:
    return connection.execute(
        """
        INSERT INTO song_guides (owner_id, title, artist, source_kind, guide, content_hash)
        VALUES (%s, 'Riff', 'Ana', 'tablatura', %s::jsonb, 'hash-tab')
        RETURNING id
        """,
        (owner_id, GUIDE),
    ).fetchone()[0]


def test_la_tablatura_se_guarda_aparte_y_se_borra_con_la_guia(owner) -> None:
    connection, owner_id = owner
    guide_id = _tab_guide(connection, owner_id)
    connection.execute(
        "INSERT INTO guide_tabs (guide_id, format, data) VALUES (%s, 'gp345', %s)",
        (guide_id, b"\x18FICHIER GUITAR PRO v5.00"),
    )
    connection.execute("DELETE FROM song_guides WHERE id = %s", (guide_id,))
    assert connection.execute("SELECT count(*) FROM guide_tabs").fetchone()[0] == 0


def test_rechaza_una_tablatura_vacia_o_de_formato_desconocido(owner) -> None:
    connection, owner_id = owner
    guide_id = _tab_guide(connection, owner_id)
    for tab_format, data in (("gp345", b""), ("pdf", b"%PDF")):
        with pytest.raises(psycopg.Error):
            connection.execute(
                "INSERT INTO guide_tabs (guide_id, format, data) VALUES (%s, %s, %s)",
                (guide_id, tab_format, data),
            )
        connection.rollback()
        guide_id = _tab_guide(connection, owner_id)
