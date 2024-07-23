CREATE OR REPLACE FUNCTION vwm_impex.export_geojson()
RETURNS json AS
$$
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
            'geometry', ST_AsGeoJSON(g.aktuell_geom, 15)::json,
            'properties', json_build_object(
                'id', g.fim_id,
                'los_id', g.id_g_los,
                'losnr', g.losnr,
                'unterlosnr', g.unterlosnr,
                'jahr', g.jahr,
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
                                'spaufsuchenichtwaldursacheid', g.spaufsuchenichtwaldursacheid
                        ),
                        'coordinates', json_build_object(
                            'spaufsucheverschobenursacheid', g.spaufsucheverschobenursacheid,
                            's_perma', g.s_perma,
                            'istgeom_x', g.istgeom_x,
                            'istgeom_y', g.istgeom_y,
                            'istgeom_elev', g.istgeom_elev,
                            'istgeom_sat', g.istgeom_sat,
                            'istgeom_hdop', g.istgeom_hdop,
                            'istgeom_vdop', g.istgeom_vdop
                        ),
                        'baumplot1', json_build_object(
                            'baumplot1',(
                                SELECT COALESCE(json_agg(
                                    json_build_object(
                                        'icode_ba', bp.baid,
                                        'azimut', bp.azi,
                                        'distanz', bp.dist,
                                        'bhd', bp.bhd,
                                        'messhoehebhd', bp.h_bhd,
                                        'schaele', bp.schal,
                                        'fege', bp.schal
                                    )
                                ), '[]'::json)
                                FROM vwm_impex.imp_t_baumplot bp
                                WHERE bp.glos_id = g.id_g_los AND bplotnr = 1
                            ),
                            'transectLocation', 0,
                            'azimuttransektploteins', (
                                SELECT ti.azi
                                FROM vwm_impex.imp_t_transektinfo ti
                                WHERE ti.glos_id = g.id_g_los
                            )
                        ),
                        'landmarken1', json_build_object(
                            'landmarken1',(
                                SELECT COALESCE(json_agg(
                                    json_build_object(
                                        'landmarken', lm1.typ,
                                        'azimut', lm1.azi,
                                        'distanz', lm1.dist
                                    )
                                ), '[]'::json)
                                FROM vwm_impex.imp_t_landmarke lm1
                                WHERE lm1.glos_id = g.id_g_los AND lplotnr = 1
                            )
                        ),
                        'baumplot2', json_build_object(
                            'baumplot2',(
                                SELECT COALESCE(json_agg(
                                    json_build_object(
                                        'icode_ba', bp2.baid,
                                        'azimut', bp2.azi,
                                        'distanz', bp2.dist,
                                        'bhd', bp2.bhd,
                                        'messhoehebhd', bp2.h_bhd,
                                        'schaele', bp2.schal,
                                        'fege', bp2.schal
                                    )
                                ), '[]'::json)
                                FROM vwm_impex.imp_t_baumplot bp2
                                WHERE bp2.glos_id = g.id_g_los AND bplotnr = 2
                               
                            )
                        ),
                        'landmarken2', json_build_object(
                            'landmarken2',(
                                SELECT COALESCE(json_agg(
                                    json_build_object(
                                        'landmarken', lm2.typ,
                                        'azimut', lm2.azi,
                                        'distanz', lm2.dist
                                    )
                                ), '[]'::json)
                                FROM vwm_impex.imp_t_landmarke lm2
                                WHERE lm2.glos_id = g.id_g_los AND lplotnr = 2
                            )
                        ),
                        'verjuengungstransekt', json_build_object(
                            'verjuengungstransekten',(
                                SELECT COALESCE(json_agg(
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
                                ), '[]'::json)
                                FROM vwm_impex.imp_t_transekt vt
                                WHERE vt.glos_id = g.id_g_los
                            ),
                            'transectLength', 0,
                            'verjuengungstransektlaenge', (
                                SELECT ti.laenge
                                FROM vwm_impex.imp_t_transektinfo ti
                                WHERE ti.glos_id = g.id_g_los
                            )
                        ),
                        'transekt', (
                            SELECT COALESCE(
                                json_build_object(
                                    'protectiveMeasure', 0,
                                    'schutzmassnahmeid', ti2.sma_id,
                                    'transektstoerungursache', ti2.transektstoerungursache
                                
                            ), '[]'::json)
                            FROM vwm_impex.imp_t_transektinfo ti2
                            WHERE ti2.glos_id = g.id_g_los
                        ),
                        'transektinfo', (
                            SELECT COALESCE(
                                json_build_object(
                                    'transektfrasshase', ti.hase,
                                    'transektfrassmaus', ti.maus,
                                    'transektfrassbieber', ti.biber
                            ), '[]'::json)
                            FROM vwm_impex.imp_t_transektinfo ti
                            WHERE ti.glos_id = g.id_g_los
                        ),
                        'bestandsbeschreibung', (
                            SELECT COALESCE(
                                json_build_object(
                                    'bestandheterogenitaetsgradid', bestbes.heterogenigrad,
                                    'bestandnschichtigid', bestbes.nschicht_id,
                                    'bestandbetriebsartid', bestbes.bea_id,
                                    'bestandkronenschlussgradid', bestbes.ksg_id,
                                    'bestandschutzmassnahmenid', bestbes.sma_id,
                                    'bestandbedeckungsgradunterstand', bestbes.bed_us,
                                    'bestandbedeckungsgradgraeser', bestbes.bed_bodenveg,
                                    'bestandbiotopid', g.biotopid
                                
                            ), '{}'::json)
                            FROM vwm_impex.imp_t_bestbes bestbes
                            WHERE bestbes.glos_id = g.id_g_los
                            
                        ),
                        't_bestockung', json_build_object(
                            't_bestockung',(
                                SELECT COALESCE(json_agg(
                                    json_build_object(
                                        'schicht_id', bess.schicht_id,
                                        'icode_ba', bess.ba_icode,
                                        'nas_id', bess.nas_id,
                                        'ba_anteil', bess.ba_anteil,
                                        'entsart_id', bess.entsart_id,
                                        'vert_id', bess.vert_id
                                    )
                                ), '[]'::json)
                                FROM vwm_impex.imp_t_bestbess bess
                                WHERE bess.glos_id = g.id_g_los
                               
                            )
                        ),
                        't_bodenvegetation', json_build_object(
                            't_bodenvegetation',(
                                SELECT COALESCE(json_agg(
                                    json_build_object(
                                        'verteilung', veggr.verteilung_id,
                                        'bodenveggr', veggr.bodenveggr_id,
                                        'anteil', veggr.prozanteil
                                    )
                                ), '[]'::json)
                                FROM vwm_impex.imp_t_besbodenveggr veggr
                                WHERE veggr.glos_id = g.id_g_los
                               
                            )
                        ),
                        'stoerung', (SELECT "export_stoerung"(g.id_g_los)),
                        'weiserpflanzen', json_build_object(
                            'krautanteil', COALESCE((SELECT krautanteil FROM vwm_impex.imp_t_transektinfo WHERE vwm_impex.imp_t_transektinfo.glos_id = g.id_g_los LIMIT 1), 0),
                            'moos', json_build_object(
                                'weiserpflanzenmoos', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE vwm_impex.imp_t_transektipf.glos_id = g.id_g_los AND indikpfl_id = 1 LIMIT 1), 0)
                            ),
                            'kraut', json_build_object(
                                'weiserpflanzenbrennessel', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 71 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzengoldnessel', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 91 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenheidekraut', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 32 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenspringkraut', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 101 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenmaigloeckchen', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 9 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenweidenroesschen', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 102 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenwaldmeister', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 81 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenwaldsauerklee', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 10 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenwegerich', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 13 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0)
                            ),
                            'grass', json_build_object(
                                'weiserpflanzendrahtschmiele', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 113 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenflaterbinse', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 131 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenhainrispengras', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 114 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenperlgras', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 115 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenpfeifengras', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 111 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzensandrohr', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 112 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenwaldzwenke', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 116 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenwinkelsegge', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 121 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0)
                            ),
                            'farne', json_build_object(
                                'weiserpflanzenadlerfarn', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 51 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0)
                            ),
                            'doldengewaechse', json_build_object(
                                'weiserpflanzengiersch', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 11 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0)
                            ),
                            'beerenstraucher', json_build_object(
                                'weiserpflanzenheidelbeere', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 21 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenpreiselbeere', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 22 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0)
                            ),
                            'grosstraucher', json_build_object(
                                'weiserpflanzenhimbeere', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 61 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0),
                                'weiserpflanzenbrombeere', COALESCE((SELECT anteilsprozent FROM vwm_impex.imp_t_transektipf WHERE indikpfl_id = 62 AND vwm_impex.imp_t_transektipf.glos_id = g.id_g_los LIMIT 1), 0)
                            )
                        )
                    )
                )
            
                )
            )
            FROM vwm_impex.g_los g
            -- selete where role_access array includes current user role
            WHERE g.role_access @> ARRAY['web_anon']::regrole[] AND g.workflow = 6
        )
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vwm_impex.export_stoerung(id_g_los INT)
RETURNS json AS
$$
DECLARE
BEGIN
    RETURN json_build_object(
        'thinning', (SELECT EXISTS(SELECT 1 FROM vwm_impex.imp_b_strg WHERE vwm_impex.imp_b_strg.glos_id = id_g_los AND s_strgid = 1 LIMIT 1)),
        'sanitaryStrokes', (SELECT EXISTS(SELECT 1 FROM vwm_impex.imp_b_strg WHERE vwm_impex.imp_b_strg.glos_id = id_g_los AND s_strgid = 2 LIMIT 1)),
        'wildfire', (SELECT EXISTS(SELECT 1 FROM vwm_impex.imp_b_strg WHERE vwm_impex.imp_b_strg.glos_id = id_g_los AND s_strgid = 3 LIMIT 1)),
        'storm', (SELECT EXISTS(SELECT 1 FROM vwm_impex.imp_b_strg WHERE vwm_impex.imp_b_strg.glos_id = id_g_los AND s_strgid = 4 LIMIT 1)),
        'soilCultivation', (SELECT EXISTS(SELECT 1 FROM vwm_impex.imp_b_strg WHERE vwm_impex.imp_b_strg.glos_id = id_g_los AND s_strgid = 5 LIMIT 1)),
        'note', (SELECT stoerung FROM vwm_impex.imp_b_strgsonstig WHERE vwm_impex.imp_b_strgsonstig.glos_id = id_g_los LIMIT 1)
    );
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION vwm_impex.import_geojson(json) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION vwm_impex.import_geojson(json) TO web_anon;