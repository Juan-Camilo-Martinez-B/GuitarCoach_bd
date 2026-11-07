# Despliegue

Este repositorio no se despliega como servicio. Publica el esquema. El cómputo es el API (Vercel o, con el workflow manual, Cloud Run) y solo recibe `DATABASE_URL`.

Hoy la base de producción es el proyecto Supabase de GuitarCoach. Postgres local de `docker compose` sirve para desarrollar y para la integración continua.

## Variables

| Variable | Uso |
| --- | --- |
| `POSTGRES_USER` | Usuario del Postgres de `docker compose`. En local, `guitarcoach`. |
| `POSTGRES_PASSWORD` | Contraseña local. En Supabase vive en el panel, no en el repositorio. |
| `POSTGRES_DB` | Nombre de la base. En Supabase es `postgres`. |
| `POSTGRES_PORT` | Puerto publicado en la máquina de desarrollo. Por defecto `54329`. |
| `REDIS_PORT` | Puerto del Redis local. Por defecto `6379`. |
| `DATABASE_URL` | URL libpq, con `?sslmode=require` cuando el host es Supabase. El backend usa el mismo destino con el esquema `postgresql+asyncpg` y sin ese parámetro: asyncpg no lo acepta y abre TLS por su cuenta. |

No subas un archivo `.env`. `.env.example` solo documenta el entorno local.

## Local

```powershell
copy .env.example .env
docker compose up -d
$env:DATABASE_URL = "postgresql://guitarcoach:guitarcoach@localhost:54329/guitarcoach"
python scripts/migrate.py
python scripts/verify.py
```

`verify.py` comprueba las tablas de la app dentro de `guitarcoach` y el historial en `public.schema_migrations`.

## Supabase

El host directo `db.<ref>.supabase.co` es solo IPv6 y en varias redes no resuelve. Usa el pooler de sesión:

```text
postgresql://postgres.<ref>:<clave>@aws-0-<región>.pooler.supabase.com:5432/postgres?sslmode=require
```

El puerto `5432` es el modo sesión y es el que deben usar las migraciones. El `6543` es modo transacción: sirve para consultas sueltas y rompe sentencias preparadas y migraciones largas. El usuario lleva el identificador del proyecto (`postgres.<ref>`). `postgres` a secas, en el pooler, no autentica.

Desde `guitarcoach-database`:

```powershell
$env:DATABASE_URL = "postgresql://postgres.<ref>:<clave>@aws-0-us-east-1.pooler.supabase.com:5432/postgres?sslmode=require"
python scripts/migrate.py
python scripts/verify.py
```

La segunda ejecución debe decir que no hay migraciones pendientes. `0020_app_schema` deja las tablas en `guitarcoach` con aislamiento por fila.

No ejecutes `reset.py` ni `seed_demo.py` contra esa base si ya tiene las cuentas y las prácticas reales. `reset.py` borra el esquema.

El backend apunta al mismo host y a la misma base, con `postgresql+asyncpg://` y `USE_DATABASE=true`. Su motor hace `SET search_path TO guitarcoach, public` en cada conexión.

## Qué vigilar del costo

Supabase y Groq tienen capas gratuitas con límites que cambian. Antes de dejar el proyecto abierto:

- Revisa el tope de la base y de la clave de Groq.
- El API ya limita los informes nuevos por usuario y día, y no repite una canción ni un informe si el hash coincide.
- No levantes un Postgres de pago «por si acaso» mientras el pooler de Supabase alcance.
