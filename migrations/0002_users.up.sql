CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    display_name TEXT NOT NULL,
    level TEXT NOT NULL DEFAULT 'beginner',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT users_email_not_blank CHECK (length(btrim(email)) > 0),
    CONSTRAINT users_email_format CHECK (
        email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
    ),
    CONSTRAINT users_password_hash_not_blank CHECK (length(password_hash) > 0),
    CONSTRAINT users_display_name_not_blank CHECK (length(btrim(display_name)) > 0),
    CONSTRAINT users_level_allowed CHECK (level IN ('beginner', 'intermediate', 'advanced'))
);

CREATE UNIQUE INDEX users_email_lower_idx ON users (lower(email));
