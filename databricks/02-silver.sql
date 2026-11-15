-- Databricks notebook source

-- COMMAND ----------
-- deduplicate bronze anime table
create or replace temp view v_dedup as
select *
from animelist.anime_season.bronze_season_anime
qualify row_number() over (partition by id order by _ingested_at desc) = 1 ;

-- COMMAND ----------
-- create silver anime table
create or replace table animelist.anime_season.silver_anime as
select
    id  as anime_id,
    idMal   as mal_id,
    coalesce(title.english, title.romaji)  as title,
    title.romaji   as title_romaji,
    format,
    source,
    try_cast(episodes as int)   as episodes,
    try_cast(duration as int)   as episode_minute,
    try_cast(averageScore as int)   as score,
    try_cast(popularity as bigint) as popularity,
    try_cast(favourites as bigint)  as favourite,
    coalesce(seasonYear, _source_year)  as season_year,
    coalesce(season, _source_season)    as season,
    make_date(startDate.year, startDate.month, startDate.day) as start_date
    from v_dedup;

-- COMMAND ----------
-- create silver anime genre table
create or replace table animelist.anime_season.silver_anime_genre as
select distinct id as anime_id, g as genre
from v_dedup lateral view explode(genres) t as g ;

-- COMMAND ----------
-- create silver anime tag table
create or replace table animelist.anime_season.silver_anime_tag as
select distinct id as anime_id, t.name as tag, t.rank as tag_rank
from v_dedup lateral view explode(tags) x as t
where t.rank >= 60 ;

-- COMMAND ----------
-- create silver anime studio table
create or replace table animelist.anime_season.silver_anime_studio as
select distinct id as anime_id, s.name as studio
from v_dedup lateral view explode(studios.nodes) x as s
where s.isAnimationStudio ;

--- COMMAND ----------
-- summary of silver anime table
select count(*) from animelist.anime_season.silver_anime ;