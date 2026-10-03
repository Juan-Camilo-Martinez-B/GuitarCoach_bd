CREATE TABLE scrape_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users (id) ON DELETE SET NULL,
    song_id INTEGER REFERENCES songs (id) ON DELETE SET NULL,
    status TEXT NOT NULL,
    query TEXT NOT NULL,
    error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT scrape_jobs_status_allowed CHECK (
        status IN ('pending', 'running', 'done', 'failed')
    ),
    CONSTRAINT scrape_jobs_query_not_blank CHECK (length(btrim(query)) > 0),
    CONSTRAINT scrape_jobs_error_when_failed CHECK (
        status <> 'failed' OR (error IS NOT NULL AND length(btrim(error)) > 0)
    )
);
