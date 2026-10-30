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

## Guías de canciones

`song_guides` guarda la guía de estudio de una canción que eligió el usuario: secciones, acordes con su duración, rasgueo y melodía, en un documento `jsonb` versionado. Reglas del esquema:

- Cada guía es de un solo dueño (`owner_id`) y se borra con él.
- `UNIQUE (owner_id, content_hash)`: subir dos veces el mismo contenido no crea una copia.
- `song_guides_no_lyrics`: el documento no puede traer la clave `lyrics`. La letra tiene derechos de autor y no se guarda.
- `source_kind` dice de dónde salió (texto pegado, ChordPro, MusicXML, audio o editor) y `status` si es un borrador o ya está revisada.
- `song_id` enlaza la canción que usan los intentos y el informe.

Las pruebas de este repositorio ejecutan `reset()`, que borra el esquema. Córrelas contra una base aparte para no perder los datos locales:

```powershell
docker exec guitarcoach-database-postgres-1 psql -U guitarcoach -d guitarcoach -c "CREATE DATABASE guitarcoach_test"
$env:DATABASE_URL = "postgresql://guitarcoach:guitarcoach@localhost:54329/guitarcoach_test"
pytest
```

## Objetos de consulta

- Vista `chord_accuracy_summary`: precisión, desfase y errores agrupados por acorde.
- Función `problematic_transitions()`: pares de acordes consecutivos en los que el segundo no coincidió con lo esperado.

El diagrama está en [schema/erd.md](schema/erd.md). Variables, variante gratuita de base de datos y alertas de presupuesto están en [docs/despliegue.md](docs/despliegue.md).

## Integración continua

`.github/workflows/ci.yml` levanta PostgreSQL 16, migra, revierte y comprueba restricciones, índices y semillas de demostración.
