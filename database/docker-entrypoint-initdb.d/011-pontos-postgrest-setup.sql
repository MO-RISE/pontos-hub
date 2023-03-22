-- Anonymuous role for unautenticated logins
CREATE ROLE web_anon nologin;

-- Allow usage on schema vessel_data to the web_anon role
GRANT USAGE ON SCHEMA vessel_data TO web_anon;

-- This gives the web_anon role select rights to all future tables in the vessel_data schema created by pontos_user
ALTER DEFAULT PRIVILEGES FOR USER pontos_user IN SCHEMA vessel_data GRANT SELECT ON TABLES TO web_anon;


-- Create authenticator role for postgrest connection and make sure it can morph into the web_anon role
CREATE ROLE authenticator noinherit LOGIN PASSWORD 'authenticator-password';
GRANT web_anon TO authenticator;