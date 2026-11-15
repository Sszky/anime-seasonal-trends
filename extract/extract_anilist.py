"""
Anime Seasonal Trends Pipeline - 1st step extract(bronze)
"""

import json
import time
from datetime import datetime, timezone
from pathlib import Path
import requests

# ------ settings ------
BASE_URL = "https://graphql.anilist.co"
START_YEAR = 2014
END_YEAR = 2025
SEASONS = ["WINTER", "SPRING", "SUMMER", "FALL"]
OUTPUT_DIR = Path("data/bronze")
SLEEP_BETWEEN_CALLS = 2.5
MAX_RETRIES = 5

QUERY = """
query ($season: MediaSeason, $seasonYear: Int, $page: Int) {
    Page(page: $page, perPage: 50) {
        pageInfo { currentPage, hasNextPage }
        media(season: $season, seasonYear: $seasonYear, type: ANIME, isAdult: false) {
            id
            idMal
            title { romaji english }
            format
            status
            episodes
            duration
            source
            season
            seasonYear
            startDate { year month day }
            averageScore
            meanScore
            popularity
            favourites
            genres
            tags { name rank }
            studios(isMain: true) { nodes { name isAnimationStudio } }
            }
        }
    }
"""

def post_with_retry(variables):
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = requests.post(
                BASE_URL,
                json = {"query": QUERY, "variables": variables},
                headers = {"Accept": "application/json"},
                timeout = 30,
            )
        except requests.RequestException as e:
                print(f" ! network error: {e}, retrying ({attempt}/{MAX_RETRIES})...")
                response = None

        if response is not None and response.status_code == 200:
            body = response.json()
            if body.get("errors"):
                raise RuntimeError(f"GraphQL error: {body['errors']}")
            return body

        if response is not None and response.status_code == 429:
            wait = int(response.headers.get("Retry-After", 60))
        elif response is None or response.status_code >= 500:
            wait = 2**attempt
        else:
            print(response.text[:500])
            response.raise_for_status()

        code = response.status_code if response is not None else "no response"
        print(f" ! got {code}, retry {attempt}/{MAX_RETRIES}, waiting {wait}s...")
        time.sleep(wait)

    raise RuntimeError(f"Failed after {MAX_RETRIES} retries: {variables}")


def fetch_season(year, season):
    page = 1
    all_anime = []

    while True:
        body = post_with_retry({"season": season, "seasonYear": year, "page": page})
        page_data = body["data"]["Page"]
        all_anime.extend(page_data["media"])
        print(f" {year} {season} page {page} (+{len(page_data['media'])})")

        time.sleep(SLEEP_BETWEEN_CALLS)
        if not page_data["pageInfo"]["hasNextPage"]:
            break
        page += 1

    return all_anime

def save_jsonl(records, path, year, season):
    ingested_at = datetime.now(timezone.utc).isoformat()
    tmp_path = path.with_suffix(".tmp")
    with open(tmp_path, "w", encoding="utf-8") as f:
        for anime in records:
            anime["_source_year"] = year
            anime["_source_season"] = season
            anime["_ingested_at"] = ingested_at
            f.write(json.dumps(anime, ensure_ascii=False) + "\n")

    tmp_path.replace(path)

def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    total = 0

    for year in range(START_YEAR, END_YEAR + 1):
        for season in SEASONS:
            out_path = OUTPUT_DIR / f"anilist_{year}_{season.lower()}.jsonl"
            if out_path.exists():
                print(f"skip {year} {season} (already downloaded)")
                continue

            print(f"fetching {year} {season} ...")
            records = fetch_season(year, season)
            save_jsonl(records, out_path, year, season)
            total += len(records)
            print(f" saved {len(records)} rows -> {out_path}")

    print(f"\nDone. New rows this run: {total}")


if __name__ == "__main__":
    main()