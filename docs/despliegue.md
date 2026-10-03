# Despliegue y costo

GuitarCoach guarda el esquema en este repositorio y el cómputo en Cloud Run. La base de datos no viaja dentro de la imagen del backend: el servicio solo recibe `DATABASE_URL`.

## Variables

| Variable | Uso |
| --- | --- |
| `POSTGRES_USER` | Usuario del Postgres local de `docker compose`. |
| `POSTGRES_PASSWORD` | Contraseña local. En producción vive en Secret Manager, no en el repositorio. |
| `POSTGRES_DB` | Nombre de la base. |
| `POSTGRES_PORT` | Puerto publicado en la máquina de desarrollo. Por defecto `54329`. |
| `DATABASE_URL` | URL libpq. El backend acepta el mismo valor con el esquema `postgresql+asyncpg`. |

No subas un archivo `.env`. `.env.example` solo documenta el entorno local.

## Variante gratuita

Cloud SQL no tiene una capa gratuita permanente: la instancia se cobra aunque no reciba tráfico. Para un despliegue sostenido sin ese costo, el diseño admite cambiar solo la URL y el proveedor, sin cambiar el SQL:

1. Créditos iniciales de GCP para Cloud SQL durante la evaluación, con alerta de presupuesto.
2. PostgreSQL gestionado con capa gratuita, por ejemplo Neon o Supabase, conectado desde Cloud Run. El driver sigue siendo PostgreSQL 16 y las migraciones de esta carpeta se aplican igual.
3. El tutor de IA usa la API de Gemini con capa gratuita en lugar de Vertex AI. Esa clave no pertenece a este repositorio; la configura el backend.

Antes de elegir, revisa los límites vigentes. Las capas gratuitas cambian.

## Alertas de presupuesto

En Cloud Billing crea un presupuesto del proyecto con alertas al 50 %, 90 % y 100 % del tope que puedas asumir (para una demo académica, un tope bajo basta). Además:

- Cloud Run del backend y del frontend con `min-instances=0` y `max-instances` bajo.
- Límite diario de informes de IA por usuario, aplicado en el backend.
- Caché de canciones (`songs.source_url`, `songs.content_hash`) y de informes (`reports.metrics_hash`) para no repetir scraping ni llamadas al modelo.

Si la alerta del 90 % se dispara, detén las revisiones de Cloud Run y no levantes Cloud SQL «por si acaso».
