-- https://postgrest.org/en/v12/references/configuration.html

-- create a dedicated schema, hidden from the API
create schema postgrest;
-- grant usage on this schema to the authenticator

CREATE SCHEMA api;


COMMENT ON SCHEMA api IS 'Allgemeines Schema fuer uebergeordnete Zwecke v1.0.62';




ALTER SCHEMA api OWNER TO postgres;


create role web_anon nologin;

grant usage on schema api to web_anon;

create role authenticator noinherit login password 'mysecretpassword';
grant web_anon to authenticator;



grant usage on schema postgrest to authenticator;

-- the function can configure postgREST by using set_config
create or replace function postgrest.pre_config()
returns void as $$
  select
    -- set_config('pgrst.db_schemas', 'api', true),
    set_config('pgrst.jwt_secret', '7u8f0HLDi5S6NKzNuo69cDEl3abvDP8YVfW3egLNubvy7uJFrP', false),
    set_config('pgrst.db_schemas', string_agg(nspname, ','), true)
    from pg_namespace
    where nspname like 'vwm_impex' OR nspname = 'api';
$$ language sql;
