"""La URL de origen funciona como clave de caché."""

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


def test_rechaza_dos_canciones_con_la_misma_url() -> None:
    connection = connect()
    reset(connection)
    chords = '[{"bar": 1, "beat": 1, "chord": "C"}]'
    connection.execute(
        """
        INSERT INTO songs (title, artist, bpm, chords, source_url, content_hash)
        VALUES ('Una', 'Autor', 80, %s::jsonb, 'https://example.com/una', 'hash-una')
        """,
        (chords,),
    )
    with pytest.raises(psycopg.Error):
        connection.execute(
            """
            INSERT INTO songs (title, artist, bpm, chords, source_url, content_hash)
            VALUES ('Otra', 'Autor', 80, %s::jsonb, 'https://example.com/una', 'hash-otra')
            """,
            (chords,),
        )
    connection.close()
