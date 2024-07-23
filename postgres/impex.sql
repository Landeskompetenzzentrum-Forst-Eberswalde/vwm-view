--
-- PostgreSQL database dump
--

-- Dumped from database version 14.12
-- Dumped by pg_dump version 14.12

-- Started on 2024-07-22 17:21:58 UTC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 19 (class 2615 OID 34436)
-- Name: vwm_impex; Type: SCHEMA; Schema: -; Owner: waldinv_admin
--

CREATE SCHEMA vwm_impex;
ALTER DEFAULT PRIVILEGES IN SCHEMA vwm_impex GRANT SELECT ON TABLES TO web_anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA vwm_impex GRANT USAGE, SELECT ON SEQUENCES TO web_anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA vwm_impex GRANT USAGE ON TYPES TO web_anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA vwm_impex GRANT EXECUTE ON FUNCTIONS TO web_anon;

ALTER SCHEMA vwm_impex OWNER TO waldinv_admin;

--
-- TOC entry 2658 (class 1255 OID 44126)
-- Name: import_geojson(json); Type: FUNCTION; Schema: vwm_impex; Owner: vwm_ats
--

CREATE FUNCTION vwm_impex.import_geojson(geojson_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$DECLARE
    added_ids json;
    feature json;
    geom geometry;
    form json;
    baumplot json;
    t_bestockung json;
    verjuengungstransekt json;
    bodenvegetation json;
    landmarke json;
    stoerung json;
    new_los_id INTEGER;
    new_bestbes_id INTEGER;
    new_punktinfo_id INTEGER;
    new_transektinfo_id INTEGER;
    stoerungen_map json;
    i int = 0;
    fim_stoerung text;
BEGIN
    -- Loop through each feature in the GeoJSON
    FOR feature IN SELECT * FROM json_array_elements(geojson_data->'features')
    LOOP
        perform FROM vwm_impex.g_los WHERE fim_id = feature->'properties'->>'id' or id_g_los = feature->'properties'->>'los_id';
        IF FOUND THEN
            DELETE FROM vwm_impex.g_los WHERE fim_id = feature->'properties'->>'id' or id_g_los = feature->'properties'->>'los_id';
        END IF;

        -- Convert GeoJSON geometry to PostGIS geometry
        geom := ST_SetSRID(ST_GeomFromGeoJSON(feature->>'geometry'), 4326);

        -- Example: Inserting data into a table. Adjust the table name and columns as necessary.
        INSERT INTO vwm_impex.g_los (
            fim_id,
            los_id,
            fim_status,
            fim_type,
            created,
            modified,
            imported,
            workflow,
            losnr,
            spaufsucheaufnahmetruppkuerzel,
            spaufsucheaufnahmetruppgnss,
            spaufsuchenichtbegehbarursacheid,
            spaufsuchenichtwaldursacheid,
            spaufsucheverschobenursacheid,
            s_perma,
            istgeom_elev,
            istgeom_sat,
            istgeom_hdop,
            istgeom_vdop,
            ist_geom
        )
        VALUES (
            feature->'properties'->>'id',
            feature->'properties'->>'los_id',
            CASE
                WHEN feature->'properties'->>'status' = 'true' THEN TRUE
                WHEN feature->'properties'->>'status' = 'false' THEN FALSE
                ELSE NULL -- or default to TRUE/FALSE depending on your requirements
            END,
            feature->'properties'->>'type',
            TO_TIMESTAMP(feature->'properties'->>'created', 'YYYY-MM-DD"T"HH24:MI:SS.US'),
            TO_TIMESTAMP(feature->'properties'->>'modified', 'YYYY-MM-DD"T"HH24:MI:SS.US'),
            NOW()::TIMESTAMP,
            (feature->'properties'->>'workflow')::INTEGER,
            feature->'properties'->>'losnr',
            feature->'properties'->'form'->'general'->>'spaufsucheaufnahmetruppkuerzel',
            feature->'properties'->'form'->'general'->>'spaufsucheaufnahmetruppgnss',
            (feature->'properties'->'form'->'general'->>'spaufsuchenichtbegehbarursacheid')::INTEGER,
            (feature->'properties'->'form'->'general'->>'spaufsuchenichtwaldursacheid')::INTEGER,
            (feature->'properties'->'form'->'coordinates'->>'spaufsucheverschobenursacheid')::INTEGER,
            (feature->'properties'->'form'->'coordinates'->>'s_perma')::INTEGER,
            (feature->'properties'->'form'->'coordinates'->>'istgeom_elev')::float,
            (feature->'properties'->'form'->'coordinates'->>'istgeom_sat')::INTEGER,
            (feature->'properties'->'form'->'coordinates'->>'istgeom_hdop')::float,
            (feature->'properties'->'form'->'coordinates'->>'istgeom_vdop')::float,
            geom

        )
        ON CONFLICT (fim_id) DO NOTHING
        RETURNING id_g_los INTO new_los_id;

        -- Save the ID of the inserted row
        added_ids := json_build_object('id', new_los_id);

        form = feature->'properties'->'form';

        -- BAUMPLOT1
        i:= 0;
        FOR baumplot IN SELECT * FROM json_array_elements(form->'baumplot1'->'baumplot1')
        LOOP
            i:= i+ 1;
            INSERT INTO vwm_impex.imp_t_baumplot (
                los_id,
                bplotnr,
                onr,
                baid,
                azi,
                dist,
                bhd,
                h_bhd,
                schal,
                fege
            )
            VALUES (
                new_los_id,
                1,
                i,
                (baumplot->>'icode_ba')::INT, 
                (baumplot->>'azimut')::INT,
                (baumplot->>'distanz')::INT,
                (baumplot->>'bhd')::INT,
                (baumplot->>'messhoehebhd')::INT,
                (baumplot->>'schaele')::BOOLEAN,
                (baumplot->>'fege')::BOOLEAN
            );
        END LOOP;
        -- BAUMPLOT2
        i:= 0;
        FOR baumplot IN SELECT * FROM json_array_elements(form->'baumplot2'->'baumplot2')
        LOOP
            i:= i+ 1;
            INSERT INTO vwm_impex.imp_t_baumplot (
                los_id,
                bplotnr,
                onr,
                baid,
                azi,
                dist,
                bhd,
                h_bhd,
                schal,
                fege
            )
            VALUES (
                new_los_id,
                2,
                i,
                (baumplot->>'icode_ba')::INT, 
                (baumplot->>'azimut')::INT,
                (baumplot->>'distanz')::INT,
                (baumplot->>'bhd')::INT,
                (baumplot->>'messhoehebhd')::INT,
                (baumplot->>'schaele')::BOOLEAN,
                (baumplot->>'fege')::BOOLEAN
            );
        END LOOP;

        -- Landmarke
        i:= 0;
        FOR landmarke IN SELECT * FROM json_array_elements(form->'landmarken1'->'landmarken1')
        LOOP
            i:= i+ 1;
            INSERT INTO vwm_impex.imp_t_baumplot (
                los_id,
                lplotnr,
                onr,
                typ,
                azi,
                dist
            )
            VALUES (
                new_los_id,
                1,
                i,
                (landmarke->>'landmarken')::text,
                (landmarke->>'azimut')::INT,
                (landmarke->>'distanz')::INT
            );
        END LOOP;

        -- Transektinformationen (imp_t_transektinfo)
        INSERT INTO vwm_impex.imp_t_transektinfo (
            los_id,
            laenge,
            tempstoerung,
            hase,
            maus,
            biber,
            sma_id,
            krautanteil,
            azi,
            transektstoerungursache
        )
        VALUES (
            new_los_id,
            (form->'verjuengungstransekt'->>'verjuengungstransektlaenge')::INT,
            -- set boolean if transektstoerungursache has value
            CASE
                WHEN (form->'transekt'->>'transektstoerungursache')::text != 'null' AND (form->'transekt'->>'transektstoerungursache')::text != '' THEN TRUE
                ELSE FALSE
            END,
            (form->'transektinfo'->>'transektfrasshase')::BOOLEAN,
            (form->'transektinfo'->>'transektfrassmaus')::BOOLEAN,
            (form->'transektinfo'->>'transektfrassbieber')::BOOLEAN,
            (form->'transekt'->>'schutzmassnahmeid')::INT,
            (form->'weiserpflanzen'->>'krautanteil')::INT,
            (form->'baumplot1'->>'azimuttransektploteins')::INT,
            form->'transekt'->>'transektstoerungursache'
        )
        RETURNING id_transektinfo INTO new_transektinfo_id;

        

        -- Bestandesbeschreibung (imp_t_bestbes)
        INSERT INTO vwm_impex.imp_t_bestbes (
            los_id,
            heterogenigrad,
            nschicht_id,
            bea_id,
            ksg_id,
            sma_id,
            bed_us,
            bed_bodenveg
        )
        VALUES (
            new_los_id,
            (form->'bestandsbeschreibung'->>'bestandheterogenitaetsgradid')::INT,
            (form->'bestandsbeschreibung'->>'bestandnschichtigid')::INT,
            (form->'bestandsbeschreibung'->>'bestandbetriebsartid')::smallint,
            (form->'bestandsbeschreibung'->>'bestandkronenschlussgradid')::smallint,
            (form->'bestandsbeschreibung'->>'bestandschutzmassnahmenid')::smallint,
            (form->'bestandsbeschreibung'->>'bestandbedeckungsgradunterstand')::smallint,
            (form->'bestandsbeschreibung'->>'bestandbedeckungsgradgraeser')::smallint
        )
        RETURNING id_bestbes INTO new_bestbes_id;


        -- Punktinformationen (imp_b_strg)
        stoerungen_map := '[
            {
                "fim": "thinning",
                "value": 1
            },
            {
                "fim": "sanitaryStrokes",
                "value": 2
            },
            {
                "fim": "wildfire",
                "value": 3
            },
            {
                "fim": "storm",
                "value": 4
            },
            {
                "fim": "soilCultivation",
                "value": 5
            }
        ]'::json;
         i:= 1;
        FOR stoerung IN SELECT * FROM json_array_elements(stoerungen_map)
        LOOP
            fim_stoerung := stoerung->>'fim';
            IF (form->'stoerung'->>fim_stoerung)::BOOLEAN = true THEN
                
                INSERT INTO vwm_impex.imp_b_strg (
                    los_id,
                    bestbesid,
                    s_strgid
                )
                VALUES (
                    new_los_id,
                    new_bestbes_id,
                    (stoerung->>'value')::INT
                );
                
            END IF;
            i:= i+ 1;
        END LOOP;
        
        IF (form->'stoerung'->>'note')::text != 'null' THEN
            INSERT INTO vwm_impex.imp_b_strgsonstig (
                los_id,
                stoerung
            )
            VALUES (
                new_los_id,
                form->'stoerung'->>'note'
            );
        END IF;




        -- Bestockung (imp_t_bestbess)
        i:= 0;
        FOR t_bestockung IN SELECT * FROM json_array_elements(form->'t_bestockung'->'t_bestockung')
        LOOP
            i:= i+ 1;
            INSERT INTO vwm_impex.imp_t_bestbess (
                los_id,
                schicht_id,
                ba_icode,
                bestbesid,
                nas_id,
                ba_anteil,
                entsart_id,
                vert_id
            )
            VALUES (
                new_los_id,
                (t_bestockung->>'schicht_id')::INT, 
                (t_bestockung->>'icode_ba')::INT,
                new_bestbes_id,
                (t_bestockung->>'nas_id')::INT,
                (t_bestockung->>'ba_anteil')::INT,
                (t_bestockung->>'entsart_id')::INT,
                (t_bestockung->>'vert_id')::INT
            );
        END LOOP;

        -- Verjuengungstransekt (imp_t_transekt)
        i:= 0;
        FOR verjuengungstransekt IN SELECT * FROM json_array_elements(form->'verjuengungstransekt'->'verjuengungstransekten')
        LOOP
            i:= i+ 1;
            INSERT INTO vwm_impex.imp_t_transekt (
                los_id,
                ba_icode,
                hst,
                sma_id,
                bhd,
                verb,
                trck,
                frost,
                insekt,
                schael_fege
            )
            VALUES (
                new_los_id,
                (verjuengungstransekt->>'ba_icode')::INT,
                (verjuengungstransekt->>'height')::INT,
                (verjuengungstransekt->>'verjuengungstransektschutzmassnahmen')::INT,
                (verjuengungstransekt->>'verjuengungstransektbhd')::INT,
                (verjuengungstransekt->>'verjuengungstransekttriebverlustdurchschalenwildverbiss')::BOOLEAN,
                (verjuengungstransekt->>'verjuengungstransekttriebverlustdurchtrockenheit')::BOOLEAN,
                (verjuengungstransekt->>'verjuengungstransekttriebverlustdurchfrost')::BOOLEAN,
                (verjuengungstransekt->>'verjuengungstransekttriebverlustdurchinsektenfrass')::BOOLEAN,
                (verjuengungstransekt->>'verjuengungstransekttriebverlustdurchfege')::BOOLEAN
            );
        END LOOP;

        -- Bodenvegetation (imp_t_transektipf)
        i:= 0;
        FOR bodenvegetation IN SELECT * FROM json_array_elements(form->'t_bodenvegetation'->'t_bodenvegetation')
        LOOP
            i:= i+ 1;
            INSERT INTO vwm_impex.imp_t_transektipf (
                los_id,
                transekti_id, -- ?
                indikpfl_id,
                anteilsprozent
            )
            VALUES (
                new_los_id,
                (bodenvegetation->>'verteilung')::INT, -- ?
                (bodenvegetation->>'bodenveggr')::INT,
                (bodenvegetation->>'anteil')::INT
            );
        END LOOP;

        -- Bodenvegetation (imp_t_transektipf)
        i:= 0;
        FOR bodenvegetation IN SELECT * FROM json_array_elements(form->'t_bodenvegetation'->'t_bodenvegetation')
        LOOP
            i:= i+ 1;
            INSERT INTO vwm_impex.imp_t_besbodenveggr (
                los_id,
                bodenveggr_id,
                verteilung_id,
                prozanteil,
                bestbesid
            )
            VALUES (
                new_los_id,
                (bodenvegetation->>'bodenveggr')::INT, -- bodenvegetationsgruppe
                (bodenvegetation->>'verteilung')::INT,
                (bodenvegetation->>'anteil')::INT,
                new_bestbes_id
            );
        END LOOP;

        
        -- Repeat the above INSERT statement for other tables as necessary, mapping GeoJSON properties to table columns.
    END LOOP;

    -- Return the IDs of the inserted rows
    RETURN added_ids;
