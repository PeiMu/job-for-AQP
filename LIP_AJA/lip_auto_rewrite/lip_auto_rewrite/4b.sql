
DROP EXTENSION IF EXISTS pg_lip_bloom;
CREATE EXTENSION pg_lip_bloom;

SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
SELECT sum(pg_lip_bloom_add(0, it.id)) FROM info_type AS it WHERE it.info ='rating';
SELECT sum(pg_lip_bloom_add(1, k.id)) FROM keyword AS k WHERE k.keyword LIKE '%sequel%';
SELECT sum(pg_lip_bloom_add(2, mi_idx.movie_id)) FROM movie_info_idx AS mi_idx WHERE mi_idx.info > '9.0';
SELECT sum(pg_lip_bloom_add(3, t.id)) FROM title AS t WHERE t.production_year > 2010;

/*+
NestLoop(mi_idx it t mk k)
NestLoop(mi_idx it t mk)
NestLoop(mi_idx it t)
HashJoin(mi_idx it)
SeqScan(mi_idx)
SeqScan(it)
IndexScan(t)
IndexScan(mk)
IndexScan(k)
Leading(((((mi_idx it) t) mk) k))*/
SELECT MIN(mi_idx.info) AS rating,
       MIN(t.title) AS movie_title
 FROM 
info_type AS it ,
keyword AS k ,
(
	SELECT * FROM movie_info_idx AS mi_idx 
	 WHERE pg_lip_bloom_probe(0, mi_idx.info_type_id)
	AND pg_lip_bloom_probe(3, mi_idx.movie_id)
) AS mi_idx ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(1, mk.keyword_id)
	AND pg_lip_bloom_probe(2, mk.movie_id)
	AND pg_lip_bloom_probe(3, mk.movie_id)
) AS mk ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(2, t.id)
) AS t
WHERE
 it.info ='rating'
  AND k.keyword LIKE '%sequel%'
  AND mi_idx.info > '9.0'
  AND t.production_year > 2010
  AND t.id = mi_idx.movie_id
  AND t.id = mk.movie_id
  AND mk.movie_id = mi_idx.movie_id
  AND k.id = mk.keyword_id
  AND it.id = mi_idx.info_type_id;

