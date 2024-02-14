-- The current schema versions deployed if this is the first boot of pontos-hub

BEGIN;

SELECT _v.register_patch('v1.0.0-pre.15', NULL, NULL);
SELECT _v.register_patch('v1.0.2', NULL, NULL);

COMMIT;