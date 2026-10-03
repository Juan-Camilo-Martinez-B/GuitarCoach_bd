INSERT INTO users (id, email, password_hash, display_name, level, latency_offset_ms)
VALUES
    (
        '55555555-5555-5555-5555-555555555555',
        'demo.principiante@example.com',
        'demo-hash-not-a-credential',
        'Demo Principiante',
        'beginner',
        35
    ),
    (
        '66666666-6666-6666-6666-666666666666',
        'demo.intermedio@example.com',
        'demo-hash-not-a-credential',
        'Demo Intermedio',
        'intermediate',
        20
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO songs (title, artist, song_key, bpm, chords, source_url, source_name, content_hash)
VALUES
    (
        'Cambios abiertos',
        'GuitarCoach Demo',
        'G',
        72,
        '[
            {"bar": 1, "beat": 1, "chord": "G"},
            {"bar": 1, "beat": 3, "chord": "D"},
            {"bar": 2, "beat": 1, "chord": "Em"},
            {"bar": 2, "beat": 3, "chord": "C"}
        ]'::jsonb,
        'https://example.com/demo/cambios-abiertos',
        'demo',
        'demo-cambios-abiertos'
    ),
    (
        'Ronda de menores',
        'GuitarCoach Demo',
        'Am',
        66,
        '[
            {"bar": 1, "beat": 1, "chord": "Am"},
            {"bar": 2, "beat": 1, "chord": "Dm"},
            {"bar": 3, "beat": 1, "chord": "E"},
            {"bar": 4, "beat": 1, "chord": "Am"}
        ]'::jsonb,
        'https://example.com/demo/ronda-de-menores',
        'demo',
        'demo-ronda-de-menores'
    )
ON CONFLICT (content_hash) DO NOTHING;

INSERT INTO user_songs (user_id, song_id, is_favorite, practice_bpm)
SELECT '55555555-5555-5555-5555-555555555555', id, TRUE, 60
FROM songs
WHERE content_hash = 'demo-cambios-abiertos'
ON CONFLICT (user_id, song_id) DO NOTHING;

INSERT INTO attempts (
    id, user_id, song_id, bpm, accuracy, avg_delta_ms, latency_offset_ms, tuning_cents_avg, raw_summary
)
SELECT
    '77777777-7777-7777-7777-777777777777',
    '55555555-5555-5555-5555-555555555555',
    id,
    60,
    50.00,
    140.00,
    35,
    -12.00,
    '{
        "events": [
            {"bar": 1, "expected": "G", "detected": "G", "delta_ms": 50, "confidence": 0.9},
            {"bar": 1, "expected": "D", "detected": "D", "delta_ms": 180, "confidence": 0.7},
            {"bar": 2, "expected": "Em", "detected": "E", "delta_ms": 210, "confidence": 0.6},
            {"bar": 2, "expected": "C", "detected": "C", "delta_ms": 90, "confidence": 0.84}
        ]
    }'::jsonb
FROM songs
WHERE content_hash = 'demo-cambios-abiertos'
ON CONFLICT (id) DO NOTHING;

INSERT INTO chord_metrics (attempt_id, chord, accuracy, avg_delta_ms, errors)
VALUES
    ('77777777-7777-7777-7777-777777777777', 'G', 100.00, 50.00, 0),
    ('77777777-7777-7777-7777-777777777777', 'D', 100.00, 180.00, 0),
    ('77777777-7777-7777-7777-777777777777', 'Em', 0.00, 210.00, 1),
    ('77777777-7777-7777-7777-777777777777', 'C', 100.00, 90.00, 0)
ON CONFLICT (attempt_id, chord) DO NOTHING;

INSERT INTO reports (id, attempt_id, content, model, metrics_hash)
VALUES (
    '88888888-8888-8888-8888-888888888888',
    '77777777-7777-7777-7777-777777777777',
    '{
        "diagnostico": "Em se confunde con E y el cambio desde D llega tarde.",
        "ejercicios": ["Practica D hacia Em a 60 BPM durante dos minutos."],
        "plan_semanal": ["Dia 1: cambios D-Em. Dia 2: la progresion completa a 60 BPM."],
        "consejos_tecnica": ["Deja preparado el dedo 2 de Em mientras aun suena D."]
    }'::jsonb,
    'demo',
    'demo-metrics-cambios-abiertos'
)
ON CONFLICT (attempt_id) DO NOTHING;
