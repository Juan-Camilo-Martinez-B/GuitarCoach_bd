"""Los trabajos se consultan por estado y antigüedad."""

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


def test_existe_el_indice_de_estado() -> None:
    connection = connect()
    reset(connection)
    row = connection.execute(
        """
        SELECT 1
        FROM pg_indexes
        WHERE indexname = 'scrape_jobs_status_created_idx'
        """
    ).fetchone()
    connection.close()
    assert row is not None
