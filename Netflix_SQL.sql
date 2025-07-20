CREATE TABLE shows (
show_id	INT,
title VARCHAR(50),
type VARCHAR(50),
genre VARCHAR(500),
language VARCHAR(50),
release_year INT,
imdb_rating FLOAT,
duration_mins INT,
is_original VARCHAR(20),
total_views INT
)

CREATE TABLE users(
user_id  INT,
name VARCHAR(100),
gender VARCHAR(20),
age INT,
city VARCHAR(50),
signup_date DATE,
plan_type VARCHAR(50),
device_type VARCHAR(50),
is_active VARCHAR(20),
language_pref VARCHAR(50)
)

CREATE TABLE watch_history(
watch_id INT,
user_id INT,
show_id INT,
watch_date DATE,
watch_duration INT,
is_completed VARCHAR(20),
device_type VARCHAR(50),
city VARCHAR(50),
rewatched_count INT,
user_rating INT
)

SELECT * FROM shows
SELECT * FROM users 
SELECT * FROM watch_history

--  User Insights
-- 1. Active User Count:
-- Count how many users are currently active.

SELECT COUNT(is_active) AS Active_user
FROM users 
WHERE is_active = 'True'

-- 2. Top Cities by Subscribers:
-- List the top 5 cities with the highest number of Netflix users.

SELECT city, COUNT(user_id) AS users
FROM users 
GROUP BY city
ORDER BY users DESC
LIMIT 5

-- 3. Plan Usage Breakdown:
-- Find the percentage of users for each plan_type.

SELECT  plan_type,
		COUNT(user_id) AS total_user,
		ROUND(COUNT(user_id) * 100.0 / (SELECT COUNT(user_id)
									FROM users ):: NUMERIC , 2) AS user_percentage 
FROM users
GROUP BY plan_type

-- 4. Most Popular Language Preference:
-- Which language_pref is most common among active users?

SELECT language_pref, COUNT(user_id) AS Active_user
FROM users 
WHERE is_active = 'True'
GROUP BY language_pref
ORDER BY Active_user DESC

-- 5. Average Age by Plan:
-- Show the average age of users grouped by plan_type.

SELECT  plan_type, 
		ROUND(AVG(age):: NUMERIC,2) AS Avg_age, 
		COUNT(user_id) AS total_user
FROM users
GROUP BY plan_type

-- 🔹 Content Analysis
-- 6. Top Rated Netflix Originals:
-- List the top 10 Netflix original shows (is_original = TRUE) with the highest IMDb rating.

SELECT title, ROUND(AVG(imdb_rating):: NUMERIC,2) AS avg_rating
FROM shows
WHERE is_original = 'True'
GROUP BY title
ORDER BY avg_rating DESC

-- 7. Most Viewed Show in India:
-- Which show has the highest total_views?

SELECT * 
FROM shows 
ORDER BY total_views DESC
LIMIT 1

-- 8. Genre-Wise Average Ratings:
-- Find the average imdb_rating grouped by genre.

SELECT genre, ROUND(AVG(imdb_rating):: NUMERIC,2) AS avg_rating
FROM shows
GROUP BY genre
ORDER BY avg_rating DESC

-- 9. Shows Released Each Year:
-- Count the number of shows released per year (from release_year).

SELECT release_year, COUNT(show_id) AS total_movies
FROM shows
GROUP BY release_year
ORDER BY release_year

-- 10. Longest Duration Movies:
-- List the top 5 longest movies (not TV Shows) by duration_mins.

SELECT * 
FROM shows
ORDER BY duration_mins DESC
LIMIT 1

-- 🔹 User Watch Behavior
-- 11. Average Watch Time Per User:
-- Calculate the average watch_duration per user.

SELECT ROUND(AVG(watch_duration):: NUMERIC ,2 ) 
					AS avg_watch_duration 
FROM watch_history

-- 12. Most Rewatched Shows:
-- Identify the top 5 show_ids with the highest total rewatched_count.

SELECT  wh.show_id, 
		title, type, genre, 
		language, SUM(watch_duration) AS total_rewatched_count
