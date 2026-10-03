CREATE TABLE attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    song_id INTEGER NOT NULL REFERENCES songs (id) ON DELETE RESTRICT,
    bpm INTEGER NOT NULL,
    accuracy NUMERIC(5, 2) NOT NULL,
    avg_delta_ms NUMERIC(8, 2) NOT NULL,
    latency_offset_ms INTEGER NOT NULL DEFAULT 0,
    tuning_cents_avg NUMERIC(6, 2),
    raw_summary JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT attempts_bpm_range CHECK (bpm BETWEEN 20 AND 300),
    CONSTRAINT attempts_accuracy_range CHECK (accuracy >= 0 AND accuracy <= 100),
    CONSTRAINT attempts_latency_range CHECK (latency_offset_ms BETWEEN -500 AND 500),
    CONSTRAINT attempts_raw_summary_object CHECK (jsonb_typeof(raw_summary) = 'object'),
    CONSTRAINT attempts_raw_summary_events CHECK (
        raw_summary ? 'events' AND jsonb_typeof(raw_summary -> 'events') = 'array'
    )
);

CREATE INDEX attempts_user_created_idx ON attempts (user_id, created_at DESC);
CREATE INDEX attempts_song_idx ON attempts (song_id);
