

--ALTER TABLE vwm_impex.g_los ADD CONSTRAINT fim_id_unique UNIQUE (fim_id);
--ALTER TABLE vwm_impex.g_los ADD CONSTRAINT los_id_unique UNIQUE (id_g_los);
--
--
--
---- Make vwm_impex.imp_t_baumplot.los_id integer
--ALTER TABLE vwm_impex.imp_t_baumplot ALTER COLUMN los_id TYPE integer USING id_g_los::integer;
--ALTER TABLE vwm_impex.imp_t_baumplot ADD CONSTRAINT fk_g_los FOREIGN KEY (losid_g_los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
---- Make vwm_impex.imp_t_transektinfo.los_id integer
--ALTER TABLE vwm_impex.imp_t_transektinfo ALTER COLUMN los_id TYPE integer USING los_id::integer;
--ALTER TABLE vwm_impex.imp_t_transektinfo ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
---- Make vwm_impex.imp_t_bestbess.los_id integer
--ALTER TABLE vwm_impex.imp_t_bestbess ALTER COLUMN los_id TYPE integer USING los_id::integer;
--ALTER TABLE vwm_impex.imp_t_bestbess ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
---- Make vwm_impex.imp_t_bestbes.los_id integer
--ALTER TABLE vwm_impex.imp_t_bestbes ALTER COLUMN los_id TYPE integer USING los_id::integer;
--ALTER TABLE vwm_impex.imp_t_bestbes ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
---- Make vwm_impex.imp_t_landmarke.los_id integer
--ALTER TABLE vwm_impex.imp_t_landmarke ALTER COLUMN los_id TYPE integer USING los_id::integer;
--ALTER TABLE vwm_impex.imp_t_landmarke ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
---- Make vwm_impex.imp_t_transekt.los_id integer
--ALTER TABLE vwm_impex.imp_t_transekt ALTER COLUMN los_id TYPE integer USING los_id::integer;
--ALTER TABLE vwm_impex.imp_t_transekt ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
---- Make vwm_impex.imp_t_transektipf.los_id integer
---- remove transektinfoid
------ALTER TABLE vwm_impex.imp_t_transektipf DROP COLUMN transektinfoid;
--ALTER TABLE vwm_impex.imp_t_transektipf ALTER COLUMN los_id TYPE integer USING los_id::integer;
--ALTER TABLE vwm_impex.imp_t_transektipf ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
--
---- Make vwm_impex.imp_t_besbodenveggr.los_id integer
--ALTER TABLE vwm_impex.imp_t_besbodenveggr ALTER COLUMN los_id TYPE integer USING los_id::integer;
--ALTER TABLE vwm_impex.imp_t_besbodenveggr ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
--
---- Make vwm_impex.imp_t_bestbess.bestbesid integer
--ALTER TABLE vwm_impex.imp_t_bestbess ALTER COLUMN bestbesid TYPE integer USING bestbesid::integer;
--ALTER TABLE vwm_impex.imp_t_bestbess ADD CONSTRAINT fk_imp_t_bestbes FOREIGN KEY (bestbesid) REFERENCES vwm_impex.imp_t_bestbes(id_bestbes) ON DELETE CASCADE;
--
---- Make vwm_impex.imp_b_strg.los_id integer
--ALTER TABLE vwm_impex.imp_b_strg ALTER COLUMN los_id TYPE integer USING los_id::integer;
--ALTER TABLE vwm_impex.imp_b_strg ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
--ALTER TABLE vwm_impex.imp_b_strg ALTER COLUMN bestbesid TYPE integer USING bestbesid::integer;
--ALTER TABLE vwm_impex.imp_b_strg ADD CONSTRAINT fk_imp_t_bestbes FOREIGN KEY (bestbesid) REFERENCES vwm_impex.imp_t_bestbes(id_bestbes) ON DELETE CASCADE;
--
---- Make vwm_impex.imp_b_strgsonstig.los_id integer
--ALTER TABLE vwm_impex.imp_b_strgsonstig ALTER COLUMN los_id TYPE integer USING los_id::integer;
--ALTER TABLE vwm_impex.imp_b_strgsonstig ADD CONSTRAINT fk_g_los FOREIGN KEY (los_id) REFERENCES vwm_impex.g_los(id_g_los) ON DELETE CASCADE;
--
---- Add default values
--ALTER TABLE vwm_impex.g_los ALTER COLUMN imported SET DEFAULT NOW();

CREATE OR REPLACE FUNCTION vwm_impex.import_geojson(geojson_data json)
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
    stoerung json;
    new_los_id INTEGER;
    new_bestbes_id INTEGER;
    new_punktinfo_id INTEGER;
    new_transektinfo_id INTEGER;
    stoerungen_map json;
    i int = 0;
    fim_stoerung text;

    workflow int;
    current_user_role text;
    current_user_role_array text[];
BEGIN
    -- Loop through each feature in the GeoJSON
    
    FOR feature IN SELECT * FROM json_array_elements(geojson_data->'features')
    LOOP

        --- only allow vwm_ats and vwm_kts to import
        --- EXIT WHEN current_user != 'vwm_ats' AND current_user != 'vwm_kts';

        --- PRINT TO CONSOLE CURRENT USER

        --- Skip if workflow is not 5

        current_user_role := current_user::text;
        current_user_role_array := ARRAY[current_user_role];
        
        workflow := (feature->'properties'->>'workflow')::INTEGER;

        
        --- IF user role is vwm_ats, set workflow to 6
        IF ( current_user::text = 'web_anon' OR current_user::text = 'vwm_ats') AND workflow = 5 THEN
            workflow := 6;
        ELSIF ( current_user::text = 'web_anon' OR current_user::text = 'vwm_kts') AND workflow = 7 THEN
            workflow := 8;
        ELSE
            CONTINUE;
        END IF;



        CREATE TEMP TABLE temp_g_los AS
            SELECT los_id, losnr, h3index_text, h3i_hid, jahr
            FROM vwm_impex.g_los WHERE fim_id = (feature->'properties'->>'id')::text or id_g_los = (feature->'properties'->>'los_id')::INTEGER;
        
        perform FROM vwm_impex.g_los WHERE fim_id = (feature->'properties'->>'id')::text or id_g_los = (feature->'properties'->>'los_id')::INTEGER;
        IF FOUND THEN
            -- output los_id from temp table as json
            DELETE FROM vwm_impex.g_los WHERE fim_id = (feature->'properties'->>'id')::text or id_g_los = (feature->'properties'->>'los_id')::INTEGER;
        END IF;

        -- Convert GeoJSON geometry to PostGIS geometry
        geom := ST_SetSRID(ST_GeomFromGeoJSON(feature->>'geometry'), 4326);

        

        -- Example: Inserting data into a table. Adjust the table name and columns as necessary.
        INSERT INTO vwm_impex.g_los (
            id_g_los,
            fim_id,
            fim_status,
            fim_type,
            created,
            modified,
            wf_wechsel_datum,
            imported,
            workflow,
            losnr,
            spaufsucheaufnahmetruppkuerzel,
            spaufsucheaufnahmetruppgnss,
            spaufsuchenichtbegehbarursacheid,
            spaufsuchenichtwaldursacheid,
            spaufsucheverschobenursacheid,
            s_perma,
            istgeom_x,
            istgeom_y,
            istgeom_elev,
            istgeom_sat,
            istgeom_hdop,
            istgeom_vdop,
            aktuell_geom,
            biotopid,
            role_access,

            los_id,
            jahr,
            h3index_text,
            h3i_hid
        )
        OVERRIDING SYSTEM VALUE
        VALUES (
            COALESCE(NULLIF((feature->'properties'->>'los_id')::text, 'null')::int, nextval('g_los_id_g_los_seq')),
            (feature->'properties'->>'id')::text,
            CASE
                WHEN feature->'properties'->>'status' = 'true' THEN TRUE
                WHEN feature->'properties'->>'status' = 'false' THEN FALSE
                ELSE NULL -- or default to TRUE/FALSE depending on your requirements
            END,
            feature->'properties'->>'type',
            TO_TIMESTAMP(feature->'properties'->>'created', 'YYYY-MM-DD"T"HH24:MI:SS.US'),
            TO_TIMESTAMP(feature->'properties'->>'modified', 'YYYY-MM-DD"T"HH24:MI:SS.US'),
            DATE(feature->'properties'->>'modified'),
            NOW()::TIMESTAMP,
            workflow,
            CASE
                WHEN (feature->'properties'->>'losnr')::text = 'null' THEN (SELECT losnr FROM temp_g_los)
                ELSE feature->'properties'->>'losnr'
            END,
            feature->'properties'->'form'->'general'->>'spaufsucheaufnahmetruppkuerzel',
            feature->'properties'->'form'->'general'->>'spaufsucheaufnahmetruppgnss',
            (feature->'properties'->'form'->'general'->>'spaufsuchenichtbegehbarursacheid')::INTEGER,
            (feature->'properties'->'form'->'general'->>'spaufsuchenichtwaldursacheid')::INTEGER,
            (feature->'properties'->'form'->'coordinates'->>'spaufsucheverschobenursacheid')::INTEGER,
            (feature->'properties'->'form'->'coordinates'->>'s_perma')::INTEGER,
            (feature->'properties'->'form'->'coordinates'->>'istgeom_x')::float,
            (feature->'properties'->'form'->'coordinates'->>'istgeom_y')::float,
            (feature->'properties'->'form'->'coordinates'->>'istgeom_elev')::float,
            (feature->'properties'->'form'->'coordinates'->>'istgeom_sat')::INTEGER,
            (feature->'properties'->'form'->'coordinates'->>'istgeom_hdop')::float,
            (feature->'properties'->'form'->'coordinates'->>'istgeom_vdop')::float,
            geom,
            (feature->'properties'->'form'->'bestandsbeschreibung'->>'bestandbiotopid')::INTEGER,
            current_user_role_array::regrole[],

            (SELECT los_id FROM temp_g_los),
            (SELECT jahr FROM temp_g_los),
            (SELECT h3index_text FROM temp_g_los),
            (SELECT h3i_hid FROM temp_g_los)

        )
        ON CONFLICT (id_g_los)
        DO UPDATE SET
            fim_id = (feature->'properties'->>'id')::text,
            fim_status = EXCLUDED.fim_status,
            fim_type = EXCLUDED.fim_type,
            created = EXCLUDED.created,
            modified = EXCLUDED.modified,
            wf_wechsel_datum = EXCLUDED.wf_wechsel_datum,
            imported = EXCLUDED.imported,
            workflow = EXCLUDED.workflow,
            losnr = EXCLUDED.losnr,
            spaufsucheaufnahmetruppkuerzel = EXCLUDED.spaufsucheaufnahmetruppkuerzel,
            spaufsucheaufnahmetruppgnss = EXCLUDED.spaufsucheaufnahmetruppgnss,
            spaufsuchenichtbegehbarursacheid = EXCLUDED.spaufsuchenichtbegehbarursacheid,
            spaufsuchenichtwaldursacheid = EXCLUDED.spaufsuchenichtwaldursacheid,
            spaufsucheverschobenursacheid = EXCLUDED.spaufsucheverschobenursacheid,
            s_perma = EXCLUDED.s_perma,
            istgeom_x = EXCLUDED.istgeom_x,
            istgeom_y = EXCLUDED.istgeom_y,
            istgeom_elev = EXCLUDED.istgeom_elev,
            istgeom_sat = EXCLUDED.istgeom_sat,
            istgeom_hdop = EXCLUDED.istgeom_hdop,
            istgeom_vdop = EXCLUDED.istgeom_vdop,
            aktuell_geom = EXCLUDED.aktuell_geom,
            biotopid = EXCLUDED.biotopid
        WHERE vwm_impex.g_los.id_g_los = (feature->'properties'->>'los_id')::INTEGER
        RETURNING id_g_los INTO new_los_id;

       DROP  TABLE temp_g_los;

        -- Save the ID of the inserted row
        added_ids := json_build_object('id', new_los_id);

        form = feature->'properties'->'form';

        -- BAUMPLOT1
        i:= 0;
        FOR baumplot IN SELECT * FROM json_array_elements(form->'baumplot1'->'baumplot1')
        LOOP
            i:= i+ 1;
            INSERT INTO vwm_impex.imp_t_baumplot (
                glos_id,
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
                glos_id,
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
                glos_id,
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
            glos_id,
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
            glos_id,
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
                    glos_id,
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
                glos_id,
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
                glos_id,
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
                glos_id,
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

        -- WEISERPFLANZEN (imp_t_transektipf)
        PERFORM "import_imp_t_transektipf"(form->'weiserpflanzen', new_los_id, new_transektinfo_id);
        --i:= 0;
        --FOR bodenvegetation IN SELECT * FROM json_array_elements(form->'t_bodenvegetation'->'t_bodenvegetation')
        --LOOP
        --    i:= i+ 1;
        --    INSERT INTO vwm_impex.imp_t_transektipf (
        --        glos_id,
        --        transekti_id, -- ?
        --        indikpfl_id,
        --        anteilsprozent
        --    )
        --    VALUES (
        --        new_los_id,
        --        new_transektinfo_id, --(bodenvegetation->>'verteilung')::INT, -- ?
        --        (bodenvegetation->>'bodenveggr')::INT,
        --        (bodenvegetation->>'anteil')::INT
        --    );
        --END LOOP;

        -- Bodenvegetation (imp_t_besbodenveggr)
        i:= 0;
        FOR bodenvegetation IN SELECT * FROM json_array_elements(form->'t_bodenvegetation'->'t_bodenvegetation')
        LOOP
            i:= i+ 1;
            INSERT INTO vwm_impex.imp_t_besbodenveggr (
                glos_id,
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
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vwm_impex.import_imp_t_transektipf(geojson_data json, new_los_id INTEGER, new_transektinfo_id INTEGER)
RETURNS void AS
$$
DECLARE
BEGIN

    INSERT INTO vwm_impex.imp_t_transektipf (
        glos_id,
        transekti_id,
        indikpfl_id,
        anteilsprozent
    )
    VALUES
    (
        new_los_id,
        new_transektinfo_id, 
        1,
        (geojson_data->'moos'->>'weiserpflanzenmoos')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        71,
        (geojson_data->'kraut'->>'weiserpflanzenbrennessel')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        91,
        (geojson_data->'kraut'->>'weiserpflanzengoldnessel')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        32,
        (geojson_data->'kraut'->>'weiserpflanzenheidekraut')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        101,
        (geojson_data->'kraut'->>'weiserpflanzenspringkraut')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        9,
        (geojson_data->'kraut'->>'weiserpflanzenmaigloeckchen')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        102,
        (geojson_data->'kraut'->>'weiserpflanzenweidenroesschen')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        81,
        (geojson_data->'kraut'->>'weiserpflanzenwaldmeister')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        10,
        (geojson_data->'kraut'->>'weiserpflanzenwaldsauerklee')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        13,
        (geojson_data->'kraut'->>'weiserpflanzenwegerich')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        113,
        (geojson_data->'grass'->>'weiserpflanzendrahtschmiele')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        131,
        (geojson_data->'grass'->>'weiserpflanzenflaterbinse')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        114,
        (geojson_data->'grass'->>'weiserpflanzenhainrispengras')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        115,
        (geojson_data->'grass'->>'weiserpflanzenperlgras')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        111,
        (geojson_data->'grass'->>'weiserpflanzenpfeifengras')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        112,
        (geojson_data->'grass'->>'weiserpflanzensandrohr')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        116,
        (geojson_data->'grass'->>'weiserpflanzenwaldzwenke')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        121,
        (geojson_data->'grass'->>'weiserpflanzenwinkelsegge')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        51,
        (geojson_data->'farne'->>'weiserpflanzenadlerfarn')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        11,
        (geojson_data->'doldengewaechse'->>'weiserpflanzengiersch')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        21,
        (geojson_data->'beerenstraucher'->>'weiserpflanzenheidelbeere')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        22,
        (geojson_data->'beerenstraucher'->>'weiserpflanzenpreiselbeere')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        61,
        (geojson_data->'grosstraucher'->>'weiserpflanzenhimbeere')::INT
    ),
    (
        new_los_id,
        new_transektinfo_id, 
        62,
        (geojson_data->'grosstraucher'->>'weiserpflanzenbrombeere')::INT
    )
    ;

END;
$$ LANGUAGE plpgsql;


ALTER FUNCTION vwm_impex.import_geojson(json) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION vwm_impex.import_geojson(json) TO web_anon;


GRANT ALL ON SCHEMA vwm_impex TO web_anon;

GRANT SELECT, UPDATE, DELETE, INSERT ON vwm_impex.g_los TO web_anon;
GRANT SELECT, UPDATE, DELETE, INSERT ON vwm_impex.imp_t_baumplot TO web_anon;
GRANT SELECT, UPDATE, DELETE, INSERT ON vwm_impex.imp_t_landmarke TO web_anon;
GRANT SELECT, UPDATE, DELETE, INSERT ON vwm_impex.imp_t_transekt TO web_anon;
GRANT SELECT, UPDATE, DELETE, INSERT ON vwm_impex.imp_t_transektinfo TO web_anon;
GRANT SELECT, UPDATE, DELETE, INSERT ON vwm_impex.imp_t_bestbess TO web_anon;
GRANT SELECT, UPDATE, DELETE, INSERT ON vwm_impex.imp_t_bestbes TO web_anon;
GRANT SELECT, UPDATE, DELETE, INSERT ON vwm_impex.imp_t_transektipf TO web_anon;
GRANT SELECT, UPDATE, DELETE, INSERT ON vwm_impex.imp_t_besbodenveggr TO web_anon;
GRANT SELECT, UPDATE, DELETE, INSERT ON vwm_impex.imp_b_strg TO web_anon;
GRANT SELECT, UPDATE, DELETE, INSERT ON vwm_impex.imp_b_strgsonstig TO web_anon;