FROM watch_history AS wh
JOIN shows AS s
ON s.show_id = wh.show_id
GROUP BY wh.show_id, title, type, genre, language
ORDER BY total_rewatched_count DESC
LIMIT 5

-- 13. Users Who Rated All Watched Shows 5:
-- List user_ids who gave a rating of 5 to every show they watched.

SELECT DISTINCT user_id, user_rating
FROM watch_history 
WHERE user_rating = 5

-- 14. Watch Completion Rate by Device:
-- For each device type, calculate the percentage of watches that were fully completed (is_completed = TRUE).

SELECT  device_type, 
		COUNT(is_completed) AS fully_watch_show,
		ROUND(COUNT(is_completed) * 100.0 / (SELECT COUNT(is_completed)
										FROM watch_history
										WHERE is_completed = 'True'):: NUMERIC ,2 ) AS percentage_full_movie,
		ROUND(COUNT(is_completed) * 100 / (SELECT COUNT(is_completed)
										FROM watch_history):: NUMERIC ,2 ) AS total_percentage
FROM watch_history
WHERE is_completed = 'True'
GROUP BY device_type
ORDER BY fully_watch_show DESC

-- 15. Monthly Active Users Trend:
-- Count unique user_ids watching shows month-wise for the past 12 months.

SELECT  EXTRACT(MONTH FROM watch_date) AS month_no,
		TO_CHAR(watch_date, 'Month') AS Watch_month,
		COUNT( DISTINCT user_id) AS unique_user
FROM watch_history
WHERE watch_date >= CURRENT_DATE - INTERVAL '12 month'
GROUP BY month_no, watch_month
ORDER BY month_no

-- 🔹 Joins and Combined Insights
-- 16. Top 5 Cities with Highest Total Watch Time:
-- Using watch_history and users_india, get top 5 cities by total watch_duration.

SELECT u.city,  SUM(wh.watch_duration) AS total_watch_time
FROM users AS u
JOIN watch_history AS wh
ON u.user_id = wh.user_id
GROUP BY u.city
ORDER BY total_watch_time DESC
LIMIT 5

-- 17. Top 3 Shows Watched by Premium Users:
-- Find the top 3 show_ids with the most views by users who are on a Premium plan.

SELECT s.show_id, s.title, s.type, s.genre, s.language, COUNT(wh.user_id) AS total_watching
FROM shows AS S
JOIN watch_history AS wh
ON s.show_id = wh.show_id
JOIN users AS u
ON u.user_id = wh.user_id
WHERE plan_type = 'Premium'
GROUP BY s.show_id, s.title, s.type, s.genre, s.language
ORDER BY total_watching DESC
LIMIT 3

-- 18. Genre Popularity Among Young Viewers:
-- Find the most-watched genres by users aged under 25.

SELECT s.genre, COUNT(wh.watch_id) AS total_watcher
FROM shows AS s
JOIN watch_history AS wh 
ON s.show_id = wh.show_id
JOIN users AS u
ON u.user_id = wh.user_id 
WHERE age > 15 and age < 25
GROUP BY s.genre
ORDER BY total_watcher DESC

-- 19. User-Show Match with High Rating & Rewatch:
-- List users who gave a rating of 5 and rewatched a show more than 2 times.

SELECT wh.show_id, s.title AS movie_name, u.name, rewatched_count
FROM shows AS s
JOIN watch_history AS wh
ON wh.show_id = s.show_id 
JOIN users AS u
ON u.user_id = wh.user_id 
WHERE user_rating = 5 AND rewatched_count >= 2
ORDER BY rewatched_count DESC

-- 20. Plan-Wise Average Viewing Duration per Show:
-- Find average watch duration per show for each plan type (Basic, Standard, Premium).

SELECT movie_name, plan_type, avg_watch_duration, ranking
FROM (
	SELECT *,
	RANK() OVER(PARTITION BY plan_type ORDER BY avg_watch_duration DESC) AS ranking
	FROM (
		SELECT  s.title AS movie_name, u.plan_type, 
				ROUND(AVG(WH.watch_duration):: NUMERIC ,2) AS  avg_watch_duration
		FROM shows AS s
		JOIN watch_history AS wh
		ON wh.show_id = s.show_id 
		JOIN users AS u
		ON u.user_id = wh.user_id
		GROUP BY s.title, u.plan_type) AS x ) AS z