END;$$;


ALTER FUNCTION vwm_impex.import_geojson(geojson_data json) OWNER TO vwm_ats;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 1019 (class 1259 OID 34546)
-- Name: g_los; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.g_los (
    id_g_los integer NOT NULL,
    fim_id character varying,
    fim_status boolean,
    fim_type character varying,
    fim_version character varying,
    created timestamp without time zone,
    modified timestamp without time zone,
    imported timestamp without time zone,
    workflow integer,
    wf_wechsel_datum date,
    los_id integer,
    losnr character varying,
    unterlosnr character varying,
    jahr integer,
    spaufsucheaufnahmetruppkuerzel character varying,
    spaufsucheaufnahmetruppgnss character varying,
    spaufsuchenichtbegehbarursacheid integer,
    spaufsuchenichtwaldursacheid integer,
    spaufsucheverschobenursacheid integer,
    s_perma integer,
    istgeom_elev double precision,
    istgeom_sat integer,
    istgeom_hdop double precision,
    istgeom_vdop double precision,
    h3index_text character varying,
    h3i_hid character varying,
    aktuell_geom public.geometry(Point,4326),
    biotopid smallint,
    istgeom_y double precision,
    istgeom_x double precision,
    role_access regrole[]
);


ALTER TABLE vwm_impex.g_los OWNER TO waldinv_admin;

