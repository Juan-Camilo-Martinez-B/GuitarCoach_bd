CREATE TABLE lesson_progress (
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    lesson_id TEXT NOT NULL,
    status TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, lesson_id),
    CONSTRAINT lesson_progress_status CHECK (status = 'completed'),
    CONSTRAINT lesson_progress_lesson_not_blank CHECK (length(btrim(lesson_id)) > 0)
);

CREATE TABLE study_checkins (
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    reviewed_on DATE NOT NULL,
    PRIMARY KEY (user_id, reviewed_on)
);

CREATE TABLE song_studies (
    song_id INTEGER PRIMARY KEY REFERENCES songs (id) ON DELETE CASCADE,
    plan JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT song_studies_plan_object CHECK (jsonb_typeof(plan) = 'object')
);
