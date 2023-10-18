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




 
 
 
 
 
 