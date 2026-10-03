CREATE FUNCTION problematic_transitions()
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
