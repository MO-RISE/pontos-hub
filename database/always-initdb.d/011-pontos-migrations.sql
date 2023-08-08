BEGIN;

-- To v1.0.0-pre.15
DO $$ BEGIN
IF _v.try_register_patch('v1.0.0-pre.15', NULL, NULL)
THEN

    -- Remove existing duplicates
    DELETE FROM vessel_data.master T1 USING vessel_data.master T2
    WHERE  T1.ctid    < T2.ctid         -- delete the "older" ones
    -- duplicate defined as:
        AND  T1.time = T2.time
        AND  T1.vessel_id = T2.vessel_id
        AND  T1.parameter_id = T2.parameter_id;

    -- Add unique constraint
    ALTER TABLE vessel_data.master ADD CONSTRAINT no_duplicates_key UNIQUE(time, vessel_id, parameter_id);

END IF;
END $$;

COMMIT;