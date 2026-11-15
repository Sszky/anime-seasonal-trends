-- Databricks notebook source

-- COMMAND ----------
-- anime seasonal summary
create or replace table animelist.anime_season.gold_season_summary as
select season_year, season, format,
        count(*)    as titles,
        sum(score)  as score_sum,
        count(score)    as scored_titles,
        sum(popularity) as total_popularity
from animelist.anime_season.silver_anime
group by season_year, season, format ;

-- COMMAND ----------
-- anime genre by year
create or replace table animelist.anime_season.gold_genre_year as
with yearly as (
    select season_year, format, count(*) as year_titles
    from animelist.anime_season.silver_anime
    group by season_year, format
)
select a.season_year, g.genre, a.format,
        count(*)    as titles,
        sum(a.score)    as score_sum,
        count(a.score)  as scored_titles,
        max(y.year_titles)  as year_titles
from animelist.anime_season.silver_anime a
join animelist.anime_season.silver_anime_genre g on a.anime_id = g.anime_id
join yearly y on a.season_year = y.season_year and a.format <=> y.format
group by a.season_year, g.genre, a.format ;

-- COMMAND ----------
-- anime studio summary
create or replace table animelist.anime_season.gold_studio as
select  s.studio,
        count(*)    as titles,
        round(avg(a.score)) as avg_score,
        sum(a.popularity)   as total_popularity,
        rank() over (order by avg(a.score) desc) as score_rank
from animelist.anime_season.silver_anime a
join animelist.anime_season.silver_anime_studio s on a.anime_id = s.anime_id
where a.score is not null
group by s.studio
having count(*) >= 5 ;

