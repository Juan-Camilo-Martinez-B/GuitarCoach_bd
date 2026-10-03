ALTER TABLE reports
    ADD CONSTRAINT reports_content_shape CHECK (
        content ? 'diagnostico'
        AND content ? 'ejercicios'
        AND content ? 'plan_semanal'
        AND content ? 'consejos_tecnica'
        AND jsonb_typeof(content -> 'diagnostico') = 'string'
        AND jsonb_typeof(content -> 'ejercicios') = 'array'
        AND jsonb_typeof(content -> 'plan_semanal') = 'array'
        AND jsonb_typeof(content -> 'consejos_tecnica') = 'array'
    );
