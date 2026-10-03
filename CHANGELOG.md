# Changelog

## 1.0.0

Primera versión del esquema de GuitarCoach AI.

- PostgreSQL 16 local con Docker Compose.
- Migraciones reversibles para usuarios, canciones, intentos, métricas, informes y trabajos de scraping.
- Búsqueda aproximada con `pg_trgm`, caché por URL de origen y forma JSON obligatoria en los informes.
- Vista `chord_accuracy_summary` y función `problematic_transitions`.
- Semillas de desarrollo y de demostración, script de verificación y pruebas de restricciones en CI.
