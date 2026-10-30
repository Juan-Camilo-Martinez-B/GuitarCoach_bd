-- Guía de estudio de una canción elegida por el usuario. Es privada de su dueño.
-- La guía guarda acordes, secciones, rasgueo y melodía; nunca la letra.
CREATE TABLE song_guides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    song_id INTEGER REFERENCES songs (id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    source_kind TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'borrador',
    guide JSONB NOT NULL,
    content_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT song_guides_title_not_blank CHECK (length(btrim(title)) > 0),
    CONSTRAINT song_guides_artist_not_blank CHECK (length(btrim(artist)) > 0),
    CONSTRAINT song_guides_source_allowed CHECK (
        source_kind IN ('pegado', 'chordpro', 'musicxml', 'audio', 'editor')
    ),
    CONSTRAINT song_guides_status_allowed CHECK (status IN ('borrador', 'revisada')),
    CONSTRAINT song_guides_guide_object CHECK (
        jsonb_typeof(guide) = 'object' AND guide ? 'version' AND guide ? 'sections'
    ),
    CONSTRAINT song_guides_no_lyrics CHECK (NOT guide ? 'lyrics'),
    CONSTRAINT song_guides_hash_not_blank CHECK (length(btrim(content_hash)) > 0),
    -- Subir dos veces el mismo contenido devuelve la misma guía (idempotencia).
    CONSTRAINT song_guides_owner_hash_unique UNIQUE (owner_id, content_hash)
);

CREATE INDEX song_guides_owner_updated_idx ON song_guides (owner_id, updated_at DESC);
