select case when website_sessions.created_at<'2013-12-12' then 'A.Pre_Birthday-Bear'
            when website_sessions.created_at<'2013-12-12' then 'A.Post_Birthday-Bear'
            else 'uh oh...check logic'
            end as time_period,
		count(distinct website_sessions.website_session_id) as sessions,
        count(distinct orders.order_id) as orders,
        count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate,
        sum(orders.price_usd) as total_revenue,
        sum(orders.items_purchased) as total_products_sold,
        sum(orders.price_usd)/count(distinct orders.order_id) as average_order_value,
        sum(orders.items_purchased)/count(distinct orders.order_id) as products_per_value,
        sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session
from website_sessions
left join orders
on  orders.website_session_id=website_sessions.website_session_id
where website_sessions.created_at between '2013-11-12' and '2014-01-12'
group by 1;