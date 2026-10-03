CREATE INDEX songs_title_trgm_idx ON songs USING gin (title gin_trgm_ops);
CREATE INDEX songs_artist_trgm_idx ON songs USING gin (artist gin_trgm_ops);
