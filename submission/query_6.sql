/*
This query calculates the most games a single team has won in a given 90-game stretch.
*/

-- Deduplicate game details
WITH nba_game_details_deduped AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY game_id, team_id, player_id) row_number
    FROM bootcamp.nba_game_details
),

-- Combine game details with game results
combined AS (
    SELECT
        gd.game_id,
        gd.team_abbreviation,
        g.game_date_est,
        MAX(CASE 
            WHEN gd.team_id = g.home_team_id AND g.home_team_wins = 1 THEN 1   
            WHEN gd.team_id = g.visitor_team_id AND g.home_team_wins = 0 THEN 1 
            ELSE 0
        END) AS team_won_game
    FROM bootcamp.nba_games g 
    JOIN nba_game_details_deduped gd ON g.game_id = gd.game_id AND gd.row_number = 1
    WHERE g.game_date_est IS NOT NULL
    GROUP BY 
        gd.game_id,
        g.game_date_est,
        gd.team_abbreviation
    ),

-- Calculate win streaks
streaks AS (
    SELECT *,
        SUM(team_won_game) OVER (
            PARTITION BY team_abbreviation ORDER BY game_date_est 
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) AS win_streak
    FROM combined
)

-- Get maximum win streak for each team
SELECT team_abbreviation, MAX(win_streak) as max_games_won_90_day_stretch
FROM streaks
GROUP BY team_abbreviation
ORDER BY max_games_won_90_day_stretch DESC