WHERE ranking <= 5 


-- 21. Churn Risk Users
-- List users who have not watched anything in the last 90 days but are still marked as is_active = TRUE.

SELECT  name, watch_date AS last_movie_date
FROM (
	SELECT DISTINCT name, watch_date,
	RANK() OVER(PARTITION BY name ORDER BY watching_month DESC) AS ranking
	FROM (
		SELECT  EXTRACT(MONTH FROM watch_date) AS month_no,
				TO_CHAR(watch_date, 'month') watching_month,
				COUNT( DISTINCT wh.user_id), u.name, watch_date
		FROM users AS u
		JOIN watch_history AS wh
		ON wh.user_id = u.user_id
		WHERE watch_date  NOT IN (SELECT watch_date 
															FROM watch_history
															WHERE watch_date >= CURRENT_DATE - INTERVAL '3 month')
						AND is_active = 'True'
		GROUP BY month_no, watching_month,  u.name, watch_date ) AS x )

-- 22. Top Performing Originals by City
-- For each city, find the most watched Netflix Original show (based on watch_duration).

SELECT movie_name, city, total_watch_time
FROM (
	SELECT *,
	RANK() OVER(PARTITION BY city ORDER BY total_watch_time DESC) AS ranking
	FROM (
		SELECT  s.title AS movie_name, u.city, 
				SUM(wh.watch_duration) AS total_watch_time
		FROM shows AS s
		JOIN watch_history AS wh
		ON wh.show_id = s.show_id
		JOIN users AS u
		ON wh.user_id = u.user_id
		WHERE is_original = 'True'
		GROUP BY s.title, u.city ) AS x ) AS z
WHERE ranking = 1
	 
-- 23. User Lifetime Watch Summary
-- For every user, calculate:
-- Total shows watched
-- Total minutes watched
-- Average rating given
-- % of completed shows


SELECT COUNT( DISTINCT name)
FROM users

SELECT  u.user_id, u.name,
		COUNT(wh.user_id) AS total_watching_movie,
		SUM(watch_duration) AS total_watching_duration,
		ROUND(AVG(user_rating):: NUMERIC , 2) AS avg_rating,
		ROUND((COUNT(is_completed) * 100.0 /( SELECT COUNT(is_completed)
												FROM watch_history
												WHERE is_completed = 'True' ) * 1000.0):: NUMERIC , 2) AS completed_show_percentage
FROM shows AS s
JOIN watch_history AS wh
ON wh.show_id = s.show_id
JOIN users AS u
ON u.user_id = wh.user_id
GROUP BY u.user_id, u.name

-- 24. Highest Rated Genre by Plan Type
-- Which genre has the highest average user rating for each plan_type?

SELECT *,
RANK() OVER(PARTITION BY plan_type ORDER BY avg_rating DESC ) AS ranking
FROM (
	SELECT s.genre, plan_type, ROUND(AVG(user_rating):: NUMERIC , 2) AS avg_rating
	FROM shows AS s
	JOIN watch_history AS wh
	ON wh.show_id = s.show_id
	JOIN users AS u
	ON u.user_id = wh.user_id
	GROUP BY s.genre, plan_type ) AS x

-- 25. User Loyalty Score (Custom Metric)
-- Create a loyalty score for each user using:
-- loyalty_score = (total_watch_duration / age) + (rewatched_count * 2)
-- Rank users by this custom loyalty metric (Top 20).

SELECT *
FROM (
	SELECT *,
	RANK() OVER(ORDER BY loyalty_score DESC) AS ranking
	FROM (
		SELECT  DISTINCT u.name, u.age,
				SUM(wh.watch_duration / u.age) + (rewatched_count * 2) AS loyalty_score
		FROM users AS u
		JOIN watch_history AS wh
		ON wh.user_id = u.user_id
		GROUP BY u.name, u.age, rewatched_count ) AS x ) AS y
