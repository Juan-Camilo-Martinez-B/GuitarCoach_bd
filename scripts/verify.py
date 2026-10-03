"""Comprueba que el esquema aplicado contiene los objetos del contrato."""

from migration_lib import connect

REQUIRED_TABLES = (
    "users",
    "songs",
    "user_songs",
    "attempts",
    "chord_metrics",
    "reports",
    "scrape_jobs",
    "schema_migrations",
)

REQUIRED_EXTENSIONS = ("pgcrypto", "pg_trgm")


def missing_objects(connection: object) -> list[str]:
    """Devuelve los nombres de tablas y extensiones que faltan."""
    missing: list[str] = []
    for extension in REQUIRED_EXTENSIONS:
        row = connection.execute(  # type: ignore[attr-defined]
            "SELECT 1 FROM pg_extension WHERE extname = %s",
            (extension,),
        ).fetchone()
        if row is None:
            missing.append(f"extension:{extension}")
    for table in REQUIRED_TABLES:
        row = connection.execute(  # type: ignore[attr-defined]
            """
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'public' AND table_name = %s
            """,
            (table,),
        ).fetchone()
        if row is None:
            missing.append(f"table:{table}")
    return missing


def main() -> None:
    with connect() as connection:
        missing = missing_objects(connection)
    if missing:
        raise SystemExit("Esquema incompleto: " + ", ".join(missing))
    print("Esquema verificado.")


if __name__ == "__main__":
    main()
