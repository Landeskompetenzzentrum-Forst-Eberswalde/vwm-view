--
-- PostgreSQL database dump
--

-- Dumped from database version 14.12
-- Dumped by pg_dump version 16.0

-- Started on 2024-07-01 21:38:59 CEST

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
-- TOC entry 27 (class 2615 OID 34436)
-- Name: vwm_impex; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA vwm_impex;


ALTER SCHEMA vwm_impex OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 1019 (class 1259 OID 34546)
-- Name: g_los; Type: TABLE; Schema: vwm_impex; Owner: postgres
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


ALTER TABLE vwm_impex.g_los OWNER TO postgres;

--
-- TOC entry 1018 (class 1259 OID 34545)
-- Name: g_los_id_g_los_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: postgres
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
-- Name: imp_t_baumplot; Type: TABLE; Schema: vwm_impex; Owner: postgres
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


ALTER TABLE vwm_impex.imp_t_baumplot OWNER TO postgres;

--
-- TOC entry 1020 (class 1259 OID 34561)
-- Name: imp_t_baumplot_id_t_bpl_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: postgres
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
-- TOC entry 1032 (class 1259 OID 34623)
-- Name: imp_t_bestbes; Type: TABLE; Schema: vwm_impex; Owner: postgres
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


ALTER TABLE vwm_impex.imp_t_bestbes OWNER TO postgres;

--
-- TOC entry 1031 (class 1259 OID 34622)
-- Name: imp_t_bestbes_id_bestbes_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: postgres
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
-- Name: imp_t_bestbess; Type: TABLE; Schema: vwm_impex; Owner: postgres
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


ALTER TABLE vwm_impex.imp_t_bestbess OWNER TO postgres;

--
-- TOC entry 1033 (class 1259 OID 34651)
-- Name: imp_t_bestbess_id_bestbess_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: postgres
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
-- Name: imp_t_landmarke; Type: TABLE; Schema: vwm_impex; Owner: postgres
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


ALTER TABLE vwm_impex.imp_t_landmarke OWNER TO postgres;

--
-- TOC entry 1024 (class 1259 OID 34588)
-- Name: imp_t_landmarke_id_imp_landmarke_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: postgres
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
-- Name: imp_t_landmarke_onr_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: postgres
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
-- Name: imp_t_punktinfo; Type: TABLE; Schema: vwm_impex; Owner: postgres
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


ALTER TABLE vwm_impex.imp_t_punktinfo OWNER TO postgres;

--
-- TOC entry 1022 (class 1259 OID 34570)
-- Name: imp_t_punktinfo_idpunktinfo_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: postgres
--

CREATE SEQUENCE vwm_impex.imp_t_punktinfo_idpunktinfo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE vwm_impex.imp_t_punktinfo_idpunktinfo_seq OWNER TO postgres;

--
-- TOC entry 7523 (class 0 OID 0)
-- Dependencies: 1022
-- Name: imp_t_punktinfo_idpunktinfo_seq; Type: SEQUENCE OWNED BY; Schema: vwm_impex; Owner: postgres
--

ALTER SEQUENCE vwm_impex.imp_t_punktinfo_idpunktinfo_seq OWNED BY vwm_impex.imp_t_punktinfo.idpunktinfo;


--
-- TOC entry 1030 (class 1259 OID 34612)
-- Name: imp_t_transekt; Type: TABLE; Schema: vwm_impex; Owner: postgres
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


ALTER TABLE vwm_impex.imp_t_transekt OWNER TO postgres;

--
-- TOC entry 1029 (class 1259 OID 34611)
-- Name: imp_t_transekt_id_transekt_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: postgres
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
-- Name: imp_t_transektinfo; Type: TABLE; Schema: vwm_impex; Owner: postgres
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


ALTER TABLE vwm_impex.imp_t_transektinfo OWNER TO postgres;