WHERE ranking <= 20

-- 26. Show Drop-off Analysis
-- Find shows where more than 60% of views were not completed (is_completed = FALSE).
-- These are shows users tend to leave midway.

SELECT  wh.show_id, s.title AS movie_name, s.type, s.genre, s.language, s.imdb_rating,
		ROUND(
        (SUM(CASE WHEN wh.is_completed = 'False' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2
    ) AS incomplete_percentage
FROM shows AS s
JOIN watch_history AS wh
ON wh.show_id = s.show_id 
GROUP BY wh.show_id, s.title, s.type, s.genre, s.language, s.imdb_rating
HAVING (SUM(CASE WHEN wh.is_completed = 'False' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) > 60
ORDER BY incomplete_percentage  

-- 27. Most Watched Genre per Age Group
-- Create age groups:
-- Below 18
-- 18–30
-- 31–50
-- Above 50
-- For each group, find the most watched genre.

SELECT genre, age_group, watched_genre
FROM (
	SELECT *,
	RANK() OVER(PARTITION BY age_group ORDER BY watched_genre DESC) AS ranking
	FROM (
		SELECT s.genre,
				( CASE
					WHEN age < 18 THEN 'Below 18'
					WHEN age >=18 AND age < 30 THEN '18 - 30'
					WHEN age >= 30 AND age < 50 THEN '31 - 50'
					WHEN age >= 50 THEN 'Above 50'
				END )  AS age_group,
				COUNT(genre) AS watched_genre
		FROM shows AS s
		JOIN watch_history AS wh
		ON wh.show_id = s.show_id
		JOIN users AS u
		ON u.user_id = wh.user_id 
		GROUP BY s.genre, age ) AS x ) AS y
WHERE ranking = 1


-- 28. Power Users
-- Identify users who:
-- Watched more shows
-- Have average rating given ≥ 4
-- Have rewatched at least 10 different shows

SELECT  u.user_id, 
		COUNT(s.show_id) AS total_watch_show, 
		SUM(rewatched_count) AS total_watch_count, 
		ROUND(AVG(user_rating):: NUMERIC ,2) AS avg_rating
FROM shows AS s
JOIN watch_history AS wh
ON wh.show_id = s.show_id
JOIN users AS u
ON u.user_id = wh.user_id 
GROUP BY u.user_id
HAVING SUM(rewatched_count) > 10 AND ROUND(AVG(user_rating):: NUMERIC ,2) >= 4
ORDER BY total_watch_show DESC

-- 29. Device Preference by Plan Type
-- For each plan_type, show the most preferred device_type (based on number of watches).

SELECT *, 
RANK() OVER(PARTITION BY plan_type ORDER BY device_count DESC) AS ranking
FROM (
	SELECT  plan_type, wh.device_type, COUNT(wh.device_type) AS device_count,
			ROUND(COUNT(wh.device_type) * 100.0 / ( SELECT COUNT(device_type)
											FROM watch_history):: NUMERIC, 2) AS percentage
	FROM users AS u
	JOIN watch_history AS wh
	ON wh.user_id = u.user_id
	GROUP BY  plan_type, wh.device_type ) AS x

-- 30. City Engagement Score
-- For each city, calculate an "engagement score":
-- engagement_score = total_watch_duration * avg_rating * % completed views
-- Rank cities by this custom metric.

SELECT * FROM shows
SELECT * FROM users 	
SELECT * FROM watch_history

SELECT  u.city,
		ROUND(SUM(watch_duration) * AVG(user_rating) * 
		(SELECT percentaeg
			FROM (
				SELECT  is_completed,
						ROUND(COUNT(is_completed) * 100.0/ ( SELECT COUNT(is_completed)
														FROM watch_history
														):: NUMERIC ,2 ) AS percentaeg
						FROM watch_history
						GROUP BY is_completed
						HAVING is_completed = 'True' )):: NUMERIC ,2) AS engagement_score
FROM users AS u
JOIN watch_history AS wh
ON wh.user_id = u.user_id
GROUP BY u.city
ORDER BY engagement_score DESC

