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

## Estado

Fase 0 más las convenciones de este documento. Las migraciones y el Postgres local llegan en los commits siguientes de la Fase 1.
