CREATE UNIQUE INDEX songs_source_url_unique
    ON songs (source_url)
    WHERE source_url IS NOT NULL;
