-- Q1) Monthly trends for gsearch sessions & orders

select
	month(website_sessions.created_at) as month,
    count(website_sessions.website_session_id) as gsearch_sessions,
    count(order_id) as gsearch_orders
from website_sessions
	left join orders
    on website_sessions.website_session_id = orders.website_session_id
where website_sessions.utm_source = "gsearch"
	and website_sessions.created_at < "2012-11-27"
group by 1;

-- Q2) monthly data for sessions & orders splitted in nonbrand & brand

select
	month(website_sessions.created_at) as month,
    count(case when website_sessions.utm_campaign = "nonbrand" then website_sessions.website_session_id else null end) as gsearch_nonbrand_sessions,
    count(case when website_sessions.utm_campaign = "nonbrand" then orders.order_id else null end) as gsearch_nonbrand_orders,
     count(case when website_sessions.utm_campaign = "brand" then website_sessions.website_session_id else null end) as gsearch_brand_sessions,
     count(case when website_sessions.utm_campaign = "brand" then orders.order_id else null end) as gsearch_brand_orders
from website_sessions
	left join orders
    on website_sessions.website_session_id = orders.website_session_id
where website_sessions.utm_source = "gsearch"
	and website_sessions.created_at < "2012-11-27"
group by 1;
    
-- Q3) monthly gsearch & nonbrand sessions & orders split by device type
select 
	month(website_sessions.created_at) as  month,
    website_sessions.device_type,
    count(case when website_sessions.utm_campaign = "nonbrand" then website_sessions.website_session_id else null end) as gsearch_nonbrand_sessions,
    count(case when website_sessions.utm_campaign = "nonbrand" then orders.order_id else null end) as gsearch_nonbrand_orders
from website_sessions
left join orders
    on website_sessions.website_session_id = orders.website_session_id
where website_sessions.utm_source = "gsearch"
	and website_sessions.utm_campaign = "nonbrand"
	and website_sessions.created_at < "2012-11-27"
group by 1, 2
order by 1;

-- Q4) monthly trend for gsearch alongwith other channels
select 
    month(created_at) as month,
    count(distinct case when utm_source = "gsearch" then website_session_id else null end)/( select count(website_session_id) from website_sessions where created_at <"2012-11-27") as percent_traffic_gsearch,
    count(distinct case when utm_source = "bsearch" then website_session_id else null end)/( select count(website_session_id) from website_sessions where created_at <"2012-11-27") as percent_traffic_gsearch,
	count(distinct case when utm_source = "" then website_session_id else null end)/( select count(website_session_id) from website_sessions where created_at <"2012-11-27") as percent_traffic_for_no_source
from website_sessions
where created_at < "2012-11-27"
group by 1;

-- Q5) monthly session to order conversion rate 

select 
	month(website_sessions.created_at) as Month,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as session_to_order_conversion_rt
from website_sessions
	left join orders
	on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < "2012-11-27"
group by 1; 

-- Q7) conversion funnel for both landers ("2012-06-19" and "2012-07-28")
-- step 1- divided session IDs w.r.t. landing page
create temporary table kaustubh
select 
	website_pageviews.pageview_url as url,
    website_sessions.website_session_id as sessions
  -- count(distinct case when website_pageviews.pageview_url = "/home" then website_sessions.website_session_id else null end) as home,
  -- count(distinct case when website_pageviews.pageview_url = "/lander-1" then website_sessions.website_session_id else null end) as lander
from website_pageviews
	left join website_sessions
    on website_pageviews.website_session_id = website_sessions.website_session_id
where website_pageviews.created_at between "2012-06-19" and "2012-07-28"
	and website_pageviews.pageview_url in ("/home","/lander-1")	;

-- step 2 - conversion funnel w.r.t. session IDs
create temporary table sonu
select 
	sessions,
    case when url = "/products" then 1 else null end as products,
    case when url = "/the-original-mr-fuzzy" then 1 else null end as fuzzy,
    case when url = "/cart" then 1 else null end as cart,
    case when url = "/shipping" then 1 else null end as shipping,
    case when url = "/billing" then 1 else null end as billing,
    case when url = "/thank-you-for-your-order" then 1 else null end as thankyou
from 
(select 
	website_sessions.website_session_id as sessions,
    website_pageviews.pageview_url as url
from website_pageviews
	left join website_sessions
    on website_pageviews.website_session_id = website_sessions.website_session_id
where website_pageviews.created_at between "2012-06-19" and "2012-07-28") as result;

create temporary table kavtya
select 
	sessions,
    max(products) as products,
    max(fuzzy) as fuzzy,
    max(cart) as cart,
    max(shipping) as shipping,
    max(billing) as billing,
    max(thankyou) as thankyou
from sonu
group by 1;
    
-- step 3 = merging 2 table kaustubh with kavtya;
select 	
	kaustubh.url,
    count(kaustubh.sessions),
    count(kavtya.products),
    count(kavtya.fuzzy),
    count(kavtya.cart),
    count(kavtya.shipping),
    count(kavtya.billing),
    count(kavtya.thankyou)
from kaustubh
	left join kavtya
    on kaustubh.sessions = kavtya.sessions
group by 1;

-- Q6) Estimating revenues for gsearch lander test("2012-06-19" and "2012-07-28")
create temporary table revenue
select
	order_id,
    website_session_id,
    items_purchased*price_usd as Revenue
from orders;

create temporary table sessions
select 
	website_sessions.website_session_id,
    created_at,
    utm_source,
    utm_campaign
from website_sessions
where created_at between "2012-06-19" and "2012-07-28"
	and utm_source = "gsearch"
   and utm_campaign = "nonbrand";
	
select
    sessions.utm_source,
    sessions.utm_campaign,
    sum(revenue.revenue)
from sessions
	left join revenue
	on sessions.website_session_id = revenue.website_session_id;