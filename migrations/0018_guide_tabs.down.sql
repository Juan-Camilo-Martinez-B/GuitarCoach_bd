DROP TABLE IF EXISTS guide_tabs;

DELETE FROM song_guides WHERE source_kind = 'tablatura';
ALTER TABLE song_guides DROP CONSTRAINT song_guides_source_allowed;
ALTER TABLE song_guides ADD CONSTRAINT song_guides_source_allowed CHECK (
    source_kind IN ('pegado', 'chordpro', 'musicxml', 'audio', 'editor')
);