--
-- TOC entry 7577 (class 0 OID 0)
-- Dependencies: 1019
-- Name: COLUMN g_los.aktuell_geom; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.g_los.aktuell_geom IS 'wenn ist_geom vorhanden wird die genommen, sonst soll_geom';


--
-- TOC entry 7578 (class 0 OID 0)
-- Dependencies: 1019
-- Name: COLUMN g_los.biotopid; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.g_los.biotopid IS 'BiotoptypID, verschlüsselt in s_biotopbb';


--
-- TOC entry 7579 (class 0 OID 0)
-- Dependencies: 1019
-- Name: COLUMN g_los.istgeom_y; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.g_los.istgeom_y IS 'Long aus GNSS Messung im FIM';


--
-- TOC entry 7580 (class 0 OID 0)
-- Dependencies: 1019
-- Name: COLUMN g_los.istgeom_x; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.g_los.istgeom_x IS 'Lat aus GNSS Messung im FIM';


--
-- TOC entry 1018 (class 1259 OID 34545)
-- Name: g_los_id_g_los_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE vwm_impex.g_los ALTER COLUMN id_g_los ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME vwm_impex.g_los_id_g_los_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 1208 (class 1259 OID 44143)
-- Name: imp_b_strg; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_b_strg (
    bestbesid integer,
    s_strgid integer,
    los_id integer,
    glos_id integer
);


