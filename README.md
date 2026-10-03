# GuitarCoach Database

Esquema PostgreSQL 16 de GuitarCoach AI. Este repositorio es la fuente de verdad del modelo de datos. El backend se mapea a estas migraciones y no genera las suyas.

El audio del estudiante no se almacena. Aquí viven usuarios, canciones, intentos, métricas por acorde, informes del tutor y trabajos de scraping.

## Cómo ejecutarlo

Requisitos: Docker y Python 3.12.

```powershell
docker compose up -d
python -m pip install -r requirements-dev.txt
$env:DATABASE_URL = "postgresql://guitarcoach:guitarcoach@localhost:54329/guitarcoach"
python scripts/migrate.py
python scripts/seed.py
python scripts/seed_demo.py
python scripts/verify.py
pytest
```

Otros comandos:

```powershell
python scripts/rollback.py
python scripts/rollback.py 2
python scripts/reset.py
```

El puerto local es `54329`. La contraseña de desarrollo está en `.env.example` y no sirve para producción.

## Convenciones

- Cada cambio es un par `migrations/NNNN_descripcion.up.sql` y `.down.sql`.
- `up` aplica un cambio lógico y `down` lo revierte.
- El historial queda en `schema_migrations`.
- La búsqueda de canciones usa `pg_trgm`. Los identificadores de usuario, intento, informe y trabajo son `uuid`.

## Objetos de consulta

- Vista `chord_accuracy_summary`: precisión, desfase y errores agrupados por acorde.
- Función `problematic_transitions()`: pares de acordes consecutivos en los que el segundo no coincidió con lo esperado.

El diagrama está en [schema/erd.md](schema/erd.md). Variables, variante gratuita de base de datos y alertas de presupuesto están en [docs/despliegue.md](docs/despliegue.md).

## Integración continua

`.github/workflows/ci.yml` levanta PostgreSQL 16, migra, revierte y comprueba restricciones, índices y semillas de demostración.
