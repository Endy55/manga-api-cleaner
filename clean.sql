START TRANSACTION;

-- Insert/Update Anime
INSERT INTO manga (
    manga_id, title, english_title, japanese_title, synopsis, 
    rank, score, status, chapters, volumes, date_started, 
    date_ended
)
SELECT
    (jsonb->'data'->>'mal_id')::INTEGER,
    jsonb->'data'->>'title',
    jsonb->'data'->>'title_english',
    jsonb->'data'->>'title_japanese',
    NULLIF(jsonb->'data'->>'rank', 'null')::INTEGER,
    NULLIF(jsonb->'data'->>'score', 'null')::FLOAT,
    jsonb->'data'->>'status',
    NULLIF(jsonb->'data'->>'chapters', 'null')::INTEGER,
    NULLIF(jsonb->'data'->>'volume', 'null')::INTEGER,
    NULLIF(jsonb->'data'->'published'->>'from', 'null')::DATE,
    NULLIF(jsonb->'data'->'published'->>'to', 'null')::DATE
FROM manga_data
WHERE jsonb->'data'->>'mal_id' IS NOT NULL
ON CONFLICT (manga_id) DO UPDATE SET
    title = EXCLUDED.title,
    english_title = EXCLUDED.english_title,
    japanese_title = EXCLUDED.japanese_title,
    synopsis = EXCLUDED.synopsis,
    rank = EXCLUDED.rank,
    score = EXCLUDED.score,
    status = EXCLUDED.status,
    chapters = EXCLUDED.chapters,
    volume = EXCLUDED.volume,
    date_published = EXCLUDED.date_published,
    date_ended = EXCLUDED.date_ended;

-- Insert Genres
INSERT INTO genre (genre_id, name)
SELECT DISTINCT
    (genre_element->>'mal_id')::INTEGER,
    genre_element->>'name'
FROM manga_data,
     LATERAL jsonb_array_elements(jsonb->'data'->'genres') AS genre_element
WHERE jsonb->'data'->>'mal_id' IS NOT NULL
  AND genre_element->>'mal_id' IS NOT NULL
ON CONFLICT (genre_id) DO NOTHING;

-- Link Anime–Genres
INSERT INTO manga_genre (manga_id, genre_id)
SELECT
    (jsonb->'data'->>'mal_id')::INTEGER,
    (genre_element->>'mal_id')::INTEGER
FROM manga_data,
     LATERAL jsonb_array_elements(jsonb->'data'->'genres') AS genre_element
WHERE jsonb->'data'->>'mal_id' IS NOT NULL
  AND genre_element->>'mal_id' IS NOT NULL
ON CONFLICT (manga_id, genre_id) DO NOTHING;

-- Insert Studios
INSERT INTO authors (author_id, name)
SELECT DISTINCT
    (author_element->>'mal_id')::INTEGER,
    author_element->>'name'
FROM manga_data,
     LATERAL jsonb_array_elements(jsonb->'data'->'authors') AS author_element
WHERE jsonb->'data'->>'mal_id' IS NOT NULL
  AND author_element->>'mal_id' IS NOT NULL
ON CONFLICT (author_id) DO NOTHING;

-- Link Anime–Studios
INSERT INTO manga_author (manga_id, author_id)
SELECT
    (jsonb->'data'->>'mal_id')::INTEGER,
    (author_element->>'mal_id')::INTEGER
FROM manga_data,
     LATERAL jsonb_array_elements(jsonb->'data'->'authors') AS author_element
WHERE jsonb->'data'->>'mal_id' IS NOT NULL
  AND author_element->>'mal_id' IS NOT NULL
ON CONFLICT (manga_id, author_id) DO NOTHING;

COMMIT;
