-- Una guía puede nacer de una tablatura (Guitar Pro, MusicXML o MIDI). El archivo se guarda
-- para volver a tocar la canción nota por nota. Va en su propia tabla: listar guías no
-- arrastra los bytes, y al borrar la guía se borra su archivo.
ALTER TABLE song_guides DROP CONSTRAINT song_guides_source_allowed;
ALTER TABLE song_guides ADD CONSTRAINT song_guides_source_allowed CHECK (
    source_kind IN ('pegado', 'chordpro', 'musicxml', 'audio', 'editor', 'tablatura')
);

CREATE TABLE guide_tabs (
    guide_id UUID PRIMARY KEY REFERENCES song_guides (id) ON DELETE CASCADE,
    format TEXT NOT NULL,
    data BYTEA NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT guide_tabs_format_allowed CHECK (
        format IN ('gp', 'gp345', 'gpx', 'midi', 'musicxml')
    ),
    -- 5 MB, igual que el límite de la API.
    CONSTRAINT guide_tabs_size CHECK (octet_length(data) BETWEEN 1 AND 5242880)
);
