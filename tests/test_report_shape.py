"""El informe solo se guarda con la forma que entiende el cliente."""

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

VALID_CONTENT = """
{
  "diagnostico": "El cambio a Am llega tarde.",
  "ejercicios": ["G a Am a 60 BPM."],
  "plan_semanal": ["Dia 1: metronomo."],
  "consejos_tecnica": ["Prepara el dedo 2."]
}
"""


def test_rechaza_un_informe_sin_la_forma_acordada() -> None:
    connection = connect()
    reset(connection)
    connection.execute(
        """
        INSERT INTO users (id, email, password_hash, display_name)
        VALUES ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'informe@example.com', 'hash', 'Ana')
        """
    )
    connection.execute(
        """
        INSERT INTO songs (title, artist, bpm, chords, content_hash)
        VALUES (
            'Informe',
            'Autor',
            80,
            '[{"bar": 1, "beat": 1, "chord": "Am"}]'::jsonb,
            'hash-informe'
        )
        """
    )
    connection.execute(
        """
        INSERT INTO attempts (id, user_id, song_id, bpm, accuracy, avg_delta_ms, raw_summary)
        SELECT
            'dddddddd-dddd-dddd-dddd-dddddddddddd',
            'cccccccc-cccc-cccc-cccc-cccccccccccc',
            id,
            80,
            40,
            20,
            '{"events": []}'::jsonb
        FROM songs
        WHERE content_hash = 'hash-informe'
        """
    )
    connection.commit()
    with pytest.raises(psycopg.Error):
        connection.execute(
            """
            INSERT INTO reports (attempt_id, content, model, metrics_hash)
            VALUES (
                'dddddddd-dddd-dddd-dddd-dddddddddddd',
                '{"diagnostico": "incompleto"}'::jsonb,
                'gemini',
                'hash'
            )
            """
        )
    connection.rollback()
    connection.execute(
        """
        INSERT INTO reports (attempt_id, content, model, metrics_hash)
        VALUES (
            'dddddddd-dddd-dddd-dddd-dddddddddddd',
            %s::jsonb,
            'gemini',
            'hash'
        )
        """,
        (VALID_CONTENT,),
    )
    connection.commit()
    connection.close()
