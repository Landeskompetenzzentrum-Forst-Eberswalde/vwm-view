--
-- PostgreSQL database dump
--

-- Dumped from database version 14.12
-- Dumped by pg_dump version 14.12

-- Started on 2024-07-16 15:57:01 UTC

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


ALTER SCHEMA vwm_impex OWNER TO waldinv_admin;

--
-- TOC entry 2657 (class 1255 OID 44093)
-- Name: export_geojson(); Type: FUNCTION; Schema: vwm_impex; Owner: vwm_ats
--

CREATE FUNCTION vwm_impex.export_geojson() RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN

    RETURN json_build_object(
        'type', 'FeatureCollection',
        'name', 'FIM - Forest Inventory and Monitoring',
        'crs', json_build_object(
            'type', 'name',
            'properties', json_build_object(
                'name', 'urn:ogc:def:crs:OGC:1.3:CRS84'
            )
        ),
        'features', (
            SELECT json_agg(
                json_build_object(
                    'type', 'Feature',  
            'geometry', ST_AsGeoJSON(g.ist_geom, 15)::json,
            'properties', json_build_object(
                'id', g.fim_id,
                'los_id', g.id_g_los,
                'created', g.created,
                'modified', g.modified,
                'status', g.fim_status,
                'workflow', g.workflow,
                'type', g.fim_type,
                'version', g.fim_version,
                'form', 
                    json_build_object(
                        'general', json_build_object(
                                'spaufsucheaufnahmetruppkuerzel', g.spaufsucheaufnahmetruppkuerzel,
                                'spaufsuchenichtbegehbarursacheid', g.spaufsuchenichtbegehbarursacheid,
                                'spaufsucheaufnahmetruppgnss', g.spaufsucheaufnahmetruppgnss,
                                'spaufsuchenichtwaldursacheid', g.spaufsuchenichtwaldursacheid,
                                'spaufsucheverschobenursacheid', g.spaufsucheverschobenursacheid
                        ),
                        'coordinates', json_build_object(
                            'spaufsucheverschobenursacheid', g.spaufsucheverschobenursacheid,
                            's_perma', g.s_perma,
                            'istgeom_x', ST_X(g.ist_geom),
                            'istgeom_y', ST_Y(g.ist_geom),
                            'istgeom_elev', g.istgeom_elev,
                            'istgeom_sat', g.istgeom_sat,
                            'istgeom_hdop', g.istgeom_hdop,
                            'istgeom_vdop', g.istgeom_vdop
                        ),
                        'stichprobenpunkt', json_build_object(),
                        'baumplot1', json_build_object(
                            'baumplot1',(
                                SELECT json_agg(
                                    json_build_object(
                                        'icode_ba', bp.baid,
                                        'azimut', bp.azi,
                                        'distanz', bp.dist,
                                        'bhd', bp.bhd,
                                        'messhoehebhd', bp.h_bhd,
                                        'schaele', bp.schal,
                                        'fege', bp.schal
                                    )
                                )
                                FROM vwm_impex.imp_t_baumplot bp
                                WHERE bp.los_id = g.id_g_los AND bplotnr = 1
                            ),
                            'transectLocation', 0,
                            'azimuttransektploteins', (
                                SELECT ti.azi
                                FROM vwm_impex.imp_t_transektinfo ti
                                WHERE ti.los_id = g.id_g_los
                            )
                        ),
                        'landmarken1', json_build_object(
                            'landmarken1',(
                                SELECT json_agg(
                                    json_build_object(
                                        'landmarken', lm1.typ,
                                        'azimut', lm1.azi,
                                        'distanz', lm1.dist
                                    )
                                )
                                FROM vwm_impex.imp_t_landmarke lm1
                                WHERE lm1.los_id = g.id_g_los AND lplotnr = 1
                            )
                        ),
                        'baumplot2', json_build_object(
                            'baumplot2',(
                                SELECT json_agg(
                                    json_build_object(
                                        'icode_ba', bp2.baid,
                                        'azimut', bp2.azi,
                                        'distanz', bp2.dist,
                                        'bhd', bp2.bhd,
                                        'messhoehebhd', bp2.h_bhd,
                                        'schaele', bp2.schal,
                                        'fege', bp2.schal
                                    )
                                )
                                FROM vwm_impex.imp_t_baumplot bp2
                                WHERE bp2.los_id = g.id_g_los AND bplotnr = 2
                               
                            )
                        ),
                        'landmarken1', json_build_object(
                            'landmarken1',(
                                SELECT json_agg(
                                    json_build_object(
                                        'landmarken', lm2.typ,
                                        'azimut', lm2.azi,
                                        'distanz', lm2.dist
                                    )
                                )
                                FROM vwm_impex.imp_t_landmarke lm2
                                WHERE lm2.los_id = g.id_g_los AND lplotnr = 2
                            )
                        ),
                        'verjuengungstransekt', json_build_object(
                            'verjuengungstransekten',(
                                SELECT json_agg(
                                    json_build_object(
                                        'ba_icode', vt.ba_icode,
                                        'height', vt.hst,
                                        'verjuengungstransektschutzmassnahmen', vt.sma_id,
                                        'verjuengungstransektbhd', vt.bhd,
                                        'verjuengungstransekttriebverlustdurchschalenwildverbiss', vt.verb,
                                        'verjuengungstransekttriebverlustdurchtrockenheit', vt.trck,
                                        'verjuengungstransekttriebverlustdurchfrost', vt.frost,
                                        'verjuengungstransekttriebverlustdurchinsektenfrass', vt.insekt,
                                        'verjuengungstransekttriebverlustdurchfege', vt.schael_fege
                                    )
                                )
                                FROM vwm_impex.imp_t_transekt vt
                                WHERE vt.los_id = g.id_g_los
                            ),
                            'transectLength', 0,
                            'verjuengungstransektlaenge', (
                                SELECT ti.laenge
                                FROM vwm_impex.imp_t_transektinfo ti
                                WHERE ti.los_id = g.id_g_los
                            )
                        ),
                        'transektinfo', (
                            SELECT json_agg(
                                json_build_object(
                                    'transektfrasshase', ti.hase,
                                    'transektfrassmaus', ti.maus,
                                    'transektfrassbieber', ti.biber
                                )
                            )
                            FROM vwm_impex.imp_t_transektinfo ti
                            WHERE ti.los_id = g.id_g_los
                            
                        ),
                        'bestandsbeschreibung', (
                            SELECT json_agg(
                                json_build_object(
                                    'bestandheterogenitaetsgradid', bestbes.heterogenigrad,
                                    'bestandnschichtigid', bestbes.nschicht_id,
                                    'bestandbetriebsartid', bestbes.bea_id,
                                    'bestandkronenschlussgradid', bestbes.ksg_id,
                                    'bestandschutzmassnahmenid', bestbes.sma_id,
                                    'bestandbedeckungsgradunterstand', bestbes.bed_us,
                                    'bestandbedeckungsgradgraeser', bestbes.bed_bodenveg
                                )
                            )
                            FROM vwm_impex.imp_t_bestbes bestbes
                            WHERE bestbes.los_id = g.id_g_los
                            
                        ),
                        't_bestockung', json_build_object(
                            't_bestockung',(
                                SELECT json_agg(
                                    json_build_object(
                                        'schicht_id', bess.schicht_id,
                                        'icode_ba', bess.ba_icode,
                                        'nas_id', bess.nas_id,
                                        'ba_anteil', bess.ba_anteil,
                                        'entsart_id', bess.entsart_id,
                                        'vert_id', bess.vert_id
                                    )
                                )
                                FROM vwm_impex.imp_t_bestbess bess
                                WHERE bess.los_id = g.id_g_los
                               
                            )
                        ),
                        't_bodenvegetation', json_build_object(
                            't_bodenvegetation',(
                                SELECT json_agg(
                                    json_build_object(
                                        'verteilung', tipf.transekti_id,
                                        'bodenveggr', tipf.indikpfl_id,
                                        'anteil', tipf.anteilsprozent
                                    )
                                )
                                FROM vwm_impex.imp_t_transektipf tipf
                                WHERE tipf.los_id = g.id_g_los
                               
                            )
                        )
                    )
                )
            
                )
            )
            FROM vwm_impex.g_los g
        )
    );
