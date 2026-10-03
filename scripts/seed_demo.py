"""Carga un conjunto de demostración, repetible, sin credenciales reales."""

from pathlib import Path

from migration_lib import _execute_script, connect

DEMO_SEED = Path(__file__).resolve().parents[1] / "seeds" / "demo.sql"


def apply_demo(connection: object) -> None:
    _execute_script(connection, DEMO_SEED.read_text(encoding="utf-8"))
    connection.commit()  # type: ignore[attr-defined]


def main() -> None:
    with connect() as connection:
        apply_demo(connection)
    print("Datos de demostración aplicados.")


if __name__ == "__main__":
    main()
