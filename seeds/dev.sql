INSERT INTO users (id, email, password_hash, display_name, level)
VALUES (
    '11111111-1111-1111-1111-111111111111',
    'alumno@example.com',
    'seed-hash-not-a-credential',
    'Alumno de prueba',
    'beginner'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO songs (title, artist, song_key, bpm, chords, source_url, source_name, content_hash)
VALUES (
    'Progresión de prueba',
    'GuitarCoach',
    'C',
    80,
    '[
        {"bar": 1, "beat": 1, "chord": "C"},
        {"bar": 1, "beat": 3, "chord": "G"},
        {"bar": 2, "beat": 1, "chord": "Am"},
        {"bar": 2, "beat": 3, "chord": "F"}
    ]'::jsonb,
    'https://example.com/songs/progresion-de-prueba',
    'fixture',
    'seed-progresion-de-prueba'
)
ON CONFLICT (content_hash) DO NOTHING;

INSERT INTO user_songs (user_id, song_id, is_favorite, practice_bpm)
SELECT
    '11111111-1111-1111-1111-111111111111',
    songs.id,
    TRUE,
    60
FROM songs
WHERE songs.content_hash = 'seed-progresion-de-prueba'
ON CONFLICT (user_id, song_id) DO NOTHING;

INSERT INTO attempts (
    id,
    user_id,
    song_id,
    bpm,
    accuracy,
    avg_delta_ms,
    latency_offset_ms,
    tuning_cents_avg,
    raw_summary
)
SELECT
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    songs.id,
    80,
    75.00,
    90.00,
    0,
    -8.00,
    '{
        "events": [
            {"bar": 1, "expected": "C", "detected": "C", "delta_ms": 40, "confidence": 0.93},
            {"bar": 1, "expected": "G", "detected": "G", "delta_ms": 80, "confidence": 0.81},
            {"bar": 2, "expected": "Am", "detected": "Em", "delta_ms": 160, "confidence": 0.55},
            {"bar": 2, "expected": "F", "detected": "F", "delta_ms": 70, "confidence": 0.88}
        ]
    }'::jsonb
FROM songs
WHERE songs.content_hash = 'seed-progresion-de-prueba'
ON CONFLICT (id) DO NOTHING;

INSERT INTO chord_metrics (attempt_id, chord, accuracy, avg_delta_ms, errors)
VALUES
    ('22222222-2222-2222-2222-222222222222', 'C', 100.00, 40.00, 0),
    ('22222222-2222-2222-2222-222222222222', 'G', 100.00, 80.00, 0),
    ('22222222-2222-2222-2222-222222222222', 'Am', 0.00, 160.00, 1),
    ('22222222-2222-2222-2222-222222222222', 'F', 100.00, 70.00, 0)
ON CONFLICT (attempt_id, chord) DO NOTHING;

INSERT INTO reports (id, attempt_id, content, model, metrics_hash)
VALUES (
    '33333333-3333-3333-3333-333333333333',
    '22222222-2222-2222-2222-222222222222',
    '{
        "diagnostico": "El cambio hacia Am llega tarde y se confunde con Em.",
        "ejercicios": ["Cambia G a Am durante un minuto a 60 BPM."],
        "plan_semanal": ["Día 1: cambios G-Am con metrónomo."],
        "consejos_tecnica": ["Prepara el dedo 2 antes de soltar G."]
    }'::jsonb,
    'seed',
    'seed-metrics-hash'
)
ON CONFLICT (attempt_id) DO NOTHING;

INSERT INTO scrape_jobs (id, user_id, status, query)
VALUES (
    '44444444-4444-4444-4444-444444444444',
    '11111111-1111-1111-1111-111111111111',
    'done',
    'progresion de prueba'
)
ON CONFLICT (id) DO NOTHING;
