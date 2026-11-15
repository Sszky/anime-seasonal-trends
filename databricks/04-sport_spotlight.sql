-- Databricks notebook source

-- COMMAND ----------
-- spotlight on sports anime
create or replace table animelist.anime_season.gold_sport_spotlight as
with sport as (
    select  a.*,
            rank() over (order by a.score desc) as score_rank,
            rank() over (order by a.popularity desc)    as popularity_rank,
            count(*) over ()    as sport_titles,
            round(100 * percent_rank() over (order by a.score), 1) as score_percentile
    from animelist.anime_season.silver_anime a
    join animelist.anime_season.silver_anime_genre g on a.anime_id = g.anime_id and g.genre = 'Sports'
    where a.score is not null
)

select  *,
        (title ilike '%haikyu%' or title_romaji ilike '%haikyu%') as is_haikyuu
from sport ; 

select title, season_year, season, format, score, popularity, score_rank, popularity_rank, sport_titles, score_percentile
from animelist.anime_season.gold_sport_spotlight
where is_haikyuu
order by season_year ;