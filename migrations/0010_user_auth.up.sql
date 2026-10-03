ALTER TABLE users
    ALTER COLUMN password_hash DROP NOT NULL;

ALTER TABLE users
    DROP CONSTRAINT users_password_hash_not_blank;

ALTER TABLE users
    ADD COLUMN oauth_subject TEXT,
    ADD COLUMN latency_offset_ms INTEGER NOT NULL DEFAULT 0;

ALTER TABLE users
    ADD CONSTRAINT users_password_hash_when_present CHECK (
        password_hash IS NULL OR length(password_hash) > 0
    ),
    ADD CONSTRAINT users_auth_method_present CHECK (
        password_hash IS NOT NULL OR oauth_subject IS NOT NULL
    ),
    ADD CONSTRAINT users_latency_offset_range CHECK (latency_offset_ms BETWEEN -500 AND 500),
    ADD CONSTRAINT users_oauth_subject_not_blank CHECK (
        oauth_subject IS NULL OR length(btrim(oauth_subject)) > 0
    );

CREATE UNIQUE INDEX users_oauth_subject_idx
    ON users (oauth_subject)
    WHERE oauth_subject IS NOT NULL;
