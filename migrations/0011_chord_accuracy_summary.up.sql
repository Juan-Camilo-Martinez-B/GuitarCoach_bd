CREATE VIEW chord_accuracy_summary AS
SELECT
    chord,
    count(*)::integer AS sample_count,
    round(avg(accuracy), 2) AS avg_accuracy,
    round(avg(avg_delta_ms), 2) AS avg_delta_ms,
    coalesce(sum(errors), 0)::integer AS total_errors
FROM chord_metrics
GROUP BY chord;
