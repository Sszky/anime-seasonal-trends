-- Databricks notebook source

-- COMMAND ----------
-- percentage of isekai titles by year
with yearly as(
    select season_year, count(*) as all_titles
    from animelist.anime_season.silver_anime
    group by season_year
),
isekai as(
    select a.season_year , count(*) as isekai_titles
    from animelist.anime_season.silver_anime a
    join animelist.anime_season.silver_anime_tag t on a.anime_id = t.anime_id 
    where t.tag = 'Isekai'
    group by a.season_year 
)

select y.season_year, 
        y.all_titles,
        coalesce(i.isekai_titles, 0) as isekai_titles,
        round(100.0 * coalesce(i.isekai_titles, 0)/y.all_titles, 1) as isekai_percent
from yearly y
left join isekai i on y.season_year = i.season_year
order by isekai_percent desc ;

-- COMMAND ----------
-- top sources by score
select source,
        count(*)    as titles,
        round(avg(score), 1)    as avg_score
from animelist.anime_season.silver_anime
where score is not null
group by source
having count(*) >= 10
order by avg_score desc ;

-- COMMAND ----------
-- high score titles by season
select season, 
        count(*) as all_titles,
        sum(case when score >= 80 then 1 else 0 end) as high_score_titles,
        round(100.0 * sum(case when score >= 80 then 1 else 0 end)/count(score), 1) as percent_high_score
from animelist.anime_season.silver_anime
group by season
order by high_score_titles desc ;

-- COMMAND ----------
-- top 10 studios by score
select studio, titles, avg_score, score_rank from animelist.anime_season.gold_studio
order by score_rank
limit 10 ;