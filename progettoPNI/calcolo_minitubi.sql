--calcolo i minitubi ovvero il campo numero_tub del layer ebw_route secondo le specifiche riportate nella mail di Andrea Salvai del 12-14 febbraio 2019

--da codice ho impostato il search_path sullo Schema corretto

--PRIMO STEP: creo una tabella temporaanea di appoggio in cui associo route con cavo in base a metodi di sovrapposizione:
CREATE TEMP TABLE calcolo_minitubi AS
SELECT t1.gidd AS gidd_route, t2.gidd AS gidd_cavo, t2.tipologia_, t2.numero_fib, t1.tipo, 
CASE
WHEN t1.numero_cav ~ '^\d+(\.\d+)?$' THEN t1.numero_cav::integer
ELSE NULL
END AS numero_cav
FROM ebw_route t1, ebw_cavo t2
WHERE t1.geom=t2.geom
UNION
SELECT t1.gidd AS gidd_route, t2.gidd AS gidd_cavo, t2.tipologia_, t2.numero_fib, t1.tipo,
CASE
WHEN t1.numero_cav ~ '^\d+(\.\d+)?$' THEN t1.numero_cav::integer
ELSE NULL
END AS numero_cav
FROM ebw_route t1, ebw_cavo t2
WHERE t1.gidd NOT IN (SELECT t1.gidd FROM ebw_route t1, ebw_cavo t2 WHERE t1.geom=t2.geom)
AND ST_Intersects(t1.geom, t2.geom)
AND Upper(ST_GeometryType(ST_Intersection(t1.geom, t2.geom))) LIKE '%LINE%';

--SECONDO STEP: calcolo i minitubi:
UPDATE ebw_route SET tub_label = minitubo FROM (
SELECT gidd_route, CASE
--minitrincea
WHEN tipo ilike 'minitrincea' AND (tipologia_ ilike 'cavo autoportante adss' OR numero_fib=396) AND numero_cav<6 THEN '(1-50) (2x7-10/14)'
WHEN tipo ilike 'minitrincea' AND (tipologia_ ilike 'cavo autoportante adss' OR numero_fib=396) AND numero_cav>=6 THEN '(1-50) (3x7-10/14)'
WHEN tipo ilike 'minitrincea' AND numero_cav<12 THEN '(3x7-10/14)'
WHEN tipo ilike 'minitrincea' AND numero_cav>=12 THEN '(4x7-10/14)'
--trincea normale / trincea Sterrato
WHEN (tipo ilike 'trincea' OR tipo ilike 'trincea sterrato') AND (tipologia_ ilike 'cavo autoportante adss' OR numero_fib=396) AND numero_cav<6 THEN '(1-50) (2x7-10/14)'
WHEN (tipo ilike 'trincea' OR tipo ilike 'trincea sterrato') AND (tipologia_ ilike 'cavo autoportante adss' OR numero_fib=396) AND numero_cav>=6 AND numero_cav<13 THEN  '(1-50) (3x7-10/14)'
WHEN (tipo ilike 'trincea' OR tipo ilike 'trincea sterrato') AND (tipologia_ ilike 'cavo autoportante adss' OR numero_fib=396) AND numero_cav>=13 AND numero_cav<20 THEN  '(1-50) (4x7-10/14)'
WHEN (tipo ilike 'trincea' OR tipo ilike 'trincea sterrato') AND (tipologia_ ilike 'cavo autoportante adss' OR numero_fib=396) AND numero_cav>=20 THEN '(1-50) (5x7-10/14)'
WHEN (tipo ilike 'trincea' OR tipo ilike 'trincea sterrato') AND numero_cav<12 THEN '(3x7-10/14)'
WHEN (tipo ilike 'trincea' OR tipo ilike 'trincea sterrato') AND numero_cav>=12 AND numero_cav<19 THEN '(4x7-10/14)'
WHEN (tipo ilike 'trincea' OR tipo ilike 'trincea sterrato') AND numero_cav>=19 THEN '(5x7-10/14)'
--Microtunneling
WHEN tipo ilike 'microtunneling' AND numero_cav<5 THEN '(1x7-10/12)'
WHEN tipo ilike 'microtunneling' AND numero_cav>=5 AND numero_cav<9 THEN '(2x7-10/12)'
WHEN tipo ilike 'microtunneling' AND numero_cav>=9 THEN '(3x7-10/12)'
--"Rete Altri Interrata"
WHEN tipo ilike 'rete altri interrata' THEN '(' || numero_cav || '-10/12)'
END AS minitubo
FROM calcolo_minitubi) foo
WHERE foo.gidd_route = ebw_route.gidd;

