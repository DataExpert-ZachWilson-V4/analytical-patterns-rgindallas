WITH yesterday AS (
    SELECT *
    FROM rgindallas.nba_players_state_tracking
    WHERE current_season = 1996
),
today AS (
    SELECT
        player_name,
        current_season,
        MIN(s.season) AS first_active_season,
        MAX(s.season) AS last_active_season
    FROM bootcamp.nba_players,
        UNNEST(seasons) s
    WHERE current_season = 1997
    GROUP BY 1, 2
),
combined AS (
    SELECT
        COALESCE (y.player_name, t.player_name) AS player_name,
        COALESCE (y.first_active_season, t.first_active_season) AS first_active_season,
        CASE
            WHEN t.current_season - t.last_active_season != 0 THEN y.last_active_season
            ELSE t.current_season
        END AS last_active_season,
        y.last_active_season AS season_yesterday,
        t.current_season
    FROM yesterday y
    FULL OUTER JOIN today t
        ON y.player_name = t.player_name
)
SELECT player_name,
    first_active_season,
    last_active_season,
    CASE
        WHEN current_season - first_active_season = 0 THEN 'New'
        WHEN last_active_season - season_yesterday = 0 THEN 'Continued Playing'
        WHEN current_season - last_active_season = 1 THEN 'Retired'
        WHEN current_season - season_yesterday > 1 AND current_season = last_active_season THEN 'Returned from Retirement'
        WHEN current_season - last_active_season > 1 THEN 'Stayed Retired'
    END AS season_active_state
FROM combined
