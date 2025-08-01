
DROP EXTENSION IF EXISTS pg_lip_bloom;
CREATE EXTENSION pg_lip_bloom;

SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(6);
SELECT sum(pg_lip_bloom_add(0, ci.movie_id)) FROM cast_info AS ci WHERE ci.note = '(voice)';
SELECT sum(pg_lip_bloom_add(1, cn.id)) FROM company_name AS cn WHERE cn.country_code ='[us]';
SELECT sum(pg_lip_bloom_add(2, mc.movie_id)) FROM movie_companies AS mc WHERE mc.note LIKE '%(200%)%' AND (mc.note LIKE '%(USA)%' OR mc.note LIKE '%(worldwide)%');
SELECT sum(pg_lip_bloom_add(3, n.id)) FROM name AS n WHERE n.gender ='f' AND n.name LIKE '%Angel%';
SELECT sum(pg_lip_bloom_add(4, rt.id)) FROM role_type AS rt WHERE rt.role ='actress';
SELECT sum(pg_lip_bloom_add(5, t.id)) FROM title AS t WHERE t.production_year between 2007 and 2010;

/*+
NestLoop(n an ci rt mc chn cn t)
NestLoop(n an ci rt mc chn cn)
NestLoop(n an ci rt mc chn)
NestLoop(n an ci rt mc)
HashJoin(n an ci rt)
NestLoop(n an ci)
NestLoop(n an)
SeqScan(n)
IndexScan(an)
IndexScan(ci)
SeqScan(rt)
IndexScan(mc)
IndexScan(chn)
IndexScan(cn)
IndexScan(t)
Leading((((((((n an) ci) rt) mc) chn) cn) t))*/
SELECT MIN(an.name) AS alternative_name,
       MIN(chn.name) AS voiced_character,
       MIN(n.name) AS voicing_actress,
       MIN(t.title) AS american_movie
 FROM 
(
	SELECT * FROM aka_name AS an 
	 WHERE pg_lip_bloom_probe(3, an.person_id)
) AS an ,
char_name AS chn ,
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(2, ci.movie_id)
	AND pg_lip_bloom_probe(3, ci.person_id)
	AND pg_lip_bloom_probe(4, ci.role_id)
	AND pg_lip_bloom_probe(5, ci.movie_id)
) AS ci ,
company_name AS cn ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.movie_id)
	AND pg_lip_bloom_probe(1, mc.company_id)
	AND pg_lip_bloom_probe(5, mc.movie_id)
) AS mc ,
name AS n ,
role_type AS rt ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(0, t.id)
	AND pg_lip_bloom_probe(2, t.id)
) AS t
WHERE
 ci.note = '(voice)'
  AND cn.country_code ='[us]'
  AND mc.note LIKE '%(200%)%'
  AND (mc.note LIKE '%(USA)%'
       OR mc.note LIKE '%(worldwide)%')
  AND n.gender ='f'
  AND n.name LIKE '%Angel%'
  AND rt.role ='actress'
  AND t.production_year BETWEEN 2007 AND 2010
  AND ci.movie_id = t.id
  AND t.id = mc.movie_id
  AND ci.movie_id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.role_id = rt.id
  AND n.id = ci.person_id
  AND chn.id = ci.person_role_id
  AND an.person_id = n.id
  AND an.person_id = ci.person_id;

