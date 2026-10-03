"""Pruebas de la vista y de la función de transiciones."""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from migration_lib import connect, reset  # noqa: E402

pytestmark = pytest.mark.skipif(
    not os.environ.get("DATABASE_URL"),
    reason="DATABASE_URL no está definida",
)


@pytest.fixture()
def database():
    connection = connect()
    reset(connection)
    connection.execute(
        """
        INSERT INTO users (id, email, password_hash, display_name)
        VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'agregados@example.com', 'hash', 'Ana')
        """
    )
    connection.execute(
        """
        INSERT INTO songs (title, artist, bpm, chords, content_hash)
        VALUES (
            'Agregados',
            'Autor',
            80,
            '[{"bar": 1, "beat": 1, "chord": "G"}, {"bar": 2, "beat": 1, "chord": "C"}]'::jsonb,
            'hash-agregados'
        )
        """
    )
    connection.execute(
        """
        INSERT INTO attempts (id, user_id, song_id, bpm, accuracy, avg_delta_ms, raw_summary)
        SELECT
            'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            id,
            80,
            50,
            120,
            '{
                "events": [
                    {"expected": "G", "detected": "G"},
                    {"expected": "C", "detected": "Am"}
                ]
            }'::jsonb
        FROM songs
        WHERE content_hash = 'hash-agregados'
        """
    )
    connection.execute(
        """
        INSERT INTO chord_metrics (attempt_id, chord, accuracy, avg_delta_ms, errors)
        VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'C', 0, 120, 1)
        """
    )
    connection.commit()
    try:
        yield connection
    finally:
        connection.close()


def test_la_vista_resume_la_precision_por_acorde(database) -> None:
    row = database.execute(
        """
        SELECT sample_count, avg_accuracy, total_errors
        FROM chord_accuracy_summary
        WHERE chord = 'C'
        """
    ).fetchone()
    assert row == (1, 0, 1)


def test_detecta_la_transicion_problematica(database) -> None:
    row = database.execute(
        "SELECT from_chord, to_chord, error_count FROM problematic_transitions()"
    ).fetchone()
    assert row == ("G", "C", 1)
