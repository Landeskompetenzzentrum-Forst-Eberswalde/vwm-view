CREATE OR REPLACE FUNCTION api.export_geojson(los_ids int[])
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
            WHERE g.id_g_los = ANY(los_ids)
        )
    );
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION api.import_geojson(json) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION api.import_geojson(json) TO web_anon;