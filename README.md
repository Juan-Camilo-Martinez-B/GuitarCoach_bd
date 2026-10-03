# GuitarCoach Database

Esquema PostgreSQL 16 de GuitarCoach AI. Este repositorio es la fuente de verdad del modelo de datos. El backend se mapea a estas migraciones y no genera las suyas.

El audio del estudiante no se almacena. Solo viven aquí usuarios, canciones, intentos, métricas, informes y trabajos de scraping.

## Convenciones de migración

- Cada cambio va en un par `migrations/NNNN_descripcion.up.sql` y `migrations/NNNN_descripcion.down.sql`.
- `NNNN` es un correlativo de cuatro dígitos. El nombre describe un solo cambio lógico (una tabla, un índice o una restricción).
- `up` aplica el cambio y `down` lo revierte por completo.
- Las migraciones son SQL plano. No se usan migraciones generadas por un ORM.
- Toda tabla lleva claves primarias, foráneas, `CHECK` cuando la regla cabe en el esquema, e índices para las consultas previstas.
- La búsqueda de canciones usa `pg_trgm`. Los identificadores de usuario, intento, informe y trabajo usan `uuid` (`pgcrypto`).

## Postgres local

```bash
docker compose up -d
```

El puerto por defecto es `54329`, para no chocar con un PostgreSQL ya instalado. La contraseña de desarrollo está en `.env.example`. No uses esos valores en producción.

## Migraciones

Con el contenedor en marcha y `DATABASE_URL` exportada:

```bash
pip install -r requirements-dev.txt
python scripts/migrate.py
python scripts/rollback.py
python scripts/rollback.py 2
python scripts/reset.py
pytest tests/test_sql_split.py
```

En PowerShell, carga la variable antes de migrar:

```powershell
$env:DATABASE_URL = "postgresql://guitarcoach:guitarcoach@localhost:54329/guitarcoach"
python scripts/migrate.py
```

Los scripts registran la versión aplicada en `schema_migrations`. Cada archivo se ejecuta en su propia transacción confirmada al terminar.

Las semillas de desarrollo crean un alumno, una progresión de cuatro acordes y un intento. El hash de contraseña es un marcador, no una credencial usable:

```powershell
python scripts/seed.py
python scripts/seed_demo.py
```

`seed_demo.py` añade dos alumnos de demostración y una progresión con un intento. Se puede ejecutar otra vez sin duplicar filas. Los hash de contraseña son marcadores, no credenciales.

## Integración continua

El workflow `.github/workflows/ci.yml` levanta PostgreSQL 16, aplica las migraciones desde las pruebas y comprueba las restricciones.

En local, con el contenedor en marcha:

```powershell
$env:DATABASE_URL = "postgresql://guitarcoach:guitarcoach@localhost:54329/guitarcoach"
pip install -r requirements-dev.txt
pytest
python scripts/verify.py
```

## Estado

Fase 3: los usuarios aceptan contraseña u OAuth y guardan la calibración de latencia. Las pruebas de restricciones corren contra PostgreSQL.