END;
$$;


ALTER FUNCTION vwm_impex.export_geojson() OWNER TO vwm_ats;

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
    los_id character varying,
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
    ist_geom public.geometry(Point,4326)
);


ALTER TABLE vwm_impex.g_los OWNER TO waldinv_admin;

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
-- TOC entry 1021 (class 1259 OID 34562)
-- Name: imp_t_baumplot; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_t_baumplot (
    id_t_bpl integer NOT NULL,
    los_id character varying,
    bplotnr integer,
    onr integer,
    baid smallint,
    azi integer,
    dist integer,
    bhd integer,
    h_bhd integer DEFAULT 13,
    schal boolean,
    fege boolean
);


ALTER TABLE vwm_impex.imp_t_baumplot OWNER TO waldinv_admin;

--
-- TOC entry 7555 (class 0 OID 0)
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
-- TOC entry 1206 (class 1259 OID 44099)
-- Name: imp_t_besbodenveggr; Type: TABLE; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE TABLE vwm_impex.imp_t_besbodenveggr (
    id_besbodenveggr bigint NOT NULL,
    bodenveggr_id smallint,
    verteilung_id smallint,
    prozanteil smallint,
    bestbesid bigint,
    los_id integer
);


ALTER TABLE vwm_impex.imp_t_besbodenveggr OWNER TO waldinv_admin;

