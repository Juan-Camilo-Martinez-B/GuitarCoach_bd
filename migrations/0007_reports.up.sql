CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL UNIQUE REFERENCES attempts (id) ON DELETE CASCADE,
    content JSONB NOT NULL,
    model TEXT NOT NULL,
    metrics_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT reports_content_object CHECK (jsonb_typeof(content) = 'object'),
    CONSTRAINT reports_model_not_blank CHECK (length(btrim(model)) > 0),
    CONSTRAINT reports_metrics_hash_not_blank CHECK (length(btrim(metrics_hash)) > 0)
);

CREATE INDEX reports_metrics_hash_idx ON reports (metrics_hash);
