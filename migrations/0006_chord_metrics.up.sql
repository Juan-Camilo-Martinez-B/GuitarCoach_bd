CREATE TABLE chord_metrics (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    attempt_id UUID NOT NULL REFERENCES attempts (id) ON DELETE CASCADE,
    chord TEXT NOT NULL,
    accuracy NUMERIC(5, 2) NOT NULL,
    avg_delta_ms NUMERIC(8, 2) NOT NULL,
    errors INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT chord_metrics_chord_not_blank CHECK (length(btrim(chord)) > 0),
    CONSTRAINT chord_metrics_accuracy_range CHECK (accuracy >= 0 AND accuracy <= 100),
    CONSTRAINT chord_metrics_errors_non_negative CHECK (errors >= 0),
    CONSTRAINT chord_metrics_attempt_chord_unique UNIQUE (attempt_id, chord)
);

CREATE INDEX chord_metrics_attempt_idx ON chord_metrics (attempt_id);