--
-- TOC entry 7557 (class 0 OID 0)
-- Dependencies: 1206
-- Name: TABLE imp_t_besbodenveggr; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_besbodenveggr IS 'Daten zur Bodenvegetationsgruppe (bodenveggr) der Bestandesbeschreibung (bestbes)';


--
-- TOC entry 1205 (class 1259 OID 44098)
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
    heterogenigrad integer DEFAULT 5
);


ALTER TABLE vwm_impex.imp_t_bestbes OWNER TO waldinv_admin;

--
-- TOC entry 7559 (class 0 OID 0)
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
    vert_id smallint
);


ALTER TABLE vwm_impex.imp_t_bestbess OWNER TO waldinv_admin;

--
-- TOC entry 7561 (class 0 OID 0)
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
    los_id character varying,
    punktinfoid bigint NOT NULL,
    lplotnr integer,
    onr integer NOT NULL,
    typ character varying,
    azi integer,
    dist integer
);


ALTER TABLE vwm_impex.imp_t_landmarke OWNER TO waldinv_admin;

--
-- TOC entry 7563 (class 0 OID 0)
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
-- TOC entry 7565 (class 0 OID 0)
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
-- TOC entry 7567 (class 0 OID 0)
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
    los_id character varying,
    transekti_id bigint,
    ba_icode smallint,
    hst smallint,
    sma_id smallint,
    bhd integer,
    verb boolean DEFAULT false,
    trck boolean DEFAULT false,
    frost boolean DEFAULT false,
    insekt boolean DEFAULT false,
    schael_fege boolean DEFAULT false
);


ALTER TABLE vwm_impex.imp_t_transekt OWNER TO waldinv_admin;

--
-- TOC entry 7568 (class 0 OID 0)
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
    los_id character varying,
    punktinfoid bigint,
    laenge integer,
    tempstoerung boolean DEFAULT false,
    hase boolean DEFAULT false,
    maus boolean DEFAULT false,
    biber boolean DEFAULT false,
    homogen boolean DEFAULT false,
    sma_id integer DEFAULT 0,
    krautanteil integer,
    azi integer
);


ALTER TABLE vwm_impex.imp_t_transektinfo OWNER TO waldinv_admin;

--
-- TOC entry 7570 (class 0 OID 0)
-- Dependencies: 1028
-- Name: TABLE imp_t_transektinfo; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_transektinfo IS 'Informationen zum Transekt - t_transekt. Es besteht die Möglichkeit an einem SP mehrere Transekte anzulegen.';


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
    transektinfoid bigint NOT NULL
);


ALTER TABLE vwm_impex.imp_t_transektipf OWNER TO waldinv_admin;

--
-- TOC entry 7572 (class 0 OID 0)
-- Dependencies: 1036
-- Name: TABLE imp_t_transektipf; Type: COMMENT; Schema: vwm_impex; Owner: waldinv_admin
--

COMMENT ON TABLE vwm_impex.imp_t_transektipf IS 'Indikatorpflanzen im Transekt';


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
-- TOC entry 7108 (class 2606 OID 34552)
-- Name: g_los g_los_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.g_los
    ADD CONSTRAINT g_los_pkey PRIMARY KEY (id_g_los);


--
-- TOC entry 7110 (class 2606 OID 34569)
-- Name: imp_t_baumplot imp_t_baumplot_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_baumplot
    ADD CONSTRAINT imp_t_baumplot_pkey PRIMARY KEY (id_t_bpl);


--
-- TOC entry 7124 (class 2606 OID 44103)
-- Name: imp_t_besbodenveggr imp_t_besbodenveggr_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_besbodenveggr
    ADD CONSTRAINT imp_t_besbodenveggr_pkey PRIMARY KEY (id_besbodenveggr);


--
-- TOC entry 7118 (class 2606 OID 34628)
-- Name: imp_t_bestbes imp_t_bestbes_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_bestbes
    ADD CONSTRAINT imp_t_bestbes_pkey PRIMARY KEY (id_bestbes);


--
-- TOC entry 7120 (class 2606 OID 34656)
-- Name: imp_t_bestbess imp_t_bestbess_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_bestbess
    ADD CONSTRAINT imp_t_bestbess_pkey PRIMARY KEY (id_bestbess);


