-- Calculating cumulative wins and rolling 90-game wins for each team
WITH team_game_results AS (
    SELECT
        ngd.team_id,
        ngd.game_id,
        ngd.team_abbreviation,
        ng.game_date_est,
        SUM(
            CASE
                WHEN ngd.team_id = ng.team_id_home THEN ng.home_team_wins
                ELSE 1 - ng.home_team_wins
            END
        ) OVER (PARTITION BY ngd.team_id ORDER BY ng.game_date_est) AS cumulative_wins,
        SUM(
            CASE
                WHEN ngd.team_id = ng.team_id_home THEN ng.home_team_wins
                ELSE 1 - ng.home_team_wins
            END
        ) OVER (PARTITION BY ngd.team_id ORDER BY ng.game_date_est ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) AS rolling_90_game_wins
    FROM
        nba_game_details_deduped ngd
        JOIN nba_games_deduped ng ON ngd.game_id = ng.game_id
)
