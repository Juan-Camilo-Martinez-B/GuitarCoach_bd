CREATE INDEX scrape_jobs_status_created_idx
    ON scrape_jobs (status, created_at DESC);
