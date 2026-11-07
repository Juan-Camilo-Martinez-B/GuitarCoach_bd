CREATE SCHEMA IF NOT EXISTS guitarcoach;

REVOKE ALL ON SCHEMA guitarcoach FROM PUBLIC;

DO $move$
DECLARE
    app_table text;
    app_tables text[] := ARRAY[
        'users',
        'songs',
        'user_songs',
        'attempts',
        'chord_metrics',
        'reports',
        'scrape_jobs',
        'lesson_progress',
        'study_checkins',
        'song_studies',
        'song_guides',
        'guide_tabs',
        'journey_milestones',
        'practice_days'
    ];
    db_role text;
BEGIN
    IF to_regclass('public.chord_accuracy_summary') IS NOT NULL THEN
        DROP VIEW public.chord_accuracy_summary;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_proc
        JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
        WHERE pg_namespace.nspname = 'public'
          AND pg_proc.proname = 'problematic_transitions'
    ) THEN
        DROP FUNCTION public.problematic_transitions();
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_proc
        JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
        WHERE pg_namespace.nspname = 'public'
          AND pg_proc.proname = 'chords_document_is_valid'
    ) THEN
        ALTER FUNCTION public.chords_document_is_valid(jsonb) SET SCHEMA guitarcoach;
    END IF;

    FOREACH app_table IN ARRAY app_tables LOOP
        IF to_regclass(format('public.%I', app_table)) IS NOT NULL THEN
            EXECUTE format('ALTER TABLE public.%I SET SCHEMA guitarcoach', app_table);
        END IF;
    END LOOP;

    FOREACH db_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role'] LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = db_role) THEN
            EXECUTE format('REVOKE ALL ON SCHEMA guitarcoach FROM %I', db_role);
            EXECUTE format('REVOKE ALL ON ALL TABLES IN SCHEMA guitarcoach FROM %I', db_role);
            EXECUTE format('REVOKE ALL ON ALL SEQUENCES IN SCHEMA guitarcoach FROM %I', db_role);
            EXECUTE format('REVOKE ALL ON ALL FUNCTIONS IN SCHEMA guitarcoach FROM %I', db_role);
            EXECUTE format('REVOKE ALL ON TABLE public.schema_migrations FROM %I', db_role);
        END IF;
    END LOOP;
END
$move$;

CREATE OR REPLACE VIEW guitarcoach.chord_accuracy_summary AS
SELECT
    chord,
    count(*)::integer AS sample_count,
    round(avg(accuracy), 2) AS avg_accuracy,
    round(avg(avg_delta_ms), 2) AS avg_delta_ms,
    coalesce(sum(errors), 0)::integer AS total_errors
FROM guitarcoach.chord_metrics
GROUP BY chord;

CREATE OR REPLACE FUNCTION guitarcoach.problematic_transitions()
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
        FROM guitarcoach.attempts
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

REVOKE ALL ON ALL TABLES IN SCHEMA guitarcoach FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA guitarcoach FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA guitarcoach FROM PUBLIC;

DO $rls$
DECLARE
    app_table text;
BEGIN
    FOR app_table IN
        SELECT pg_class.relname
        FROM pg_class
        JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        WHERE pg_namespace.nspname = 'guitarcoach'
          AND pg_class.relkind = 'r'
    LOOP
        EXECUTE format('ALTER TABLE guitarcoach.%I ENABLE ROW LEVEL SECURITY', app_table);
    END LOOP;
END
$rls$;

ALTER TABLE public.schema_migrations ENABLE ROW LEVEL SECURITY;
