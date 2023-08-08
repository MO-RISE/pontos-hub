-- Configure schema for master data table

CREATE SCHEMA vessel_data;  -- Will contain the master table with all vessel_data

CREATE TABLE vessel_data.master (
   time             TIMESTAMPTZ                 NOT NULL,
   vessel_id        TEXT                        NOT NULL,
   parameter_id     TEXT                        NOT NULL,
   value            TEXT                        NOT NULL,
   CONSTRAINT no_duplicates_key UNIQUE(time, vessel_id, parameter_id)
);

SELECT create_hypertable('vessel_data.master', 'time');

CREATE INDEX ON vessel_data.master (time DESC);     --Should be enabled by default
CREATE INDEX ON vessel_data.master (vessel_id, time DESC);
CREATE INDEX ON vessel_data.master (parameter_id, time DESC);
CREATE INDEX ON vessel_data.master (vessel_id, parameter_id, time DESC);