ALTER TABLE vwm_impex.imp_b_strg OWNER TO waldinv_admin;

--
-- TOC entry 7582 (class 0 OID 0)
-- Dependencies: 1208
-- Name: COLUMN imp_b_strg.bestbesid; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_b_strg.bestbesid IS 'ID der Bestandesbeschreibung t_bestbes';


--
-- TOC entry 7583 (class 0 OID 0)
-- Dependencies: 1208
-- Name: COLUMN imp_b_strg.s_strgid; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_b_strg.s_strgid IS 'ID aus s_strg';


--
-- TOC entry 7584 (class 0 OID 0)
-- Dependencies: 1208
-- Name: COLUMN imp_b_strg.los_id; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_b_strg.los_id IS 'los_id referenziert den Punkt und die Erhebung eindeutig';


--
-- TOC entry 1209 (class 1259 OID 44147)
-- Name: imp_b_strgsonstig; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_b_strgsonstig (
    idpunktinfo integer,
    stoerung text,
    los_id integer,
    glos_id integer
);


ALTER TABLE vwm_impex.imp_b_strgsonstig OWNER TO waldinv_admin;

--
-- TOC entry 1021 (class 1259 OID 34562)
-- Name: imp_t_baumplot; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_t_baumplot (
    id_t_bpl integer NOT NULL,
    los_id integer,
    bplotnr integer,
    onr integer,
    baid smallint,
    azi integer,
    dist integer,
    bhd integer,
    h_bhd integer DEFAULT 13,
    schal boolean,
    fege boolean,
    glos_id integer
);


ALTER TABLE vwm_impex.imp_t_baumplot OWNER TO waldinv_admin;

--
-- TOC entry 7587 (class 0 OID 0)
-- Dependencies: 1021
-- Name: TABLE imp_t_baumplot; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_baumplot IS 'Baumplot';


--
-- TOC entry 1020 (class 1259 OID 34561)
-- Name: imp_t_baumplot_id_t_bpl_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE vwm_impex.imp_t_baumplot ALTER COLUMN id_t_bpl ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME vwm_impex.imp_t_baumplot_id_t_bpl_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 1205 (class 1259 OID 44099)
-- Name: imp_t_besbodenveggr; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_t_besbodenveggr (
    id_besbodenveggr bigint NOT NULL,
    bodenveggr_id smallint,
    verteilung_id smallint,
    prozanteil smallint,
    bestbesid bigint,
    los_id integer,
    glos_id integer
);


ALTER TABLE vwm_impex.imp_t_besbodenveggr OWNER TO waldinv_admin;

--
-- TOC entry 7589 (class 0 OID 0)
-- Dependencies: 1205
-- Name: TABLE imp_t_besbodenveggr; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_besbodenveggr IS 'Daten zur Bodenvegetationsgruppe (bodenveggr) der Bestandesbeschreibung (bestbes)';


--
-- TOC entry 7590 (class 0 OID 0)
-- Dependencies: 1205
-- Name: COLUMN imp_t_besbodenveggr.bodenveggr_id; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_besbodenveggr.bodenveggr_id IS 'bodenvegetationsgruppe aus s_bodenveggr';


--
-- TOC entry 7591 (class 0 OID 0)
-- Dependencies: 1205
-- Name: COLUMN imp_t_besbodenveggr.verteilung_id; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_besbodenveggr.verteilung_id IS 'Verteilung aus s_vert';


--
-- TOC entry 7592 (class 0 OID 0)
-- Dependencies: 1205
-- Name: COLUMN imp_t_besbodenveggr.prozanteil; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_besbodenveggr.prozanteil IS 'Anteil der Gruppe die Erfasst wurde';


