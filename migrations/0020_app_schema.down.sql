DROP VIEW IF EXISTS guitarcoach.chord_accuracy_summary;
DROP FUNCTION IF EXISTS guitarcoach.problematic_transitions();

ALTER FUNCTION guitarcoach.chords_document_is_valid(jsonb) SET SCHEMA public;
ALTER TABLE guitarcoach.practice_days SET SCHEMA public;
ALTER TABLE guitarcoach.journey_milestones SET SCHEMA public;
ALTER TABLE guitarcoach.guide_tabs SET SCHEMA public;
ALTER TABLE guitarcoach.song_guides SET SCHEMA public;
ALTER TABLE guitarcoach.song_studies SET SCHEMA public;
ALTER TABLE guitarcoach.study_checkins SET SCHEMA public;
ALTER TABLE guitarcoach.lesson_progress SET SCHEMA public;
ALTER TABLE guitarcoach.scrape_jobs SET SCHEMA public;
ALTER TABLE guitarcoach.reports SET SCHEMA public;
ALTER TABLE guitarcoach.chord_metrics SET SCHEMA public;
ALTER TABLE guitarcoach.attempts SET SCHEMA public;
ALTER TABLE guitarcoach.user_songs SET SCHEMA public;
ALTER TABLE guitarcoach.songs SET SCHEMA public;
ALTER TABLE guitarcoach.users SET SCHEMA public;

CREATE VIEW public.chord_accuracy_summary AS
SELECT
    chord,
    count(*)::integer AS sample_count,
    round(avg(accuracy), 2) AS avg_accuracy,
    round(avg(avg_delta_ms), 2) AS avg_delta_ms,
    coalesce(sum(errors), 0)::integer AS total_errors
FROM chord_metrics
GROUP BY chord;

CREATE FUNCTION public.problematic_transitions()
RETURNS TABLE (from_chord text, to_chord text, error_count bigint)
LANGUAGE sql
STABLE
AS $$
    WITH ordered_events AS (
        SELECT
            attempts.id AS attempt_id,
            events.ordinality AS position,
            events.element ->> 'expected' AS expected,
            events.element ->> 'detected' AS detected
        FROM attempts
        CROSS JOIN LATERAL jsonb_array_elements(attempts.raw_summary -> 'events')
            WITH ORDINALITY AS events(element, ordinality)
    ),
    pairs AS (
        SELECT
            expected AS from_chord,
            lead(expected) OVER (PARTITION BY attempt_id ORDER BY position) AS to_chord,
            lead(detected) OVER (PARTITION BY attempt_id ORDER BY position) AS next_detected
        FROM ordered_events
    )
    SELECT from_chord, to_chord, count(*) AS error_count
    FROM pairs
    WHERE to_chord IS NOT NULL
      AND next_detected IS DISTINCT FROM to_chord
    GROUP BY from_chord, to_chord
    ORDER BY error_count DESC, from_chord, to_chord;
$$;

ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.songs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_songs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chord_metrics DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.scrape_jobs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_progress DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_checkins DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.song_studies DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.song_guides DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.guide_tabs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.journey_milestones DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_days DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.schema_migrations DISABLE ROW LEVEL SECURITY;

DROP SCHEMA guitarcoach;
