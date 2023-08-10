--- Configure views that will be available externally and the api docs
--- NOTE! This file is executed on every boot and must there be re-entrant!

-- Create views that will be available through the rest api
CREATE OR REPLACE VIEW api_views.vessel_ids AS (SELECT DISTINCT vessel_id FROM vessel_data.master);
CREATE OR REPLACE VIEW api_views.vessel_data AS (SELECT * FROM vessel_data.master);

-- OpenAPI documentation comments
COMMENT ON SCHEMA api_views IS
  'Welcome to the REST API documentation for PONTOS HUB!

  PONTOS HUB stores sensor records in a narrow table format:

  time (TIMESTAMPZ)   |   vessel_id (TEXT)   |   parameter_id (TEXT)   |   value (TEXT)

  where

  time is the timestamp of the record,
  vessel_id is a unique identifier for the vessel where the sensor record originates from,
  parameter_id is a tag as defined and documented at https://pontos.ri.se,
  value is the actual sensor record

  Get started:

  1. Make sure you have fetched an access token so that you can access the data. If not, see here: https://pontos.ri.se
  2. Have a look at the examples at https://pontos.ri.se
  3. For further details about how to use the API, consider looking through this part of the PostgREST documentation: https://postgrest.org/en/stable/api.html#tables-and-views

  We hope you will find this data hub and the data that it offers useful for your use case!

';

-- Vessel IDs view
COMMENT ON VIEW api_views.vessel_ids IS
  'Distinct vessel_ids available in the data hub';

-- Vessel data view
COMMENT ON VIEW api_views.vessel_data IS
  'All data available in the data hub, stored in a narrow table setup.';
COMMENT ON COLUMN api_views.vessel_data.time IS
  'Timestamp of data';
COMMENT ON COLUMN api_views.vessel_data.vessel_id IS
  'A unique identifier for each vessel, usually the IMO number if available.';
COMMENT ON COLUMN api_views.vessel_data.parameter_id IS
  'A unique tag for each parameter, documented at https://pontos.ri.se';
COMMENT ON COLUMN api_views.vessel_data.value IS
  'The data value. This column is always of type text, therefore it may be beneficial to perform a cast operation as part of the GET request, see https://postgrest.org/en/stable/api.html#casting-columns';