--
-- TOC entry 7593 (class 0 OID 0)
-- Dependencies: 1205
-- Name: COLUMN imp_t_besbodenveggr.bestbesid; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_besbodenveggr.bestbesid IS 'ID der Bestandesbeschreibung - kann zukünftig entfallen';


--
-- TOC entry 7594 (class 0 OID 0)
-- Dependencies: 1205
-- Name: COLUMN imp_t_besbodenveggr.los_id; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_besbodenveggr.los_id IS 'los_id referenziert eindeutig auf Punkt und Aufnahme in t_los';


--
-- TOC entry 1204 (class 1259 OID 44098)
-- Name: imp_t_besbodenveggr_id_besbodenveggr_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE vwm_impex.imp_t_besbodenveggr ALTER COLUMN id_besbodenveggr ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME vwm_impex.imp_t_besbodenveggr_id_besbodenveggr_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 1032 (class 1259 OID 34623)
-- Name: imp_t_bestbes; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_t_bestbes (
    id_bestbes bigint NOT NULL,
    los_id character varying,
    punktinfoid bigint,
    bea_id smallint,
    ksg_id smallint,
    sma_id smallint,
    bed_us smallint,
    bed_bodenveg smallint,
    nschicht_id integer,
    heterogenigrad integer DEFAULT 5,
    glos_id integer
);


ALTER TABLE vwm_impex.imp_t_bestbes OWNER TO waldinv_admin;

--
-- TOC entry 7596 (class 0 OID 0)
-- Dependencies: 1032
-- Name: TABLE imp_t_bestbes; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_bestbes IS 'Bestandesbeschreibung';


--
-- TOC entry 1031 (class 1259 OID 34622)
-- Name: imp_t_bestbes_id_bestbes_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE vwm_impex.imp_t_bestbes ALTER COLUMN id_bestbes ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME vwm_impex.imp_t_bestbes_id_bestbes_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 1034 (class 1259 OID 34652)
-- Name: imp_t_bestbess; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_t_bestbess (
    id_bestbess bigint NOT NULL,
    los_id integer,
    punktinfoid bigint,
    bestbesid integer,
    schicht_id smallint,
    ba_icode smallint,
    nas_id smallint,
    ba_anteil smallint,
    entsart_id smallint,
    vert_id smallint,
    glos_id integer
);


ALTER TABLE vwm_impex.imp_t_bestbess OWNER TO waldinv_admin;

--
-- TOC entry 7598 (class 0 OID 0)
-- Dependencies: 1034
-- Name: TABLE imp_t_bestbess; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_bestbess IS 'Bestandesbeschreibung, Schichten';


--
-- TOC entry 1033 (class 1259 OID 34651)
-- Name: imp_t_bestbess_id_bestbess_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE vwm_impex.imp_t_bestbess ALTER COLUMN id_bestbess ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME vwm_impex.imp_t_bestbess_id_bestbess_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 1026 (class 1259 OID 34590)
-- Name: imp_t_landmarke; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_t_landmarke (
    id_imp_landmarke integer NOT NULL,
    los_id integer,
    punktinfoid bigint NOT NULL,
    lplotnr integer,
    onr integer NOT NULL,
    typ character varying,
    azi integer,
    dist integer,
    glos_id integer
);


ALTER TABLE vwm_impex.imp_t_landmarke OWNER TO waldinv_admin;

--
-- TOC entry 7600 (class 0 OID 0)
-- Dependencies: 1026
-- Name: TABLE imp_t_landmarke; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_landmarke IS 'Landmarke';


--
-- TOC entry 1024 (class 1259 OID 34588)
-- Name: imp_t_landmarke_id_imp_landmarke_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE vwm_impex.imp_t_landmarke ALTER COLUMN id_imp_landmarke ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME vwm_impex.imp_t_landmarke_id_imp_landmarke_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 1025 (class 1259 OID 34589)
-- Name: imp_t_landmarke_onr_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE vwm_impex.imp_t_landmarke ALTER COLUMN onr ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME vwm_impex.imp_t_landmarke_onr_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 8
    CACHE 1
    CYCLE
);


--
-- TOC entry 1023 (class 1259 OID 34571)
-- Name: imp_t_punktinfo; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_t_punktinfo (
    los_id character varying NOT NULL,
    h3index_text character varying,
    nichtwaldid character varying,
    sbgeh_icode integer,
    verlegg_id integer,
    istgeomid bigint,
    idpunktinfo integer,
    biotopid smallint,
    perma_id integer
);


ALTER TABLE vwm_impex.imp_t_punktinfo OWNER TO waldinv_admin;

--
-- TOC entry 7602 (class 0 OID 0)
-- Dependencies: 1023
-- Name: TABLE imp_t_punktinfo; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_punktinfo IS 'Punktinformation';


--
-- TOC entry 1022 (class 1259 OID 34570)
-- Name: imp_t_punktinfo_idpunktinfo_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE SEQUENCE vwm_impex.imp_t_punktinfo_idpunktinfo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE vwm_impex.imp_t_punktinfo_idpunktinfo_seq OWNER TO waldinv_admin;

--
-- TOC entry 7604 (class 0 OID 0)
-- Dependencies: 1022
-- Name: imp_t_punktinfo_idpunktinfo_seq; Type: SEQUENCE OWNED BY; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER SEQUENCE vwm_impex.imp_t_punktinfo_idpunktinfo_seq OWNED BY vwm_impex.imp_t_punktinfo.idpunktinfo;


