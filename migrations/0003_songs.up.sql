CREATE FUNCTION chords_document_is_valid(doc jsonb) RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT doc IS NOT NULL
       AND jsonb_typeof(doc) = 'array'
       AND NOT EXISTS (
            SELECT 1
            FROM jsonb_array_elements(doc) AS element
            WHERE jsonb_typeof(element) <> 'object'
               OR NOT (element ? 'bar' AND element ? 'beat' AND element ? 'chord')
               OR jsonb_typeof(element -> 'bar') <> 'number'
               OR jsonb_typeof(element -> 'beat') <> 'number'
               OR jsonb_typeof(element -> 'chord') <> 'string'
               OR length(btrim(element ->> 'chord')) = 0
               OR (element ->> 'bar')::numeric < 1
               OR (element ->> 'beat')::numeric <= 0
       );
$$;

CREATE TABLE songs (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    song_key TEXT,
    bpm INTEGER NOT NULL,
    chords JSONB NOT NULL,
    source_url TEXT,
    source_name TEXT,
    content_hash TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT songs_title_not_blank CHECK (length(btrim(title)) > 0),
    CONSTRAINT songs_artist_not_blank CHECK (length(btrim(artist)) > 0),
    CONSTRAINT songs_bpm_range CHECK (bpm BETWEEN 20 AND 300),
    CONSTRAINT songs_chords_valid CHECK (chords_document_is_valid(chords)),
    CONSTRAINT songs_song_key_not_blank CHECK (song_key IS NULL OR length(btrim(song_key)) > 0),
    CONSTRAINT songs_content_hash_unique UNIQUE (content_hash)
);