--
-- TOC entry 1027 (class 1259 OID 34597)
-- Name: imp_t_transektinfo_id_transektinfo_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: postgres
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
-- Name: imp_t_transektipf; Type: TABLE; Schema: vwm_impex; Owner: postgres
--

CREATE TABLE vwm_impex.imp_t_transektipf (
    id_tripfl bigint NOT NULL,
    los_id integer,
    transekti_id bigint,
    indikpfl_id integer,
    anteilsprozent integer,
    transektinfoid bigint NOT NULL
);


ALTER TABLE vwm_impex.imp_t_transektipf OWNER TO postgres;

--
-- TOC entry 1035 (class 1259 OID 34657)
-- Name: imp_t_transektipf_id_tripfl_seq; Type: SEQUENCE; Schema: vwm_impex; Owner: postgres
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
-- TOC entry 7079 (class 2606 OID 34552)
-- Name: g_los g_los_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: postgres
--

ALTER TABLE ONLY vwm_impex.g_los
    ADD CONSTRAINT g_los_pkey PRIMARY KEY (id_g_los);


--
-- TOC entry 7081 (class 2606 OID 34569)
-- Name: imp_t_baumplot imp_t_baumplot_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: postgres
--

ALTER TABLE ONLY vwm_impex.imp_t_baumplot
    ADD CONSTRAINT imp_t_baumplot_pkey PRIMARY KEY (id_t_bpl);


--
-- TOC entry 7089 (class 2606 OID 34628)
-- Name: imp_t_bestbes imp_t_bestbes_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: postgres
--

ALTER TABLE ONLY vwm_impex.imp_t_bestbes
    ADD CONSTRAINT imp_t_bestbes_pkey PRIMARY KEY (id_bestbes);


--
-- TOC entry 7091 (class 2606 OID 34656)
-- Name: imp_t_bestbess imp_t_bestbess_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: postgres
--

ALTER TABLE ONLY vwm_impex.imp_t_bestbess
    ADD CONSTRAINT imp_t_bestbess_pkey PRIMARY KEY (id_bestbess);


--
-- TOC entry 7083 (class 2606 OID 34596)
-- Name: imp_t_landmarke imp_t_landmarke_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: postgres
--

ALTER TABLE ONLY vwm_impex.imp_t_landmarke
    ADD CONSTRAINT imp_t_landmarke_pkey PRIMARY KEY (id_imp_landmarke);


--
-- TOC entry 7087 (class 2606 OID 34621)
-- Name: imp_t_transekt imp_t_transekt_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: postgres
--

ALTER TABLE ONLY vwm_impex.imp_t_transekt
    ADD CONSTRAINT imp_t_transekt_pkey PRIMARY KEY (id_transekt);


--
-- TOC entry 7085 (class 2606 OID 34610)
-- Name: imp_t_transektinfo imp_t_transektinfo_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: postgres
--

ALTER TABLE ONLY vwm_impex.imp_t_transektinfo
    ADD CONSTRAINT imp_t_transektinfo_pkey PRIMARY KEY (id_transektinfo);


--
-- TOC entry 7093 (class 2606 OID 34662)
-- Name: imp_t_transektipf imp_t_transektipf_pkey; Type: CONSTRAINT; Schema: vwm_impex; Owner: postgres
--

ALTER TABLE ONLY vwm_impex.imp_t_transektipf
    ADD CONSTRAINT imp_t_transektipf_pkey PRIMARY KEY (id_tripfl);


--
-- TOC entry 7077 (class 1259 OID 34553)
-- Name: g_los_ist_geom_idx; Type: INDEX; Schema: vwm_impex; Owner: postgres
--

CREATE INDEX g_los_ist_geom_idx ON vwm_impex.g_los USING gist (ist_geom);


--
-- TOC entry 7516 (class 0 OID 0)
-- Dependencies: 27
-- Name: SCHEMA vwm_impex; Type: ACL; Schema: -; Owner: postgres
--

