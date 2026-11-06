-- La ruta del principiante y su racha. Antes vivían solo en el navegador: con estas tablas se
-- conservan al cambiar de equipo. Los logros no se guardan: salen de estos datos.
CREATE TABLE journey_milestones (
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    milestone TEXT NOT NULL,
    achieved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, milestone),
    CONSTRAINT journey_milestones_known CHECK (
        milestone IN ('afinar', 'acorde', 'tocar', 'propia', 'avance')
    )
);

-- Un día de práctica por usuario. La clave primaria hace idempotente el aviso del navegador.
CREATE TABLE practice_days (
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    day DATE NOT NULL,
    PRIMARY KEY (user_id, day)
);
