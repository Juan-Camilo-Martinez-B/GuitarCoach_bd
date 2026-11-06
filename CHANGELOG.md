# Changelog

## Sin publicar

- Migración 0019: tablas `journey_milestones` y `practice_days` para guardar la ruta y la racha en la cuenta. Se borran con el usuario.
- Migración 0018: tabla `guide_tabs` (archivo de tablatura 1:1 con la guía, hasta 5 MB, se borra con ella) y origen `tablatura` en `song_guides`.
- Migración 0017: tabla `song_guides`, privada por dueño, idempotente por contenido y sin letra.

## 1.0.0

Primera versión del esquema de GuitarCoach AI.

- PostgreSQL 16 local con Docker Compose.
- Migraciones reversibles para usuarios, canciones, intentos, métricas, informes y trabajos de scraping.
- Búsqueda aproximada con `pg_trgm`, caché por URL de origen y forma JSON obligatoria en los informes.
- Vista `chord_accuracy_summary` y función `problematic_transitions`.
- Semillas de desarrollo y de demostración, script de verificación y pruebas de restricciones en CI.
