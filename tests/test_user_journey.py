"""La ruta del principiante: pasos conocidos, sin repetidos y se borran con la cuenta."""

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


@pytest.fixture()
def owner():
    connection = connect()
    reset(connection)
    row = connection.execute(
        """
        INSERT INTO users (email, password_hash, display_name)
        VALUES ('ruta@example.com', 'hash', 'Ana')
        RETURNING id
        """
    ).fetchone()
    connection.commit()
    try:
        yield connection, row[0]
    finally:
        connection.close()


def test_rechaza_un_paso_desconocido(owner) -> None:
    connection, user_id = owner
    with pytest.raises(psycopg.errors.CheckViolation):
        connection.execute(
            "INSERT INTO journey_milestones (user_id, milestone) VALUES (%s, 'trampa')",
            (user_id,),
        )
    connection.rollback()


def test_un_dia_y_un_paso_no_se_repiten(owner) -> None:
    connection, user_id = owner
    connection.execute(
        "INSERT INTO practice_days (user_id, day) VALUES (%s, '2026-03-10')", (user_id,)
    )
    with pytest.raises(psycopg.errors.UniqueViolation):
        connection.execute(
            "INSERT INTO practice_days (user_id, day) VALUES (%s, '2026-03-10')", (user_id,)
        )
    connection.rollback()


def test_se_borra_con_la_cuenta(owner) -> None:
    connection, user_id = owner
    connection.execute(
        "INSERT INTO journey_milestones (user_id, milestone) VALUES (%s, 'afinar')", (user_id,)
    )
    connection.execute(
        "INSERT INTO practice_days (user_id, day) VALUES (%s, '2026-03-10')", (user_id,)
    )
    connection.execute("DELETE FROM users WHERE id = %s", (user_id,))
    assert connection.execute("SELECT count(*) FROM journey_milestones").fetchone()[0] == 0
    assert connection.execute("SELECT count(*) FROM practice_days").fetchone()[0] == 0
    connection.rollback()
