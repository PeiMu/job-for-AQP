
DROP EXTENSION IF EXISTS pg_lip_bloom;
CREATE EXTENSION pg_lip_bloom;

SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(10);
SELECT sum(pg_lip_bloom_add(0, id)) FROM comp_cast_type AS cct1 WHERE cct1.kind IN ('cast', 'crew');
SELECT sum(pg_lip_bloom_add(1, id)) FROM comp_cast_type AS cct2 WHERE cct2.kind ='complete+verified';
SELECT sum(pg_lip_bloom_add(3, id)) FROM info_type AS it1 WHERE it1.info = 'genres';
SELECT sum(pg_lip_bloom_add(4, id)) FROM info_type AS it2 WHERE it2.info = 'votes';
-- SELECT sum(pg_lip_bloom_add(5, id)) FROM keyword AS k WHERE k.keyword IN ('murder',
--                     'violence',
--                     'blood',
--                     'gore',
--                     'death',
--                     'female-nudity',
--                     'hospital');

-- SELECT sum(pg_lip_bloom_add(2, movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(writer)',
--                   '(head writer)',
--                   '(written by)',
--                   '(story)',
--                   '(story editor)');

SELECT sum(pg_lip_bloom_add(2, movie_id)) FROM  movie_info AS mi WHERE mi.info IN ('Horror',
                  'Thriller');
-- SELECT sum(pg_lip_bloom_add(7, id)) FROM name AS n WHERE n.gender = 'm';
-- SELECT sum(pg_lip_bloom_add(2, id)) FROM title AS t WHERE t.production_year > 2000;


/*+
NestLoop(k mk mi_idx it2 cc cct1 cct2 ci mi it1 n t)
NestLoop(k mk mi_idx it2 cc cct1 cct2 ci mi it1 n)
NestLoop(k mk mi_idx it2 cc cct1 cct2 ci mi it1)
NestLoop(k mk mi_idx it2 cc cct1 cct2 ci mi)
NestLoop(k mk mi_idx it2 cc cct1 cct2 ci)
NestLoop(k mk mi_idx it2 cc cct1 cct2)
NestLoop(k mk mi_idx it2 cc cct1)
NestLoop(k mk mi_idx it2 cc)
HashJoin(k mk mi_idx it2)
NestLoop(k mk mi_idx)
NestLoop(k mk)
Leading((((((((((it2 ((k mk) mi_idx)) cc) cct1) cct2) ci) mi) it1) n) t))
*/
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS writer,
       MIN(t.title) AS complete_violent_movie
FROM (
        SELECT * FROM complete_cast as cc
        WHERE 
        pg_lip_bloom_probe(2, movie_id) AND 
        pg_lip_bloom_probe(0, subject_id) AND
        pg_lip_bloom_probe(1, status_id)   
     ) AS cc,
     comp_cast_type AS cct1,
     comp_cast_type AS cct2,
     (
        SELECT * FROM cast_info as ci
        WHERE 
        pg_lip_bloom_probe(2, movie_id) 
      --   AND
      --   pg_lip_bloom_probe(7, person_id)
     ) AS ci,
     info_type AS it1,
     info_type AS it2,
     keyword AS k,
     (
        SELECT * FROM movie_info as mi
        WHERE 
        pg_lip_bloom_probe(2, movie_id) AND
        pg_lip_bloom_probe(3, info_type_id)
     ) AS mi,
     (
        SELECT * FROM movie_info_idx as mi_idx
        WHERE 
        pg_lip_bloom_probe(2, movie_id) AND
        pg_lip_bloom_probe(4, info_type_id)
     ) AS mi_idx,
     (
        SELECT * FROM movie_keyword as mk
        WHERE 
        pg_lip_bloom_probe(2, movie_id) -- AND
         -- pg_lip_bloom_probe(5, keyword_id)
     ) AS mk,
     name AS n,
     (
         SELECT * FROM title as t
        WHERE pg_lip_bloom_probe(2, id)
     ) AS t
WHERE cct1.kind IN ('cast',
                    'crew')
  AND cct2.kind ='complete+verified'
  AND ci.note IN ('(writer)',
                  '(head writer)',
                  '(written by)',
                  '(story)',
                  '(story editor)')
  AND it1.info = 'genres'
  AND it2.info = 'votes'
  AND k.keyword IN ('murder',
                    'violence',
                    'blood',
                    'gore',
                    'death',
                    'female-nudity',
                    'hospital')
  AND mi.info IN ('Horror',
                  'Thriller')
  AND n.gender = 'm'
  AND t.production_year > 2000
  AND t.id = mi.movie_id
  AND t.id = mi_idx.movie_id
  AND t.id = ci.movie_id
  AND t.id = mk.movie_id
  AND t.id = cc.movie_id
  AND ci.movie_id = mi.movie_id
  AND ci.movie_id = mi_idx.movie_id
  AND ci.movie_id = mk.movie_id
  AND ci.movie_id = cc.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND mi.movie_id = mk.movie_id
  AND mi.movie_id = cc.movie_id
  AND mi_idx.movie_id = mk.movie_id
  AND mi_idx.movie_id = cc.movie_id
  AND mk.movie_id = cc.movie_id
  AND n.id = ci.person_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id
  AND k.id = mk.keyword_id
  AND cct1.id = cc.subject_id
  AND cct2.id = cc.status_id;
