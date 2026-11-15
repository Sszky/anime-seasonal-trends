-- Databricks notebook source

-- COMMAND ----------
-- bronze season anime table
create or replace table animelist.anime_season.bronze_season_anime as
select * , current_timestamp() as loaded_at
from json. `/Volumes/animelist/anime_season/raw/seasons/data/bronze`;

describe animelist.anime_season.bronze_season_anime;

-- COMMAND ----------
-- summary of bronze season anime table
select
    count(*)                        as raw_rows,
    count(distinct id)              as unique_anime,
    count(*) - count(distinct id)   as duplicate_rows,
    sum(case when season <> _source_season 
        or seasonYear <> _source_year 
        then 1 else 0 end)          as season_mismatch,
    sum(case when averageScore is null then 1 else 0 end)   as no_score,
    sum(case when episodes is null then 1 else 0 end)   as no_episodes,
    sum(case when size(studios.nodes) = 0 then 1 else 0 end)    as no_studio
from animelist.anime_season.bronze_season_anime;

select format, count(*) as title, round(avg(popularity), 1 ) as avg_popularity
from animelist.anime_season.bronze_season_anime
where averageScore is null
group by format
order by title desc;