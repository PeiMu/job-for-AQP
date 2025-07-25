
DROP EXTENSION IF EXISTS pg_lip_bloom;
CREATE EXTENSION pg_lip_bloom;

SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(8);
SELECT sum(pg_lip_bloom_add(0, cct1.id)) FROM comp_cast_type AS cct1 WHERE cct1.kind = 'cast';
SELECT sum(pg_lip_bloom_add(1, cct2.id)) FROM comp_cast_type AS cct2 WHERE cct2.kind LIKE '%complete%';
SELECT sum(pg_lip_bloom_add(2, chn.id)) FROM char_name AS chn WHERE chn.name IS NOT NULL AND (chn.name LIKE '%man%' OR chn.name LIKE '%Man%');
SELECT sum(pg_lip_bloom_add(3, it2.id)) FROM info_type AS it2 WHERE it2.info = 'rating';
SELECT sum(pg_lip_bloom_add(4, k.id)) FROM keyword AS k WHERE k.keyword IN ('superhero', 'marvel-comics', 'based-on-comic', 'tv-special', 'fight', 'violence', 'magnet', 'web', 'claw', 'laser');
SELECT sum(pg_lip_bloom_add(5, kt.id)) FROM kind_type AS kt WHERE kt.kind = 'movie';
SELECT sum(pg_lip_bloom_add(6, mi_idx.movie_id)) FROM movie_info_idx AS mi_idx WHERE mi_idx.info > '7.0';
SELECT sum(pg_lip_bloom_add(7, t.id)) FROM title AS t WHERE t.production_year > 2000;

/*+
NestLoop(kt it2 cc cct1 cct2 mi_idx t ci chn mk k n)
NestLoop(kt it2 cc cct1 cct2 mi_idx t ci chn mk k)
NestLoop(kt it2 cc cct1 cct2 mi_idx t ci chn mk)
NestLoop(kt it2 cc cct1 cct2 mi_idx t ci chn)
NestLoop(kt it2 cc cct1 cct2 mi_idx t ci)
NestLoop(kt it2 cc cct1 cct2 mi_idx t)
NestLoop(it2 cc cct1 cct2 mi_idx t)
NestLoop(it2 cc cct1 cct2 mi_idx)
NestLoop(cc cct1 cct2 mi_idx)
HashJoin(cc cct1 cct2)
HashJoin(cc cct1)
SeqScan(kt)
SeqScan(it2)
SeqScan(cc)
SeqScan(cct1)
SeqScan(cct2)
IndexScan(mi_idx)
IndexScan(t)
IndexScan(ci)
IndexScan(chn)
IndexScan(mk)
IndexScan(k)
IndexScan(n)
Leading(((((((kt ((it2 (((cc cct1) cct2) mi_idx)) t)) ci) chn) mk) k) n))*/
SELECT MIN(chn.name) AS character_name,
       MIN(mi_idx.info) AS rating,
       MIN(n.name) AS playing_actor,
       MIN(t.title) AS complete_hero_movie
 FROM 
(
	SELECT * FROM complete_cast AS cc 
	 WHERE pg_lip_bloom_probe(0, cc.subject_id)
	AND pg_lip_bloom_probe(1, cc.status_id)
	AND pg_lip_bloom_probe(6, cc.movie_id)
	AND pg_lip_bloom_probe(7, cc.movie_id)
) AS cc ,
comp_cast_type AS cct1 ,
comp_cast_type AS cct2 ,
char_name AS chn ,
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(2, ci.person_role_id)
	AND pg_lip_bloom_probe(6, ci.movie_id)
	AND pg_lip_bloom_probe(7, ci.movie_id)
) AS ci ,
info_type AS it2 ,
keyword AS k ,
kind_type AS kt ,
(
	SELECT * FROM movie_info_idx AS mi_idx 
	 WHERE pg_lip_bloom_probe(3, mi_idx.info_type_id)
	AND pg_lip_bloom_probe(7, mi_idx.movie_id)
) AS mi_idx ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(4, mk.keyword_id)
	AND pg_lip_bloom_probe(6, mk.movie_id)
	AND pg_lip_bloom_probe(7, mk.movie_id)
) AS mk ,
name AS n ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(5, t.kind_id)
	AND pg_lip_bloom_probe(6, t.id)
) AS t
WHERE
 cct1.kind = 'cast'
  AND cct2.kind LIKE '%complete%'
  AND chn.name IS NOT NULL
  AND (chn.name LIKE '%man%'
       OR chn.name LIKE '%Man%')
  AND it2.info = 'rating'
  AND k.keyword IN ('superhero',
                    'marvel-comics',
                    'based-on-comic',
                    'tv-special',
                    'fight',
                    'violence',
                    'magnet',
                    'web',
                    'claw',
                    'laser')
  AND kt.kind = 'movie'
  AND mi_idx.info > '7.0'
  AND t.production_year > 2000
  AND kt.id = t.kind_id
  AND t.id = mk.movie_id
  AND t.id = ci.movie_id
  AND t.id = cc.movie_id
  AND t.id = mi_idx.movie_id
  AND mk.movie_id = ci.movie_id
  AND mk.movie_id = cc.movie_id
  AND mk.movie_id = mi_idx.movie_id
  AND ci.movie_id = cc.movie_id
  AND ci.movie_id = mi_idx.movie_id
  AND cc.movie_id = mi_idx.movie_id
  AND chn.id = ci.person_role_id
  AND n.id = ci.person_id
  AND k.id = mk.keyword_id
  AND cct1.id = cc.subject_id
  AND cct2.id = cc.status_id
  AND it2.id = mi_idx.info_type_id;

