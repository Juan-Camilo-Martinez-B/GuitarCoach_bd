# GuitarCoach Database

Esquema PostgreSQL 16 de GuitarCoach AI. Este repositorio es la fuente de verdad del modelo de datos. El backend se mapea a estas migraciones y no genera las suyas. El audio del estudiante no se almacena.

Las tablas de la aplicación viven en el esquema `guitarcoach`. El historial del ejecutor, `schema_migrations`, se queda en `public`.

| Documento | Qué explica |
| --- | --- |
| [schema/erd.md](schema/erd.md) | Entidades, claves y relaciones. |
| [docs/despliegue.md](docs/despliegue.md) | Postgres local, Supabase y qué no correr contra la nube. |
| [CHANGELOG.md](CHANGELOG.md) | Versión 1.0.0. |

## Cómo ejecutarlo

Requisitos: Docker y Python 3.12.

```powershell
copy .env.example .env
docker compose up -d
python -m pip install -r requirements-dev.txt
$env:DATABASE_URL = "postgresql://guitarcoach:guitarcoach@localhost:54329/guitarcoach"
python scripts/migrate.py
python scripts/seed.py
python scripts/seed_demo.py
python scripts/verify.py
pytest
```

`docker compose` levanta Postgres 16 en el puerto `54329` y Redis 7 en el `6379`. Redis no guarda datos de la app: el API lo usa solo para avisar que una importación terminó. La contraseña de desarrollo está en `.env.example` y no sirve para producción.

Otros comandos, siempre contra la base local:

```powershell
python scripts/rollback.py
python scripts/rollback.py 2
python scripts/reset.py
```

`reset.py` borra el esquema y lo vuelve a crear. No lo ejecutes contra Supabase.

## Esquema `guitarcoach`

La migración `0020_app_schema` crea el esquema, le quita el permiso a `PUBLIC` y mueve ahí las tablas de la app. Si una instalación nueva aplica `0001`–`0019` antes de que el esquema exista, esas migraciones crean los objetos en `public` y `0020` los traslada. Si ya están en `guitarcoach`, los movimientos de `0020` no hacen nada.

| Qué | Dónde queda |
| --- | --- |
| Tablas, vista `chord_accuracy_summary` y función `problematic_transitions()` | `guitarcoach` |
| `schema_migrations` | `public`, para que el ejecutor no cree un historial vacío al cambiar el `search_path` |
| Funciones de `pg_trgm` | `public`, porque la extensión se creó ahí. No se mueven. |

Cada tabla de `guitarcoach` tiene aislamiento por fila (`ROW LEVEL SECURITY`) y, si existen, los roles `anon`, `authenticated` y `service_role` pierden sus permisos. Esos roles son los de la API pública de Supabase. La API de GuitarCoach entra como dueño de las tablas (`postgres`), que atraviesa el aislamiento. Un cliente con la clave anónima no lee estas tablas.

El ejecutor de migraciones hace `SET search_path TO guitarcoach, public` y anota el historial en `public.schema_migrations`. El backend repite ese `search_path` en cada conexión y además declara `schema="guitarcoach"` en los modelos.

## Convenciones

- Cada cambio es un par `migrations/NNNN_descripcion.up.sql` y `.down.sql`.
- `up` aplica un cambio lógico y `down` lo revierte.
- El historial queda en `public.schema_migrations`.
- La búsqueda de canciones usa `pg_trgm`. Los identificadores de usuario, intento, informe, trabajo y guía son `uuid`. `songs.id` es un entero.

## Objetos que no son tablas

- Vista `guitarcoach.chord_accuracy_summary`: precisión, desfase y errores agrupados por acorde.
- Función `guitarcoach.problematic_transitions()`: pares de acordes consecutivos en los que el segundo no coincidió con lo esperado.

## Tablas de la app

El diagrama completo está en [schema/erd.md](schema/erd.md). El papel de cada grupo:

| Grupo | Tablas | Para qué |
| --- | --- | --- |
| Cuentas | `users` | Correo, hash, nombre, nivel y el ajuste de latencia. |
| Catálogo | `songs`, `user_songs`, `song_studies`, `scrape_jobs` | Canciones, favoritos, plan de estudio y la importación. |
| Práctica | `attempts`, `chord_metrics`, `reports` | El intento, el resumen por acorde y el informe. |
| Curso | `lesson_progress`, `study_checkins` | Lecciones hechas y el día en que el alumno vio el repaso. |
| Guías | `song_guides`, `guide_tabs` | El documento de estudio y el archivo de Guitar Pro, aparte para no arrastrar los bytes al listar. |
| Ruta | `journey_milestones`, `practice_days` | Pasos y días. La clave primaria hace idempotente el aviso del navegador. Los logros no se guardan: la API los calcula. |

Reglas que el esquema impone y la API no puede saltarse:

- `song_guides`: `UNIQUE (owner_id, content_hash)` y un `CHECK` que rechaza la clave `lyrics`.
- `guide_tabs`: 1:1 con la guía, formatos `gp`, `gp345`, `gpx`, `midi` o `musicxml`, entre 1 byte y 5 MB, `ON DELETE CASCADE`.
- `songs`: `content_hash` único y `source_url` único cuando existe, para no repetir una importación.

Las pruebas de este repositorio ejecutan `reset()`, que borra el esquema. Córrelas contra una base aparte:

```powershell
docker exec guitarcoach-database-postgres-1 psql -U guitarcoach -d guitarcoach -c "CREATE DATABASE guitarcoach_test"
$env:DATABASE_URL = "postgresql://guitarcoach:guitarcoach@localhost:54329/guitarcoach_test"
pytest
```

## Integración continua

`.github/workflows/ci.yml` levanta PostgreSQL 16, migra, revierte y comprueba restricciones, índices y semillas de demostración.
