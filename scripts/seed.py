"""Carga semillas de desarrollo. No incluye datos de demostración."""

from pathlib import Path

from migration_lib import _execute_script, connect

SEEDS = Path(__file__).resolve().parents[1] / "seeds" / "dev.sql"


def main() -> None:
    script = SEEDS.read_text(encoding="utf-8")
    with connect() as connection:
        _execute_script(connection, script)
        connection.commit()
    print(f"Semillas aplicadas desde {SEEDS.name}.")


if __name__ == "__main__":
    main()
