/*
Below are my responses to the capstone
questions. I have modified all answers
to support many segments in keeping
with question #9.
 */


-- 1
/* There are two different segments -
namely, "30" and "87".
*/

SELECT segment
FROM subscriptions
GROUP BY segment;


-- 2
/*
Churn can only be calculated between
January and March in 2017. Given
that churn = attrition/initial, churn
cannot be calculated for December or
after March (since there is no attrition
data).
*/

SELECT subscription_start AS start_date,
subscription_end AS end_date
FROM subscriptions
ORDER BY start_date, end_date;


-- 3
/*
Create the months temporary table
 */

SELECT '2017-01-01' AS first_day,
	  '2017-01-31' AS last_day
UNION
SELECT '2017-02-01' AS first_day,
  '2017-02-28' AS last_day
UNION
SELECT '2017-03-01' AS first_day,
  '2017-03-31' AS last_day;


-- 4
/*
Create the cross-join temporary table
 */

WITH months AS (
  SELECT '2017-01-01' AS first_day,
	  '2017-01-31' AS last_day
	UNION
	SELECT '2017-02-01' AS first_day,
	  '2017-02-28' AS last_day
	UNION
	SELECT '2017-03-01' AS first_day,
    '2017-03-31' AS last_day
)
SELECT *
FROM subscriptions
CROSS JOIN months;


-- 5
/*
Create the status temporary table
 */

WITH months AS (
  SELECT '2017-01-01' AS first_day,
	  '2017-01-31' AS last_day
	UNION
	SELECT '2017-02-01' AS first_day,
	  '2017-02-28' AS last_day
	UNION
	SELECT '2017-03-01' AS first_day,
    '2017-03-31' AS last_day
), cross_join AS (
  SELECT *
  FROM subscriptions
  CROSS JOIN months
)
SELECT cross_join.id AS id,
  cross_join.first_day AS month,
  subscriptions.segment AS segment,
  CASE WHEN cross_join.subscription_start
         < cross_join.first_day
         AND (cross_join.subscription_end
         > cross_join.first_day
         OR cross_join.subscription_end
         is NULL)
       THEN 1
       ELSE 0
  END AS is_active
FROM cross_join
LEFT JOIN subscriptions
  ON cross_join.id = subscriptions.id;


-- 6
/*
Add cancellations columns to the status
temporary table
 */

WITH months AS (
  SELECT '2017-01-01' AS first_day,
	  '2017-01-31' AS last_day
	UNION
	SELECT '2017-02-01' AS first_day,
	  '2017-02-28' AS last_day
	UNION
	SELECT '2017-03-01' AS first_day,
    '2017-03-31' AS last_day
), cross_join AS (
  SELECT *
  FROM subscriptions
  CROSS JOIN months
)
SELECT cross_join.id AS id,
  cross_join.first_day AS month,
  subscriptions.segment AS segment,
  CASE WHEN cross_join.subscription_start
         < cross_join.first_day
         AND (cross_join.subscription_end
         > cross_join.first_day
         OR cross_join.subscription_end
         IS NULL)
     THEN 1
     ELSE 0
  END AS is_active,
  CASE WHEN (cross_join.subscription_end
         BETWEEN cross_join.first_day
         AND cross_join.last_day)
       THEN 1
       ELSE 0
  END AS is_canceled
FROM cross_join
LEFT JOIN subscriptions
  ON cross_join.id = subscriptions.id;


-- 7
/*
Create status_aggregate temporary table
 */

WITH months AS (
  SELECT '2017-01-01' AS first_day,
	  '2017-01-31' AS last_day
	UNION
	SELECT '2017-02-01' AS first_day,
	  '2017-02-28' AS last_day
	UNION
	SELECT '2017-03-01' AS first_day,
    '2017-03-31' AS last_day
), cross_join AS (
  SELECT *
  FROM subscriptions
  CROSS JOIN months
), status AS (
  SELECT cross_join.id AS id,
    cross_join.first_day AS month,
    subscriptions.segment AS segment,
    CASE WHEN cross_join.subscription_start
         < cross_join.first_day
         AND (cross_join.subscription_end
         > cross_join.first_day
         OR cross_join.subscription_end
         IS NULL)
     THEN 1
     ELSE 0
  END AS is_active,
    CASE WHEN (cross_join.subscription_end
           BETWEEN cross_join.first_day
           AND cross_join.last_day)
         THEN 1
         ELSE 0
    END AS is_canceled
  FROM cross_join
  LEFT JOIN subscriptions
    ON cross_join.id = subscriptions.id
)
SELECT month,
 segment,
 SUM(is_active) AS sum_active,
 SUM(is_canceled) AS sum_canceled
FROM status
GROUP BY segment, month;

-- 8 and 9
/*
Churn Rates by Month - per #9, modified #8
to support many segments instead of only 2.

Segment 30 has the least churn. Segment 87
has 3 to 4 times as much churn every month.
 */

WITH months AS (
  SELECT '2017-01-01' AS first_day,
	  '2017-01-31' AS last_day
	UNION
	SELECT '2017-02-01' AS first_day,
	  '2017-02-28' AS last_day
	UNION
	SELECT '2017-03-01' AS first_day,
    '2017-03-31' AS last_day
), cross_join AS (
  SELECT *
  FROM subscriptions
  CROSS JOIN months
), status AS (
  SELECT cross_join.id AS id,
    cross_join.first_day AS month,
    subscriptions.segment AS segment,
    CASE WHEN cross_join.subscription_start
         < cross_join.first_day
         AND (cross_join.subscription_end
         > cross_join.first_day
         OR cross_join.subscription_end
         IS NULL)
     THEN 1
     ELSE 0
  END AS is_active,
    CASE WHEN (cross_join.subscription_end
           BETWEEN cross_join.first_day
           AND cross_join.last_day)
         THEN 1
         ELSE 0
    END AS is_canceled
  FROM cross_join
  LEFT JOIN subscriptions
    ON cross_join.id = subscriptions.id
), status_aggregate AS (
     SELECT month,
       segment,
       SUM(is_active) AS sum_active,
       SUM(is_canceled) AS sum_canceled
     FROM status
     GROUP BY segment, month
)
SELECT month,
  segment,
  printf("%.2f%%",
    100.0 * sum_canceled/sum_active)
    AS churn
FROM status_aggregate;