--
-- TOC entry 1030 (class 1259 OID 34612)
-- Name: imp_t_transekt; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_t_transekt (
    id_transekt bigint NOT NULL,
    los_id integer,
    transekti_id bigint,
    ba_icode smallint,
    hst smallint,
    sma_id smallint,
    bhd integer,
    verb boolean DEFAULT false,
    trck boolean DEFAULT false,
    frost boolean DEFAULT false,
    insekt boolean DEFAULT false,
    schael_fege boolean DEFAULT false,
    glos_id integer
);


ALTER TABLE vwm_impex.imp_t_transekt OWNER TO waldinv_admin;

--
-- TOC entry 7605 (class 0 OID 0)
-- Dependencies: 1030
-- Name: TABLE imp_t_transekt; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_transekt IS 'Verjüngungstransekt';


--
-- TOC entry 1029 (class 1259 OID 34611)
-- Name: imp_t_transekt_id_transekt_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE vwm_impex.imp_t_transekt ALTER COLUMN id_transekt ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME vwm_impex.imp_t_transekt_id_transekt_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 1028 (class 1259 OID 34598)
-- Name: imp_t_transektinfo; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_t_transektinfo (
    id_transektinfo integer NOT NULL,
    los_id integer,
    punktinfoid bigint,
    laenge integer,
    tempstoerung boolean DEFAULT false,
    hase boolean DEFAULT false,
    maus boolean DEFAULT false,
    biber boolean DEFAULT false,
    homogen boolean DEFAULT false,
    sma_id integer DEFAULT 0,
    krautanteil integer,
    azi integer,
    transektstoerungursache character varying,
    glos_id integer
);


ALTER TABLE vwm_impex.imp_t_transektinfo OWNER TO waldinv_admin;

--
-- TOC entry 7607 (class 0 OID 0)
-- Dependencies: 1028
-- Name: TABLE imp_t_transektinfo; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_transektinfo IS 'Informationen zum Transekt - t_transekt. Es besteht die Möglichkeit an einem SP mehrere Transekte anzulegen.';


--
-- TOC entry 7608 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.los_id; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.los_id IS 'eindeutige Referenzierung von Punkt und Aufnahme über t_los';


--
-- TOC entry 7609 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.punktinfoid; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.punktinfoid IS 'Referenzierung auf punktinfo - kann zukünftig entfallen wenn Felder nach t_los überführt';


--
-- TOC entry 7610 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.laenge; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.laenge IS 'Transektlänge in dm - Standard 200';


--
-- TOC entry 7611 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.tempstoerung; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.tempstoerung IS 'Temporärer Störung die aktuell eine Aufnahme verhindert';


--
-- TOC entry 7612 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.hase; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.hase IS 'Verbiss von Hase im Transekt';


--
-- TOC entry 7613 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.maus; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.maus IS 'Verbiss von Maus im Transekt';


--
-- TOC entry 7614 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.biber; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.biber IS 'Verbiss von Biber im Transekt';


--
-- TOC entry 7615 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.homogen; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.homogen IS 'kann zukünftig entfallen - war mal zur Arbeitserleichterung gedacht';


--
-- TOC entry 7616 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.sma_id; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.sma_id IS 'Schutzmaßnahmen-id aus s_sma';


--
-- TOC entry 7617 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.krautanteil; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.krautanteil IS 'Anteil der Kräuter und Sträucher im Transekt';


--
-- TOC entry 7618 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.azi; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.azi IS 'Azimut des Transektes vom SP aus';


--
-- TOC entry 7619 (class 0 OID 0)
-- Dependencies: 1028
-- Name: COLUMN imp_t_transektinfo.transektstoerungursache; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektinfo.transektstoerungursache IS 'Ursache für tempstoerung';


--
-- TOC entry 1027 (class 1259 OID 34597)
-- Name: imp_t_transektinfo_id_transektinfo_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE vwm_impex.imp_t_transektinfo ALTER COLUMN id_transektinfo ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME vwm_impex.imp_t_transektinfo_id_transektinfo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 1036 (class 1259 OID 34658)
-- Name: imp_t_transektipf; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_t_transektipf (
    id_tripfl bigint NOT NULL,
    los_id integer,
    transekti_id bigint,
    indikpfl_id integer,
    anteilsprozent integer,
    glos_id integer
);


ALTER TABLE vwm_impex.imp_t_transektipf OWNER TO waldinv_admin;

--
-- TOC entry 7621 (class 0 OID 0)
-- Dependencies: 1036
-- Name: TABLE imp_t_transektipf; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_transektipf IS 'Indikatorpflanzen im Transekt';


--
-- TOC entry 7622 (class 0 OID 0)
-- Dependencies: 1036
-- Name: COLUMN imp_t_transektipf.los_id; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektipf.los_id IS 'eindeutige Referenzierung des Punktes und der Aufnahme aus t_los';


--
-- TOC entry 7623 (class 0 OID 0)
-- Dependencies: 1036
-- Name: COLUMN imp_t_transektipf.transekti_id; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektipf.transekti_id IS 'transektinfo_id ursprüngliche Referenzierung - kann zukünftig entfallen';


