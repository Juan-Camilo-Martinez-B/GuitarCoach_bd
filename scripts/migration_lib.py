"""Aplicación ordenada de migraciones SQL reversibles."""

from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MIGRATIONS_DIR = ROOT / "migrations"
HISTORY_TABLE = "schema_migrations"


def database_url() -> str:
    """Devuelve la URL libpq. Acepta el esquema asyncpg del backend y lo normaliza."""
    url = os.environ.get("DATABASE_URL", "").strip()
    if not url:
        raise SystemExit("DATABASE_URL no está definida. Copia .env.example a .env.")
    prefix = "postgresql+asyncpg://"
    if url.startswith(prefix):
        return "postgresql://" + url.removeprefix(prefix)
    return url


def split_sql(script: str) -> list[str]:
    """Parte un script en sentencias, respetando comillas, comentarios y dollar-quotes."""
    statements: list[str] = []
    current: list[str] = []
    index = 0
    length = len(script)
    state = "normal"
    dollar_tag = ""

    while index < length:
        char = script[index]
        nxt = script[index + 1] if index + 1 < length else ""

        if state == "normal":
            if char == "-" and nxt == "-":
                state = "line_comment"
                current.append(char)
            elif char == "/" and nxt == "*":
                state = "block_comment"
                current.append(char)
            elif char == "'":
                state = "single"
                current.append(char)
            elif char == '"':
                state = "double"
                current.append(char)
            elif char == "$":
                tag = _dollar_tag_at(script, index)
                if tag is not None:
                    state = "dollar"
                    dollar_tag = tag
                    current.append(tag)
                    index += len(tag)
                    continue
                current.append(char)
            elif char == ";":
                statement = "".join(current).strip()
                if _has_sql(statement):
                    statements.append(statement)
                current = []
            else:
                current.append(char)
        elif state == "line_comment":
            current.append(char)
            if char == "\n":
                state = "normal"
        elif state == "block_comment":
            current.append(char)
            if char == "*" and nxt == "/":
                current.append(nxt)
                index += 1
                state = "normal"
        elif state == "single":
            current.append(char)
            if char == "'" and nxt == "'":
                current.append(nxt)
                index += 1
            elif char == "'":
                state = "normal"
        elif state == "double":
            current.append(char)
            if char == '"':
                state = "normal"
        elif state == "dollar":
            if script.startswith(dollar_tag, index):
                current.append(dollar_tag)
                index += len(dollar_tag)
                state = "normal"
                continue
            current.append(char)
        index += 1

    tail = "".join(current).strip()
    if _has_sql(tail):
        statements.append(tail)
    return statements


def paired_migrations() -> list[tuple[str, Path, Path]]:
    """Lista pares up/down ordenados por versión."""
    if not MIGRATIONS_DIR.exists():
        return []
    pairs: list[tuple[str, Path, Path]] = []
    for up_path in sorted(MIGRATIONS_DIR.glob("*.up.sql")):
        version = up_path.name[: -len(".up.sql")]
        down_path = MIGRATIONS_DIR / f"{version}.down.sql"
        if not down_path.exists():
            raise SystemExit(f"Falta la migración inversa de {up_path.name}")
        pairs.append((version, up_path, down_path))
    return pairs


def applied_versions(connection: object) -> list[str]:
    rows = connection.execute(  # type: ignore[attr-defined]
        f"SELECT version FROM {HISTORY_TABLE} ORDER BY version"
    ).fetchall()
    return [row[0] for row in rows]


def migrate(connection: object) -> list[str]:
    """Aplica las migraciones pendientes y devuelve sus versiones."""
    _ensure_history(connection)
    done = set(applied_versions(connection))
    applied_now: list[str] = []
    for version, up_path, _down_path in paired_migrations():
        if version in done:
            continue
        _execute_script(connection, up_path.read_text(encoding="utf-8"))
        connection.execute(  # type: ignore[attr-defined]
            f"INSERT INTO {HISTORY_TABLE} (version) VALUES (%s)",
            (version,),
        )
        connection.commit()  # type: ignore[attr-defined]
        applied_now.append(version)
    return applied_now


def rollback(connection: object, steps: int) -> list[str]:
    """Revierte las últimas `steps` migraciones aplicadas."""
    if steps < 1:
        raise SystemExit("El número de pasos debe ser mayor que cero.")
    _ensure_history(connection)
    applied = applied_versions(connection)
    if steps > len(applied):
        raise SystemExit(
            f"Hay {len(applied)} migraciones aplicadas y se pidieron {steps} reversiones."
        )
    targets = list(reversed(applied[-steps:]))
    by_version = {version: (up, down) for version, up, down in paired_migrations()}
    reverted: list[str] = []
    for version in targets:
        if version not in by_version:
            raise SystemExit(f"No existe el archivo de {version} para revertirlo.")
        _down = by_version[version][1]
        _execute_script(connection, _down.read_text(encoding="utf-8"))
        connection.execute(  # type: ignore[attr-defined]
            f"DELETE FROM {HISTORY_TABLE} WHERE version = %s",
            (version,),
        )
        connection.commit()  # type: ignore[attr-defined]
        reverted.append(version)
    return reverted


def reset(connection: object) -> None:
    """Revierte todo y vuelve a migrar."""
    _ensure_history(connection)
    applied = applied_versions(connection)
    if applied:
        rollback(connection, len(applied))
    migrate(connection)


def connect() -> object:
    import psycopg

    return psycopg.connect(database_url())


def _ensure_history(connection: object) -> None:
    connection.execute(  # type: ignore[attr-defined]
        f"""
        CREATE TABLE IF NOT EXISTS {HISTORY_TABLE} (
            version TEXT PRIMARY KEY,
            applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )
        """
    )
    connection.commit()  # type: ignore[attr-defined]


def _execute_script(connection: object, script: str) -> None:
    try:
        for statement in split_sql(script):
            connection.execute(statement)  # type: ignore[attr-defined]
    except Exception:
        connection.rollback()  # type: ignore[attr-defined]
        raise


def _dollar_tag_at(script: str, index: int) -> str | None:
    if not script.startswith("$", index):
        return None
    end = index + 1
    while end < len(script) and (script[end].isalnum() or script[end] == "_"):
        end += 1
    if end < len(script) and script[end] == "$":
        return script[index : end + 1]
    return None


def _has_sql(statement: str) -> bool:
    for line in statement.splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("--"):
            return True
    return False


def main_migrate() -> None:
    with connect() as connection:
        applied = migrate(connection)
    if applied:
        print("Aplicadas:", ", ".join(applied))
    else:
        print("No hay migraciones pendientes.")


def main_rollback() -> None:
    steps = 1
    if len(sys.argv) > 1:
        steps = int(sys.argv[1])
    with connect() as connection:
        reverted = rollback(connection, steps)
    print("Revertidas:", ", ".join(reverted))


def main_reset() -> None:
    with connect() as connection:
        reset(connection)
    print("Esquema reiniciado.")
