--- Configure views that will be available externally and the api docs
--- NOTE! This file is executed on every boot and must there be re-entrant!

-- Create views that will be available through the rest api
CREATE OR REPLACE VIEW api_views.vessel_ids AS (SELECT DISTINCT vessel_id FROM vessel_data.master);
CREATE OR REPLACE VIEW api_views.vessel_data AS (SELECT * FROM vessel_data.master);

-- OpenAPI documentation comments
COMMENT ON SCHEMA api_views IS
  'Welcome to the REST API documentation for PONTOS HUB!

  A good starting point to understand how to use this REST API is to look through this part of the PostgREST documentation: https://postgrest.org/en/stable/api.html#tables-and-views

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed justo nibh, sollicitudin sit amet ipsum eget, scelerisque posuere neque. Cras tristique massa orci, quis maximus nibh eleifend quis. Phasellus faucibus venenatis libero non accumsan. Morbi tincidunt orci quis arcu lobortis rhoncus. Donec placerat dui vel eros auctor, vel feugiat sem placerat. Mauris a tempor nunc. Suspendisse non justo a nisi dignissim tincidunt. Vestibulum sagittis, erat eu sodales lacinia, eros felis congue lectus, vel tincidunt nunc ipsum ut diam. In lacinia lectus in ante convallis volutpat. Donec feugiat porttitor maximus. Suspendisse ac congue sem. Sed hendrerit, ante quis tincidunt aliquet, sapien massa sagittis lorem, nec venenatis ante mauris sit amet sapien.
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