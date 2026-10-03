"""La demostración se puede cargar más de una vez sin duplicar filas."""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from migration_lib import connect, reset  # noqa: E402
from seed_demo import apply_demo  # noqa: E402

pytestmark = pytest.mark.skipif(
    not os.environ.get("DATABASE_URL"),
    reason="DATABASE_URL no está definida",
)


def test_la_demostracion_es_idempotente() -> None:
    connection = connect()
    reset(connection)
    apply_demo(connection)
    apply_demo(connection)
    songs = connection.execute(
        "SELECT count(*) FROM songs WHERE content_hash LIKE 'demo-%'"
    ).fetchone()
    users = connection.execute(
        "SELECT count(*) FROM users WHERE email LIKE 'demo.%@example.com'"
    ).fetchone()
    connection.close()
    assert songs == (2,)
    assert users == (2,)
