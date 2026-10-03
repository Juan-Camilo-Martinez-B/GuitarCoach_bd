DROP INDEX IF EXISTS users_oauth_subject_idx;

ALTER TABLE users
    DROP CONSTRAINT users_oauth_subject_not_blank,
    DROP CONSTRAINT users_latency_offset_range,
    DROP CONSTRAINT users_auth_method_present,
    DROP CONSTRAINT users_password_hash_when_present;

ALTER TABLE users
    DROP COLUMN latency_offset_ms,
    DROP COLUMN oauth_subject;

UPDATE users
SET password_hash = 'rollback-placeholder'
WHERE password_hash IS NULL;

ALTER TABLE users
    ALTER COLUMN password_hash SET NOT NULL;

ALTER TABLE users
    ADD CONSTRAINT users_password_hash_not_blank CHECK (length(password_hash) > 0);