--
-- TOC entry 7624 (class 0 OID 0)
-- Dependencies: 1036
-- Name: COLUMN imp_t_transektipf.indikpfl_id; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektipf.indikpfl_id IS 'Indikatorpflanzen_id aus vwm.s_indikpfl';


--
-- TOC entry 7625 (class 0 OID 0)
-- Dependencies: 1036
-- Name: COLUMN imp_t_transektipf.anteilsprozent; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON COLUMN vwm_impex.imp_t_transektipf.anteilsprozent IS 'Anteil der Indikatorpflanze an der Aufnahmefläche im Transekt';


--
-- TOC entry 1035 (class 1259 OID 34657)
-- Name: imp_t_transektipf_id_tripfl_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE vwm_impex.imp_t_transektipf ALTER COLUMN id_tripfl ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME vwm_impex.imp_t_transektipf_id_tripfl_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 7117 (class 2606 OID 34552)
-- Name: g_los g_los_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.g_los
    ADD CONSTRAINT g_los_pkey PRIMARY KEY (id_g_los);


--
-- TOC entry 7119 (class 2606 OID 34569)
-- Name: imp_t_baumplot imp_t_baumplot_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_baumplot
    ADD CONSTRAINT imp_t_baumplot_pkey PRIMARY KEY (id_t_bpl);


--
-- TOC entry 7133 (class 2606 OID 44103)
-- Name: imp_t_besbodenveggr imp_t_besbodenveggr_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_besbodenveggr
    ADD CONSTRAINT imp_t_besbodenveggr_pkey PRIMARY KEY (id_besbodenveggr);


--
-- TOC entry 7127 (class 2606 OID 34628)
-- Name: imp_t_bestbes imp_t_bestbes_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_bestbes
    ADD CONSTRAINT imp_t_bestbes_pkey PRIMARY KEY (id_bestbes);


--
-- TOC entry 7129 (class 2606 OID 34656)
-- Name: imp_t_bestbess imp_t_bestbess_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_bestbess
    ADD CONSTRAINT imp_t_bestbess_pkey PRIMARY KEY (id_bestbess);


--
-- TOC entry 7121 (class 2606 OID 34596)
-- Name: imp_t_landmarke imp_t_landmarke_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_landmarke
    ADD CONSTRAINT imp_t_landmarke_pkey PRIMARY KEY (id_imp_landmarke);


--
-- TOC entry 7125 (class 2606 OID 34621)
-- Name: imp_t_transekt imp_t_transekt_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_transekt
    ADD CONSTRAINT imp_t_transekt_pkey PRIMARY KEY (id_transekt);


--
-- TOC entry 7123 (class 2606 OID 34610)
-- Name: imp_t_transektinfo imp_t_transektinfo_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_transektinfo
    ADD CONSTRAINT imp_t_transektinfo_pkey PRIMARY KEY (id_transektinfo);


--
-- TOC entry 7131 (class 2606 OID 34662)
-- Name: imp_t_transektipf imp_t_transektipf_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_transektipf
    ADD CONSTRAINT imp_t_transektipf_pkey PRIMARY KEY (id_tripfl);


--
-- TOC entry 7115 (class 1259 OID 34553)
-- Name: g_los_ist_geom_idx; Type: INDEX; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE INDEX g_los_ist_geom_idx ON vwm_impex.g_los USING gist (aktuell_geom);


