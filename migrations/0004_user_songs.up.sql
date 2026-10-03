CREATE TABLE user_songs (
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    song_id INTEGER NOT NULL REFERENCES songs (id) ON DELETE CASCADE,
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    practice_bpm INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, song_id),
    CONSTRAINT user_songs_practice_bpm_range CHECK (
        practice_bpm IS NULL OR practice_bpm BETWEEN 20 AND 300
    )
);
