-- Setting up views and roles for use with PostgREST

CREATE SCHEMA api_views;    -- Will contain specific views of the data that should be accessible to the postgREST api users

CREATE ROLE web_anon nologin; -- Anonymuous role for unautenticated logins
CREATE ROLE web_user nologin; -- Authenticated role

-- Allow usage on schema api_views to all roles
GRANT USAGE ON SCHEMA api_views TO web_anon;
GRANT USAGE ON SCHEMA api_views TO web_user;

-- This gives the specified role select rights to all future tables in the api_views schema created by pontos_user
ALTER DEFAULT PRIVILEGES FOR USER pontos_user IN SCHEMA api_views GRANT SELECT ON TABLES TO web_anon;
ALTER DEFAULT PRIVILEGES FOR USER pontos_user IN SCHEMA api_views GRANT SELECT ON TABLES TO web_user;


-- Create authenticator role for postgrest connection and make sure it can morph into the other roles
CREATE ROLE authenticator noinherit LOGIN PASSWORD 'authenticator-password';
GRANT web_anon TO authenticator;
GRANT web_user TO authenticator;