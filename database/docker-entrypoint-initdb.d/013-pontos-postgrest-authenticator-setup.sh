#!/bin/bash

sql_statement=`mktemp`

cat <<EOF >${sql_statement}
-- Create authenticator role for postgrest connection and make sure it can morph into the other roles
CREATE ROLE authenticator noinherit LOGIN PASSWORD '${POSTGRES_PASSWORD}';
GRANT web_anon TO authenticator;
GRANT web_user TO authenticator;
EOF

psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -f ${sql_statement}
