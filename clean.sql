START TRANSACTION;

INSERT INTO manga (
    manga_id, title, english_title, japanese_title, synopsis, date_published,
    date_ended, status, chapters, volumes, rank, score, scored_by, popularity, favorites, members
)
SELECT DISTINCT ON ((jsonb->'data'->>'mal_id')::INTEGER)
    (jsonb->'data'->>'mal_id')::INTEGER AS manga_id,
    jsonb->'data'->>'title',
    jsonb->'data'->>'title_english',
    jsonb->'data'->>'title_japanese',
    jsonb->'data'->>'synopsis',
    NULLIF(jsonb->'data'->'published'->>'from', 'null')::DATE,
    NULLIF(jsonb->'data'->'published'->>'to', 'null')::DATE,
    jsonb->'data'->>'status',
    NULLIF(jsonb->'data'->>'chapters', 'null')::INTEGER,
    NULLIF(jsonb->'data'->>'volumes', 'null')::INTEGER,
    NULLIF(jsonb->'data'->>'rank', 'null')::INTEGER,
    NULLIF(jsonb->'data'->>'score', 'null')::FLOAT,
    NULLIF(jsonb->'data'->>'scored_by', 'null')::INTEGER,
    NULLIF(jsonb->'data'->>'popularity', 'null')::INTEGER,
    NULLIF(jsonb->'data'->>'favorites', 'null')::INTEGER,
    NULLIF(jsonb->'data'->>'members', 'null')::INTEGER
FROM manga_data
WHERE jsonb->'data'->>'mal_id' IS NOT NULL
ORDER BY manga_id, scraped_at DESC
ON CONFLICT (manga_id) DO UPDATE SET
    title = EXCLUDED.title,
    english_title = EXCLUDED.english_title,
    japanese_title = EXCLUDED.japanese_title,
    synopsis = EXCLUDED.synopsis,
    date_published = EXCLUDED.date_published,
    date_ended = EXCLUDED.date_ended,
    status = EXCLUDED.status,
    chapters = EXCLUDED.chapters,
    volumes = EXCLUDED.volumes,
    rank = EXCLUDED.rank,
    score = EXCLUDED.score,
    scored_by = EXCLUDED.scored_by,
    popularity = EXCLUDED.popularity,
    favorites = EXCLUDED.favorites,
    members = EXCLUDED.members
    ;

INSERT INTO genres (genre_id, name)
SELECT DISTINCT
    (genre_element->>'mal_id')::INTEGER,
    genre_element->>'name'
FROM manga_data,
     LATERAL jsonb_array_elements(jsonb->'data'->'genres') AS genre_element
WHERE jsonb->'data'->>'mal_id' IS NOT NULL
  AND genre_element->>'mal_id' IS NOT NULL
ON CONFLICT (genre_id) DO NOTHING;


INSERT INTO manga_genre (manga_id, genre_id)
SELECT
    (jsonb->'data'->>'mal_id')::INTEGER,
    (genre_element->>'mal_id')::INTEGER
FROM manga_data,
     LATERAL jsonb_array_elements(jsonb->'data'->'genres') AS genre_element
WHERE jsonb->'data'->>'mal_id' IS NOT NULL
  AND genre_element->>'mal_id' IS NOT NULL
  AND (jsonb->'data'->>'mal_id')::BIGINT IN (SELECT manga_id FROM manga)
ON CONFLICT (manga_id, genre_id) DO NOTHING;


INSERT INTO authors (author_id, name)
SELECT DISTINCT
    (author_element->>'mal_id')::INTEGER,
    author_element->>'name'
FROM manga_data,
     LATERAL jsonb_array_elements(jsonb->'data'->'authors') AS author_element
WHERE jsonb->'data'->>'mal_id' IS NOT NULL
  AND author_element->>'mal_id' IS NOT NULL
ON CONFLICT (author_id) DO NOTHING;


INSERT INTO manga_author (manga_id, author_id)
SELECT
    (jsonb->'data'->>'mal_id')::INTEGER,
    (author_element->>'mal_id')::INTEGER
FROM manga_data,
     LATERAL jsonb_array_elements(jsonb->'data'->'authors') AS author_element
WHERE jsonb->'data'->>'mal_id' IS NOT NULL
  AND author_element->>'mal_id' IS NOT NULL
  AND (jsonb->'data'->>'mal_id')::BIGINT IN (SELECT manga_id FROM manga)
ON CONFLICT (manga_id, author_id) DO NOTHING;

COMMIT;
