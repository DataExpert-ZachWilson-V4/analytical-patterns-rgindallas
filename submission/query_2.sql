--Create function to perform aggregations of the nba_game_detials
CREATE OR REPLACE FUNCTION aggregate_game_details(game_details TABLE, games TABLE) RETURNS TABLE AS
BEGIN
    RETURN (
        SELECT     
            COALESCE(gd.player_name, 'Overall') AS player,
            COALESCE(gd.team_abbreviation, 'Overall') AS team,
            COALESCE(CAST(g.season AS VARCHAR), 'Overall') AS season,
            CASE   
                WHEN GROUPING(gd.player_name, gd.team_abbreviation) = 0 THEN 'player_team'
                WHEN GROUPING(gd.player_name, g.season) = 0 THEN 'player_season'
                WHEN GROUPING(gd.team_abbreviation) = 0 THEN 'team'
            END AS grouping_type,
            SUM(gd.pts) AS total_points,
            SUM(IF(
                (gd.team_id = g.home_team_id AND g.home_team_wins = 1) OR
                (gd.team_id = g.visitor_team_id AND g.home_team_wins = 0),
                1,
                0
            )) AS wins
        FROM (
            SELECT *,
                ROW_NUMBER() OVER(PARTITION BY game_id, team_id, player_id ORDER BY game_date_est) AS row_num
            FROM game_details
        ) AS gd
        JOIN games AS g ON gd.game_id = g.game_id
        WHERE gd.row_num = 1
        GROUP BY GROUPING SETS( 
            (player_name, team_abbreviation),
            (player_name, season),
            (team_abbreviation)
        )
    )
END
