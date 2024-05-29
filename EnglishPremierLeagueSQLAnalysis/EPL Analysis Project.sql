/*
	English Premier League Results Analysis using SQL
*/

-- Understanding the data was questions and interpretations!
-- Top 5 teams with the most home / away wins in the premier league?
-- Most home wins
SELECT HomeTeam, COUNT(FTR) HomeWins
FROM epl
WHERE FTR = 'H'
GROUP BY HomeTeam
ORDER BY HomeWins DESC
LIMIT 5;

-- Most away wins
SELECT AwayTeam, COUNT(FTR) AwayWins
FROM epl
WHERE FTR = 'A'
GROUP BY AwayTeam
ORDER BY AwayWins DESC
LIMIT 5;

-- Top 20 teams that have the highest goal-scoring record at home and away in the PL?
-- Home teams goals scored
SELECT HomeTeam, SUM(FTHG) HomeGoals
FROM epl
GROUP BY HomeTeam
ORDER BY HomeGoals DESC
LIMIT 20;

SELECT AwayTeam, SUM(FTAG) AwayGoals
FROM epl
GROUP BY AwayTeam
ORDER BY AwayGoals DESC
LIMIT 20;

-- Which teams have the best average defense in the PL?
SELECT HomeTeam, avg(FTAG) HomeGoalsConceded, avg(FTHG) AwayGoalsConceded
FROM epl
GROUP BY HomeTeam
ORDER BY HomeGoalsConceded;

-- Which 3 teams are the most disciplined in the PL?
SELECT HomeTeam, sum(HY + AY) TotalYellowCards, sum(HR + AR) TotalRedCards
FROM epl 
GROUP BY HomeTeam
HAVING TotalYellowCards IS NOT NULL and TotalRedCards IS NOT NULL
ORDER BY TotalYellowCards, TotalRedCards;

-- Which team has the best win record against another team in the PL?
SELECT SEASON, `Date`,
		LEFT(MatchDate,11) AS `Date`, 
        HomeTeam,
        AwayTeam,
        CONCAT(FTHG, '-', FTAG) AS Result,
        CONCAT(HTHG, '-', HTAG) AS HalfTime,
        IF(FTHG > FTAG, 'Arsenal Win', IF(FTHG = FTAG, 'Draw', 'Spurs Win')) AS Result
FROM epl 
WHERE HomeTeam IN ('Arsenal', 'Tottenham') AND AwayTeam IN ('Tottenham', 'Arsenal') AND HomeTeam <> AwayTeam
ORDER BY `Date` DESC;
  


