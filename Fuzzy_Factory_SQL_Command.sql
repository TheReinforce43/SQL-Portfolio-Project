use mavenfuzzyfactory;
select * from mavenfuzzyfactory.order_item_refunds;

-- 1. Site Traffic breakdown

SELECT 
    utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS sessions
FROM
    mavenfuzzyfactory.website_sessions
WHERE
    created_at < '2012-04-12'
        AND utm_source IS NOT NULL
GROUP BY 1 , 2 , 3
ORDER BY 4 DESC;
 
 -- 2. site traffic breakdown only for gsearch utm_source
 SELECT 
    utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS sessions
FROM
    mavenfuzzyfactory.website_sessions
WHERE
    created_at < '2012-04-12'
        AND utm_source IS NOT NULL
        AND utm_campaign = 'nonbrand'
GROUP BY 1 , 2 , 3
ORDER BY 4 DESC;

-- 3. Gsearch conversion rate(CVR) where CVR at least 4%

with cte as (
SELECT 
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders
FROM
    mavenfuzzyfactory.website_sessions AS ws
        LEFT JOIN
    mavenfuzzyfactory.orders USING (website_session_id)
where
 
ws.utm_source='gsearch' and ws.utm_campaign='nonbrand' and ws.created_at < '2012-04-14'
)
select *,concat(round((orders/sessions)*100,2),'%') as CVR 
from cte;

-- where (orders/sessions)>=.04; 

-- 04. Trended Summaries with sessions

SELECT 
    YEAR(created_at) AS cr_year,
    WEEK(created_at) AS cr_week,
    COUNT(DISTINCT website_session_id) AS sessions
FROM
    mavenfuzzyfactory.website_sessions
WHERE
    website_session_id BETWEEN 100000 AND 115000
GROUP BY 1 , 2
ORDER BY 3 desc;

-- 5. Make Pivot table using SQL

SELECT 
    primary_product_id,
    COUNT(DISTINCT CASE
            WHEN items_purchased = 1 THEN order_id
            ELSE NULL
        END) AS order_1_purchased,
    COUNT(DISTINCT CASE
            WHEN items_purchased = 2 THEN order_id
            ELSE NULL
        END) AS order_2_purchased
FROM
    mavenfuzzyfactory.orders
WHERE
    order_id BETWEEN 31000 AND 32000
GROUP BY 1
ORDER BY 1 , 2 DESC;

-- 06. Gsearch volume trends

SELECT 
    MIN(DATE(created_at)) AS week_start,
    MAX(DATE(created_at)) AS week_end,
    COUNT(DISTINCT website_session_id) AS sessions
FROM
    mavenfuzzyfactory.website_sessions
WHERE
    created_at < '2012-05-10'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY YEARWEEK(created_at);
-- ORDER BY 2 DESC;

-- 07. Gsearch device level performance 
with cte as ( SELECT 
    ws.device_type,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders
FROM
    mavenfuzzyfactory.website_sessions AS ws
        LEFT JOIN
    mavenfuzzyfactory.orders AS o USING (website_session_id)
WHERE
    LOWER(ws.utm_source) = 'gsearch'
        AND ws.created_at < '2012-05-11'
        and lower(ws.utm_campaign)='nonbrand'
GROUP BY ws.device_type)
select * , concat(round( (orders/sessions)*100  ,2),' %') as conversion_Rate from cte;

-- 08. Gsearch device level trends
SELECT 
    MIN(DATE(created_at)) AS week_start,
    COUNT(CASE
        WHEN device_type = 'desktop' THEN website_session_id
        ELSE NULL
    END) AS dtop_sessions,
    COUNT(CASE
        WHEN device_type = 'mobile' THEN website_session_id
        ELSE NULL
    END) AS mob_sessions
FROM
    mavenfuzzyfactory.website_sessions
WHERE
    utm_campaign = 'nonbrand'
        AND utm_source = 'gsearch'
        AND created_at BETWEEN '2012-04-16' AND '2012-06-08'
GROUP BY YEARWEEK(created_at);

-- 09. top  5 Website Pages sessions before 2012-06-09

SELECT 
    pageview_url, COUNT(DISTINCT website_session_id) AS sessions
FROM
    mavenfuzzyfactory.website_pageviews AS wp
        LEFT JOIN
    mavenfuzzyfactory.website_sessions AS ws USING (website_session_id)
WHERE
    ws.created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY sessions DESC
LIMIT 5;

-- 10. top 5 entry pages
-- Step A) Find the first page views for each session via creating temporary table
-- Step B) Find the URL the customer saw on the first pageview

CREATE TEMPORARY TABLE first_page_views
	SELECT 
		website_session_id,
		MIN(website_pageview_id) AS min_page_views
	FROM mavenfuzzyfactory.website_pageviews
	WHERE created_at<'2012-06-12'
	GROUP BY website_session_id;

SELECT 
    wp.pageview_url AS landing_page,
    COUNT(DISTINCT fpv.website_session_id) AS first_hitting_page
FROM
    first_page_views AS fpv
        LEFT JOIN
    website_pageviews AS wp ON fpv.min_page_views = wp.website_pageview_id
GROUP BY 1;

-- 11. Find the landing page performance in a certain period of time in january,2014

-- Steps: 
-- A) Find the first website_pageview_id for relevant sessions
-- B) Indentifying the landing page of each sessions
-- C) Counting pageviews for each sessions, to identify "bounces"
-- D) Summarizing total sessions and bounced sessions by Landing Pages/Entry Pages

DROP TABLE  IF EXISTS first_page_views;

create temporary table first_page_views
SELECT 
    ws.website_session_id,
    MIN(wp.website_pageview_id) AS min_web_pageview_id
FROM
    mavenfuzzyfactory.website_sessions AS ws
        JOIN
    mavenfuzzyfactory.website_pageviews AS wp USING (website_session_id)
WHERE
    ws.created_at BETWEEN '2014-01-01' AND '2014-01-31'
GROUP BY ws.website_session_id;  

drop table if exists session_with_landing_page;
create temporary table session_with_landing_page
SELECT 
    fpv.website_session_id,
    wp.pageview_url AS landing_page
FROM
    first_page_views AS fpv
        LEFT JOIN
    mavenfuzzyfactory.website_pageviews AS wp ON fpv.min_web_pageview_id = wp.website_pageview_id;

drop table if exists bounced_sessions;
create temporary table  bounced_sessions
SELECT 
    swld.website_session_id,
    swld.landing_page,
    COUNT(wp.website_pageview_id) AS count_page_viewed
FROM
    session_with_landing_page AS swld
        LEFT JOIN
    mavenfuzzyfactory.website_pageviews AS wp USING (website_session_id)
GROUP BY 1 , 2
HAVING COUNT(wp.website_pageview_id) = 1;
    




-- Final Output
 with cte as (SELECT 
    swld.landing_page,
    COUNT(swld.website_session_id) AS sessions,
    COUNT(bs.website_session_id) AS bounced_sessions
FROM
    session_with_landing_page AS swld
        LEFT JOIN
    bounced_sessions AS bs USING (website_session_id)
GROUP BY 1)
SELECT 
    *,
    CONCAT(ROUND((bounced_sessions / sessions) * 100, 2),
            '%') AS bounced_percentage
FROM
    cte;
 
 
 
 