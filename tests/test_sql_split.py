"""Pruebas del separador de sentencias, sin base de datos."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from migration_lib import _execute_script, paired_migrations, split_sql


def test_separa_sentencias_simples() -> None:
    statements = split_sql("SELECT 1;\nSELECT 2;")
    assert statements == ["SELECT 1", "SELECT 2"]


def test_ignora_punto_y_coma_dentro_de_cadenas_y_dollar_quotes() -> None:
    script = """
    CREATE FUNCTION demo() RETURNS text
    LANGUAGE sql
    AS $$
      SELECT 'a;b';
    $$;
    SELECT 1;
    """
    statements = split_sql(script)
    assert len(statements) == 2
    assert "SELECT 'a;b'" in statements[0]
    assert statements[1] == "SELECT 1"


def test_ignora_punto_y_coma_dentro_de_comentarios() -> None:
    statements = split_sql("-- nada;\nSELECT 1; -- fin\n")
    assert statements == ["-- nada;\nSELECT 1"]


def test_revierte_la_transaccion_si_una_sentencia_falla() -> None:
    class ConexionFalsa:
        def __init__(self) -> None:
            self.rolled_back = False

        def execute(self, statement: str, _params: object = None) -> None:
            if "FALLA" in statement:
                raise RuntimeError("sentencia rechazada")

        def rollback(self) -> None:
            self.rolled_back = True

    connection = ConexionFalsa()
    try:
        _execute_script(connection, "SELECT 1; SELECT FALLA;")
    except RuntimeError:
        assert connection.rolled_back
    else:
        raise AssertionError("debió propagar el error")


def test_pares_up_down_cuando_existen() -> None:
    for version, up_path, down_path in paired_migrations():
        assert up_path.name.startswith(version)
        assert down_path.exists()