--
-- TOC entry 7134 (class 2606 OID 44228)
-- Name: imp_t_baumplot fk_g_los; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_baumplot
    ADD CONSTRAINT fk_g_los FOREIGN KEY (glos_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;


--
-- TOC entry 7135 (class 2606 OID 44233)
-- Name: imp_t_landmarke fk_g_los; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_landmarke
    ADD CONSTRAINT fk_g_los FOREIGN KEY (glos_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;


--
-- TOC entry 7144 (class 2606 OID 44238)
-- Name: imp_t_besbodenveggr fk_g_los; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_besbodenveggr
    ADD CONSTRAINT fk_g_los FOREIGN KEY (glos_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;


--
-- TOC entry 7139 (class 2606 OID 44243)
-- Name: imp_t_bestbes fk_g_los; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_bestbes
    ADD CONSTRAINT fk_g_los FOREIGN KEY (glos_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;


--
-- TOC entry 7140 (class 2606 OID 44248)
-- Name: imp_t_bestbess fk_g_los; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_bestbess
    ADD CONSTRAINT fk_g_los FOREIGN KEY (glos_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;


--
-- TOC entry 7137 (class 2606 OID 44253)
-- Name: imp_t_transekt fk_g_los; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_transekt
    ADD CONSTRAINT fk_g_los FOREIGN KEY (glos_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;


--
-- TOC entry 7136 (class 2606 OID 44258)
-- Name: imp_t_transektinfo fk_g_los; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_transektinfo
    ADD CONSTRAINT fk_g_los FOREIGN KEY (glos_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;


--
-- TOC entry 7142 (class 2606 OID 44263)
-- Name: imp_t_transektipf fk_g_los; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_transektipf
    ADD CONSTRAINT fk_g_los FOREIGN KEY (glos_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;


--
-- TOC entry 7146 (class 2606 OID 44268)
-- Name: imp_b_strg fk_g_los; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_b_strg
    ADD CONSTRAINT fk_g_los FOREIGN KEY (glos_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;


--
-- TOC entry 7147 (class 2606 OID 44273)
-- Name: imp_b_strgsonstig fk_g_los; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_b_strgsonstig
    ADD CONSTRAINT fk_g_los FOREIGN KEY (glos_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;


--
-- TOC entry 7145 (class 2606 OID 44288)
-- Name: imp_t_besbodenveggr imp_t_besbodenveggr_imp_t_bestbes_fk; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_besbodenveggr
    ADD CONSTRAINT imp_t_besbodenveggr_imp_t_bestbes_fk FOREIGN KEY (bestbesid) REFERENCES vwm_impex.imp_t_bestbes(id_bestbes);


--
-- TOC entry 7141 (class 2606 OID 44283)
-- Name: imp_t_bestbess imp_t_bestbess_imp_t_bestbes_fk; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_bestbess
    ADD CONSTRAINT imp_t_bestbess_imp_t_bestbes_fk FOREIGN KEY (bestbesid) REFERENCES vwm_impex.imp_t_bestbes(id_bestbes);


--
-- TOC entry 7138 (class 2606 OID 44278)
-- Name: imp_t_transekt imp_t_transekt_imp_t_transektinfo_fk; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_transekt
    ADD CONSTRAINT imp_t_transekt_imp_t_transektinfo_fk FOREIGN KEY (transekti_id) REFERENCES vwm_impex.imp_t_transektinfo(id_transektinfo);


--
-- TOC entry 7143 (class 2606 OID 44293)
-- Name: imp_t_transektipf imp_t_transektipf_imp_t_transektinfo_fk; Type: FK CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_transektipf
    ADD CONSTRAINT imp_t_transektipf_imp_t_transektinfo_fk FOREIGN KEY (transekti_id) REFERENCES vwm_impex.imp_t_transektinfo(id_transektinfo);


--
-- TOC entry 7575 (class 0 OID 0)
-- Dependencies: 19
-- Name: SCHEMA vwm_impex; Type: ACL; Schema: -; Owner: waldinv_admin
--

GRANT ALL ON SCHEMA vwm_impex TO vwm_ats;
GRANT USAGE ON SCHEMA vwm_impex TO lfb_read;
GRANT USAGE ON SCHEMA vwm_impex TO simplex4data_lfb;
GRANT USAGE ON SCHEMA vwm_impex TO vwm_kts;
GRANT ALL ON SCHEMA vwm_impex TO twiebke;


--
-- TOC entry 7576 (class 0 OID 0)
-- Dependencies: 4565
-- Name: LANGUAGE plpgsql; Type: ACL; Schema: -; Owner: simplex4data_main
--

GRANT ALL ON LANGUAGE plpgsql TO waldinv_admin;


--
-- TOC entry 7581 (class 0 OID 0)
-- Dependencies: 1019
-- Name: TABLE g_los; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.g_los TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.g_los TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.g_los TO simplex4data_lfb;


--
-- TOC entry 7585 (class 0 OID 0)
-- Dependencies: 1208
-- Name: TABLE imp_b_strg; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_b_strg TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_b_strg TO lfb_read;


--
-- TOC entry 7586 (class 0 OID 0)
-- Dependencies: 1209
-- Name: TABLE imp_b_strgsonstig; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_b_strgsonstig TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_b_strgsonstig TO lfb_read;


--
-- TOC entry 7588 (class 0 OID 0)
-- Dependencies: 1021
-- Name: TABLE imp_t_baumplot; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_baumplot TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_baumplot TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_baumplot TO simplex4data_lfb;


--
-- TOC entry 7595 (class 0 OID 0)
-- Dependencies: 1205
-- Name: TABLE imp_t_besbodenveggr; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_besbodenveggr TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_besbodenveggr TO lfb_read;


--
-- TOC entry 7597 (class 0 OID 0)
-- Dependencies: 1032
-- Name: TABLE imp_t_bestbes; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_bestbes TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_bestbes TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_bestbes TO simplex4data_lfb;


--
-- TOC entry 7599 (class 0 OID 0)
-- Dependencies: 1034
-- Name: TABLE imp_t_bestbess; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_bestbess TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_bestbess TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_bestbess TO simplex4data_lfb;


--
-- TOC entry 7601 (class 0 OID 0)
-- Dependencies: 1026
-- Name: TABLE imp_t_landmarke; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_landmarke TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_landmarke TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_landmarke TO simplex4data_lfb;


--
-- TOC entry 7603 (class 0 OID 0)
-- Dependencies: 1023
-- Name: TABLE imp_t_punktinfo; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_punktinfo TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_punktinfo TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_punktinfo TO simplex4data_lfb;


--
-- TOC entry 7606 (class 0 OID 0)
-- Dependencies: 1030
-- Name: TABLE imp_t_transekt; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_transekt TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_transekt TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_transekt TO simplex4data_lfb;


--
-- TOC entry 7620 (class 0 OID 0)
-- Dependencies: 1028
-- Name: TABLE imp_t_transektinfo; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_transektinfo TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_transektinfo TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_transektinfo TO simplex4data_lfb;


--
-- TOC entry 7626 (class 0 OID 0)
-- Dependencies: 1036
-- Name: TABLE imp_t_transektipf; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_transektipf TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_transektipf TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_transektipf TO simplex4data_lfb;


-- Completed on 2024-07-22 17:22:09 UTC

--
-- PostgreSQL database dump complete
--