--
-- TOC entry 7112 (class 2606 OID 34596)
-- Name: imp_t_landmarke imp_t_landmarke_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_landmarke
    ADD CONSTRAINT imp_t_landmarke_pkey PRIMARY KEY (id_imp_landmarke);


--
-- TOC entry 7116 (class 2606 OID 34621)
-- Name: imp_t_transekt imp_t_transekt_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_transekt
    ADD CONSTRAINT imp_t_transekt_pkey PRIMARY KEY (id_transekt);


--
-- TOC entry 7114 (class 2606 OID 34610)
-- Name: imp_t_transektinfo imp_t_transektinfo_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_transektinfo
    ADD CONSTRAINT imp_t_transektinfo_pkey PRIMARY KEY (id_transektinfo);


--
-- TOC entry 7122 (class 2606 OID 34662)
-- Name: imp_t_transektipf imp_t_transektipf_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: waldinv_admin
--

ALTER TABLE ONLY vwm_impex.imp_t_transektipf
    ADD CONSTRAINT imp_t_transektipf_pkey PRIMARY KEY (id_tripfl);


--
-- TOC entry 7106 (class 1259 OID 34553)
-- Name: g_los_ist_geom_idx; Type: INDEX; Schema: vwm_impex; Owner: waldinv_admin
--

CREATE INDEX g_los_ist_geom_idx ON vwm_impex.g_los USING gist (ist_geom);


--
-- TOC entry 7553 (class 0 OID 0)
-- Dependencies: 19
-- Name: SCHEMA vwm_impex; Type: ACL; Schema: -; Owner: waldinv_admin
--

GRANT ALL ON SCHEMA vwm_impex TO vwm_ats;
GRANT USAGE ON SCHEMA vwm_impex TO lfb_read;
GRANT USAGE ON SCHEMA vwm_impex TO simplex4data_lfb;
GRANT USAGE ON SCHEMA vwm_impex TO vwm_kts;
GRANT ALL ON SCHEMA vwm_impex TO twiebke;


--
-- TOC entry 7554 (class 0 OID 0)
-- Dependencies: 1019
-- Name: TABLE g_los; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.g_los TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.g_los TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.g_los TO simplex4data_lfb;


--
-- TOC entry 7556 (class 0 OID 0)
-- Dependencies: 1021
-- Name: TABLE imp_t_baumplot; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_baumplot TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_baumplot TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_baumplot TO simplex4data_lfb;


--
-- TOC entry 7558 (class 0 OID 0)
-- Dependencies: 1206
-- Name: TABLE imp_t_besbodenveggr; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_besbodenveggr TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_besbodenveggr TO lfb_read;


--
-- TOC entry 7560 (class 0 OID 0)
-- Dependencies: 1032
-- Name: TABLE imp_t_bestbes; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_bestbes TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_bestbes TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_bestbes TO simplex4data_lfb;


--
-- TOC entry 7562 (class 0 OID 0)
-- Dependencies: 1034
-- Name: TABLE imp_t_bestbess; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_bestbess TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_bestbess TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_bestbess TO simplex4data_lfb;


--
-- TOC entry 7564 (class 0 OID 0)
-- Dependencies: 1026
-- Name: TABLE imp_t_landmarke; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_landmarke TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_landmarke TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_landmarke TO simplex4data_lfb;


--
-- TOC entry 7566 (class 0 OID 0)
-- Dependencies: 1023
-- Name: TABLE imp_t_punktinfo; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_punktinfo TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_punktinfo TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_punktinfo TO simplex4data_lfb;


--
-- TOC entry 7569 (class 0 OID 0)
-- Dependencies: 1030
-- Name: TABLE imp_t_transekt; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_transekt TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_transekt TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_transekt TO simplex4data_lfb;


--
-- TOC entry 7571 (class 0 OID 0)
-- Dependencies: 1028
-- Name: TABLE imp_t_transektinfo; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_transektinfo TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_transektinfo TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_transektinfo TO simplex4data_lfb;


--
-- TOC entry 7573 (class 0 OID 0)
-- Dependencies: 1036
-- Name: TABLE imp_t_transektipf; Type: ACL; Schema: vwm_impex; Owner: waldinv_admin
--

GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLE vwm_impex.imp_t_transektipf TO vwm_ats;
GRANT SELECT ON TABLE vwm_impex.imp_t_transektipf TO lfb_read;
GRANT SELECT ON TABLE vwm_impex.imp_t_transektipf TO simplex4data_lfb;


-- Completed on 2024-07-16 15:57:09 UTC

--
-- PostgreSQL database dump complete
--

