
DROP EXTENSION IF EXISTS pg_lip_bloom;
CREATE EXTENSION pg_lip_bloom;

SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(8);
SELECT sum(pg_lip_bloom_add(0, ci.movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)');
SELECT sum(pg_lip_bloom_add(1, cn.id)) FROM company_name AS cn WHERE cn.country_code ='[us]';
SELECT sum(pg_lip_bloom_add(2, it.id)) FROM info_type AS it WHERE it.info = 'release dates';
SELECT sum(pg_lip_bloom_add(3, k.id)) FROM keyword AS k WHERE k.keyword IN ('hero', 'martial-arts', 'hand-to-hand-combat');
SELECT sum(pg_lip_bloom_add(4, mi.movie_id)) FROM movie_info AS mi WHERE mi.info IS NOT NULL AND (mi.info LIKE 'Japan:%201%' OR mi.info LIKE 'USA:%201%');
SELECT sum(pg_lip_bloom_add(5, n.id)) FROM name AS n WHERE n.gender ='f' AND n.name LIKE '%An%';
SELECT sum(pg_lip_bloom_add(6, rt.id)) FROM role_type AS rt WHERE rt.role ='actress';
SELECT sum(pg_lip_bloom_add(7, t.id)) FROM title AS t WHERE t.production_year > 2010;

/*+
NestLoop(it k mk t mi ci an chn mc cn n rt)
NestLoop(it k mk t mi ci an chn mc cn n)
NestLoop(it k mk t mi ci an chn mc cn)
NestLoop(it k mk t mi ci an chn mc)
NestLoop(it k mk t mi ci an chn)
NestLoop(it k mk t mi ci an)
NestLoop(it k mk t mi ci)
NestLoop(it k mk t mi)
NestLoop(k mk t mi)
NestLoop(k mk t)
NestLoop(k mk)
SeqScan(it)
SeqScan(k)
IndexScan(mk)
IndexScan(t)
IndexScan(mi)
IndexScan(ci)
IndexScan(an)
IndexScan(chn)
IndexScan(mc)
IndexScan(cn)
IndexScan(n)
SeqScan(rt)
Leading(((((((((it (((k mk) t) mi)) ci) an) chn) mc) cn) n) rt))*/
SELECT MIN(chn.name) AS voiced_char_name,
       MIN(n.name) AS voicing_actress_name,
       MIN(t.title) AS voiced_action_movie_jap_eng
 FROM 
(
	SELECT * FROM aka_name AS an 
	 WHERE pg_lip_bloom_probe(5, an.person_id)
) AS an ,
char_name AS chn ,
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(4, ci.movie_id)
	AND pg_lip_bloom_probe(5, ci.person_id)
	AND pg_lip_bloom_probe(6, ci.role_id)
	AND pg_lip_bloom_probe(7, ci.movie_id)
) AS ci ,
company_name AS cn ,
info_type AS it ,
keyword AS k ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.movie_id)
	AND pg_lip_bloom_probe(1, mc.company_id)
	AND pg_lip_bloom_probe(4, mc.movie_id)
	AND pg_lip_bloom_probe(7, mc.movie_id)
) AS mc ,
(
	SELECT * FROM movie_info AS mi 
	 WHERE pg_lip_bloom_probe(0, mi.movie_id)
	AND pg_lip_bloom_probe(2, mi.info_type_id)
	AND pg_lip_bloom_probe(7, mi.movie_id)
) AS mi ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(0, mk.movie_id)
	AND pg_lip_bloom_probe(3, mk.keyword_id)
	AND pg_lip_bloom_probe(4, mk.movie_id)
	AND pg_lip_bloom_probe(7, mk.movie_id)
) AS mk ,
name AS n ,
role_type AS rt ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(0, t.id)
	AND pg_lip_bloom_probe(4, t.id)
) AS t
WHERE
 ci.note IN ('(voice)',
                  '(voice: Japanese version)',
                  '(voice) (uncredited)',
                  '(voice: English version)')
  AND cn.country_code ='[us]'
  AND it.info = 'release dates'
  AND k.keyword IN ('hero',
                    'martial-arts',
                    'hand-to-hand-combat')
  AND mi.info IS NOT NULL
  AND (mi.info LIKE 'Japan:%201%'
       OR mi.info LIKE 'USA:%201%')
  AND n.gender ='f'
  AND n.name LIKE '%An%'
  AND rt.role ='actress'
  AND t.production_year > 2010
  AND t.id = mi.movie_id
  AND t.id = mc.movie_id
  AND t.id = ci.movie_id
  AND t.id = mk.movie_id
  AND mc.movie_id = ci.movie_id
  AND mc.movie_id = mi.movie_id
  AND mc.movie_id = mk.movie_id
  AND mi.movie_id = ci.movie_id
  AND mi.movie_id = mk.movie_id
  AND ci.movie_id = mk.movie_id
  AND cn.id = mc.company_id
  AND it.id = mi.info_type_id
  AND n.id = ci.person_id
  AND rt.id = ci.role_id
  AND n.id = an.person_id
  AND ci.person_id = an.person_id
  AND chn.id = ci.person_role_id
  AND k.id = mk.keyword_id;

