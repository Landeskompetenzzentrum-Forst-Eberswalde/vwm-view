

ALTER TABLE vwm_impex.g_los ADD CONSTRAINT fim_id_unique UNIQUE (fim_id);
ALTER TABLE vwm_impex.g_los ADD CONSTRAINT los_id_unique UNIQUE (los_id);
-- Make vwm_impex.imp_t_baumplot.los_id integer
ALTER TABLE vwm_impex.imp_t_baumplot ALTER COLUMN los_id TYPE integer USING los_id::integer;
ALTER TABLE vwm_impex.imp_t_baumplot ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
-- Make vwm_impex.imp_t_transektinfo.los_id integer
ALTER TABLE vwm_impex.imp_t_transektinfo ALTER COLUMN los_id TYPE integer USING los_id::integer;
ALTER TABLE vwm_impex.imp_t_transektinfo ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
-- Make vwm_impex.imp_t_bestbess.los_id integer
ALTER TABLE vwm_impex.imp_t_bestbess ALTER COLUMN los_id TYPE integer USING los_id::integer;
ALTER TABLE vwm_impex.imp_t_bestbess ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
-- Make vwm_impex.imp_t_bestbes.los_id integer
ALTER TABLE vwm_impex.imp_t_bestbes ALTER COLUMN los_id TYPE integer USING los_id::integer;
ALTER TABLE vwm_impex.imp_t_bestbes ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
-- Make vwm_impex.imp_t_landmarke.los_id integer
ALTER TABLE vwm_impex.imp_t_landmarke ALTER COLUMN los_id TYPE integer USING los_id::integer;
ALTER TABLE vwm_impex.imp_t_landmarke ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
-- Make vwm_impex.imp_t_transekt.los_id integer
ALTER TABLE vwm_impex.imp_t_transekt ALTER COLUMN los_id TYPE integer USING los_id::integer;
ALTER TABLE vwm_impex.imp_t_transekt ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
-- Make vwm_impex.imp_t_transektipf.los_id integer
-- remove transektinfoid
ALTER TABLE vwm_impex.imp_t_transektipf DROP COLUMN transektinfoid;
ALTER TABLE vwm_impex.imp_t_transektipf ALTER COLUMN los_id TYPE integer USING los_id::integer;
ALTER TABLE vwm_impex.imp_t_transektipf ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;

-- Add default values
ALTER TABLE vwm_impex.g_los ALTER COLUMN imported SET DEFAULT NOW();

CREATE OR REPLACE FUNCTION api.import_geojson(geojson_data json)
RETURNS json AS
$$
DECLARE
    added_ids json;
    feature json;
    geom geometry;
    form json;
    baumplot json;
    t_bestockung json;
    verjuengungstransekt json;
    bodenvegetation json;
    landmarke json;
    new_los_id INTEGER;
    new_bestbes_id INTEGER;
    new_punktinfo_id INTEGER;
    i int = 0;
BEGIN
    -- Loop through each feature in the GeoJSON
    FOR feature IN SELECT * FROM json_array_elements(geojson_data->'features')
    LOOP
        perform FROM vwm_impex.g_los WHERE fim_id = feature->'properties'->>'id' or los_id = feature->'properties'->>'los_id';
        IF FOUND THEN
            DELETE FROM vwm_impex.g_los WHERE fim_id = feature->'properties'->>'id' or los_id = feature->'properties'->>'los_id';
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
            hase,
            maus,
            biber,
            krautanteil,
            azi
        )
        VALUES (
            new_los_id,
            (form->'verjuengungstransekt'->>'verjuengungstransektlaenge')::INT,
            (form->'transektinfo'->>'transektfrasshase')::BOOLEAN,
            (form->'transektinfo'->>'transektfrassmaus')::BOOLEAN,
            (form->'transektinfo'->>'transektfrassbieber')::BOOLEAN,
            (form->'weiserpflanzen'->>'krautanteil')::INT,
            (form->'baumplot1'->>'azimuttransektploteins')::INT
        );

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
            (form->'bestandesbeschreibung'->>'bestandheterogenitaetsgradid')::INT,
            (form->'bestandesbeschreibung'->>'bestandnschichtigid')::INT,
            (form->'bestandesbeschreibung'->>'bestandbetriebsartid')::smallint,
            (form->'bestandesbeschreibung'->>'bestandkronenschlussgradid')::smallint,
            (form->'bestandesbeschreibung'->>'bestandschutzmassnahmenid')::smallint,
            (form->'bestandesbeschreibung'->>'bestandbedeckungsgradunterstand')::smallint,
            (form->'bestandesbeschreibung'->>'bestandbedeckungsgradgraeser')::smallint
        )
        RETURNING id_bestbes INTO new_bestbes_id;

        -- Bestockung (imp_t_bestbess)
        i:= 0;
        FOR t_bestockung IN SELECT * FROM json_array_elements(form->'t_bestockung'->'t_bestockung')
        LOOP
            i:= i+ 1;
            INSERT INTO vwm_impex.imp_t_bestbess (
                los_id,
                schicht_id,
                bestbesid,
                ba_icode,
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


        
        -- Repeat the above INSERT statement for other tables as necessary, mapping GeoJSON properties to table columns.
    END LOOP;

    -- Return the IDs of the inserted rows
    RETURN added_ids;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION api.import_geojson(json) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION api.import_geojson(json) TO web_anon;


GRANT ALL ON SCHEMA vwm_impex TO web_anon;

GRANT SELECT, DELETE, INSERT ON vwm_impex.g_los TO web_anon;
GRANT SELECT, DELETE, INSERT ON vwm_impex.imp_t_baumplot TO web_anon;
GRANT SELECT, DELETE, INSERT ON vwm_impex.imp_t_landmarke TO web_anon;
GRANT SELECT, DELETE, INSERT ON vwm_impex.imp_t_transekt TO web_anon;
GRANT SELECT, DELETE, INSERT ON vwm_impex.imp_t_transektinfo TO web_anon;
GRANT SELECT, DELETE, INSERT ON vwm_impex.imp_t_bestbess TO web_anon;
GRANT SELECT, DELETE, INSERT ON vwm_impex.imp_t_bestbes TO web_anon;
GRANT SELECT, DELETE, INSERT ON vwm_impex.imp_t_transektipf TO web_anon;

