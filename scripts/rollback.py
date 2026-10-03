"""Revierte la última migración, o N si se pasa un entero."""

from migration_lib import main_rollback

if __name__ == "__main__":
    main_rollback()
