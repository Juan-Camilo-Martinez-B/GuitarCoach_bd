# Diagrama entidad-relación

Todas estas tablas están en el esquema `guitarcoach`. `public.schema_migrations` no aparece: es el historial del ejecutor, no un dato de la app. El audio no tiene tabla.

`song_key` evita la palabra reservada `key`. Los logros de la ruta no se guardan: la API los calcula a partir de intentos, guías, lecciones y días.

```mermaid
erDiagram
    USERS ||--o{ USER_SONGS : guarda
    SONGS ||--o{ USER_SONGS : incluye
    USERS ||--o{ ATTEMPTS : realiza
    SONGS ||--o{ ATTEMPTS : sobre
    ATTEMPTS ||--o{ CHORD_METRICS : resume
    ATTEMPTS ||--o| REPORTS : genera
    USERS ||--o{ SCRAPE_JOBS : pide
    SONGS ||--o{ SCRAPE_JOBS : origina
    SONGS ||--|| SONG_STUDIES : estudia
    USERS ||--o{ SONG_GUIDES : posee
    SONGS ||--o{ SONG_GUIDES : practica
    SONG_GUIDES ||--o| GUIDE_TABS : adjunta
    USERS ||--o{ LESSON_PROGRESS : completa
    USERS ||--o{ STUDY_CHECKINS : repasa
    USERS ||--o{ JOURNEY_MILESTONES : logra
    USERS ||--o{ PRACTICE_DAYS : practica

    USERS {
        uuid id
        text email
        text password_hash
        text display_name
        text oauth_subject
        text level
        int latency_offset_ms
    }
    SONGS {
        int id
        text title
        text artist
        text song_key
        int bpm
        jsonb chords
        text source_url
        text content_hash
    }
    USER_SONGS {
        uuid user_id
        int song_id
        bool is_favorite
        int practice_bpm
    }
    SONG_STUDIES {
        int song_id
        jsonb plan
    }
    ATTEMPTS {
        uuid id
        uuid user_id
        int song_id
        numeric accuracy
        jsonb raw_summary
    }
    CHORD_METRICS {
        int id
        uuid attempt_id
        text chord
        numeric accuracy
        int errors
    }
    REPORTS {
        uuid id
        uuid attempt_id
        jsonb content
        text metrics_hash
    }
    SCRAPE_JOBS {
        uuid id
        uuid user_id
        text status
        text query
        int song_id
    }
    SONG_GUIDES {
        uuid id
        uuid owner_id
        int song_id
        text title
        text source_kind
        text status
        jsonb guide
        text content_hash
    }
    GUIDE_TABS {
        uuid guide_id
        text format
        bytea data
    }
    LESSON_PROGRESS {
        uuid user_id
        text lesson_id
        text status
    }
    STUDY_CHECKINS {
        uuid user_id
        date reviewed_on
    }
    JOURNEY_MILESTONES {
        uuid user_id
        text milestone
    }
    PRACTICE_DAYS {
        uuid user_id
        date day
    }
```

`GUIDE_TABS.data` es el archivo. Vive en su tabla para que `GET /guides` no lo traiga. Se borra con la guía.

Además de las tablas, `guitarcoach.chord_accuracy_summary` agrupa la precisión por acorde y `guitarcoach.problematic_transitions()` devuelve los pares consecutivos que salieron mal.
