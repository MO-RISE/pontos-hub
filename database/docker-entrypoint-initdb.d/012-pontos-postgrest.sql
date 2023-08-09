-- Configuring groundwork for interaction with PostgREST

CREATE SCHEMA api_views;    -- Will contain specific views of the data that should be accessible to the postgREST api users

-- Setting up views and roles for use with PostgREST
CREATE ROLE web_anon nologin; -- Anonymuous role for unautenticated logins
CREATE ROLE web_user nologin; -- Authenticated role

-- Allow usage on schema api_views to all roles
GRANT USAGE ON SCHEMA api_views TO web_anon;
GRANT USAGE ON SCHEMA api_views TO web_user;

-- This gives the specified role select rights to all future tables in the api_views schema created by pontos_user
-- NOTE: We do not give the web_anon user any privileges here. It will be used only for allowing connections to the
-- postgrest instance to view the API docs but not actually read any data from the tables/views.
ALTER DEFAULT PRIVILEGES FOR USER pontos_user IN SCHEMA api_views GRANT SELECT ON TABLES TO web_user;
