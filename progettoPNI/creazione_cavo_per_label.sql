--Setta il SEARCH_PATH sullo schema di lavoro!
--Creo ai nodi dei punti:
CREATE TEMP TABLE cavo_finale_node_labels AS (
--CREATE TABLE cavo_finale_node_labels AS (
WITH ix AS
( SELECT DISTINCT public.ST_Intersection(public.ST_SnapToGrid(a.geom, 0.01), public.ST_SnapToGrid(b.geom, 0.01)) geom 
  FROM cavo_finale a JOIN cavo_finale b ON public.ST_Intersects(a.geom,b.geom) ),
ix_simple_lines AS 
( SELECT
    (public.ST_Dump(public.ST_LineMerge(public.ST_CollectionExtract(geom, 2)))).geom geom
  FROM
    ix ),
ix_points AS
( SELECT
    (public.ST_Dump(public.ST_CollectionExtract(geom, 1))).geom geom
  FROM
    ix )
SELECT row_number() OVER() id, geom
FROM (
  SELECT public.ST_StartPoint(geom) geom FROM ix_simple_lines
  UNION
  SELECT public.ST_EndPoint(geom) FROM ix_simple_lines
  UNION
  SELECT geom FROM ix_points
) points_union);
CREATE INDEX ON cavo_finale_node_labels (id);
CREATE INDEX ON cavo_finale_node_labels USING gist (geom);


--Splitto ebw_cavo ovvero cavo_finale (cioe ebw_cavo ripulito) sui nodi precedenti:
CREATE TABLE cavo_labels AS (
SELECT max(id) AS id, public.ST_UNION(geom) AS geom, gid_cavo, sum(count) AS count FROM (
SELECT row_number() OVER() id, geom, array_to_string(array_agg(DISTINCT gid_cavo), ',') AS gid_cavo, count(*) FROM (
SELECT (public.ST_Dump(public.ST_Split(public.ST_Snap(a.geom, b.geom, 0.01), b.geom))).geom, array_to_string(array_agg(DISTINCT a.gidd), ',') AS gid_cavo
FROM cavo_finale a
JOIN cavo_finale_node_labels b 
ON public.ST_DWithin(b.geom, a.geom, 0.01)
--WHERE
--a.net_type != 'Contatori-PTA'
--da mail di Gatti del 18 gennaio 2018: escludo anche le scale di scala e le fibre da 12 --> beh al momento NON escludo nulla!
--a.net_type NOT IN ('Contatori-PTA', 'Contatori-contatore') OR a.fibre_coun != 12
GROUP BY public.ST_Dump(public.ST_Split(public.ST_Snap(a.geom, b.geom, 0.01), b.geom))
) AS foo GROUP BY geom
) AS foo2 GROUP BY gid_cavo);


--nel caso di cavo_finale mancano ovviamente un sacco di informazioni provenienti invece da ebw_cavo. Mi riporto solo quelle essenziali per le label:
ALTER TABLE cavo_finale ADD COLUMN potenziali character varying(3);
UPDATE cavo_finale SET potenziali = b.potenziali FROM ebw_cavo b WHERE b.gidd=cavo_finale.gidd;

--Creo infine le etichette sulla tabella:
--ATTENZIONE! in questo caso, riprendo le etichette 'potenziali' dal cavo originario, cioe' senza split_lines--ma lo split_lines probabilmente NON andra' fatto!
ALTER TABLE cavo_labels ADD COLUMN cavo_label character varying(1250);
UPDATE cavo_labels SET cavo_label = label FROM
(SELECT a.id,
--array_to_string(array_agg('1mc ' || b.fibre_coun || ' # ' || b.length_m::integer || 'm'), ', ') AS label
array_to_string(array_agg(potenziali||' FO'), ' # ') AS label
FROM cavo_labels a
LEFT JOIN
ebw_cavo b ON b.gidd::text = ANY(string_to_array(a.gid_cavo, ','))
GROUP BY id) AS foo WHERE cavo_labels.id = foo.id;


