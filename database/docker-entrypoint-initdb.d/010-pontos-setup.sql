-- Initial setup of database and master table

CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

CREATE SCHEMA vessel_data;  -- Will contain the master table with all vessel_data

CREATE TABLE vessel_data.master (
   time             TIMESTAMPTZ                 NOT NULL,
   vessel_id        TEXT                        NOT NULL,
   parameter_id     TEXT                        NOT NULL,
   value            TEXT                        NOT NULL
);

SELECT create_hypertable('vessel_data.master', 'time');

CREATE INDEX ON vessel_data.master (time DESC);     --Should be enabled by default
CREATE INDEX ON vessel_data.master (vessel_id, time DESC);
CREATE INDEX ON vessel_data.master (parameter_id, time DESC);
CREATE INDEX ON vessel_data.master (vessel_id, parameter_id, time DESC);

SELECT add_retention_policy('vessel_data.master', INTERVAL '6 months');
