#1 identify cart page views and sessions
create temporary table sessions_seeing_cart
select case when created_at <'2013-09-25' then 'A.Pre_Cross_Sell'
            when created_at >= '2013-09-25' then 'B.Post_Cross_Sell'
            else 'uh oh...check logic'
            end as time_period,
		website_session_id as cart_session_id,
        website_pageview_id as cart_pageview_id
from website_pageviews
where created_at between '2013-08-25' and '2013-10-25' and pageview_url='/cart';

#2 see which of cart sessions clicked through to the shipping page
create temporary table cart_sessions_seeing_another_page
select sessions_seeing_cart.time_period,
       sessions_seeing_cart.cart_session_id,
       min(website_pageviews.website_pageview_id) as pv_id_after_cart
from sessions_seeing_cart
left join website_pageviews
on website_pageviews.website_session_id=sessions_seeing_cart.cart_session_id
   and website_pageviews.website_pageview_id>sessions_seeing_cart.cart_pageview_id
group by 1,2
having min(website_pageviews.website_pageview_id) is not null;

create temporary table pre_post_sessions_orders
select time_period, cart_session_id, order_id, items_purchased,price_usd
from sessions_seeing_cart
inner join orders
on sessions_seeing_cart.cart_session_id=orders.website_session_id;

#3 find orders associated with cart sessions
create temporary table full_data
select sessions_seeing_cart.time_period,
       sessions_seeing_cart.cart_session_id,
       case when cart_sessions_seeing_another_page.cart_session_id is null then 0 else 1 end as clicked_to_another_page,
       case when pre_post_sessions_orders.order_id is null then 0 else 1 end as placed_order,
       pre_post_sessions_orders.items_purchased,
       pre_post_sessions_orders.price_usd
from sessions_seeing_cart
left join  cart_sessions_seeing_another_page
on sessions_seeing_cart.cart_session_id=cart_sessions_seeing_another_page.cart_session_id
left join pre_post_sessions_orders
on sessions_seeing_cart.cart_session_id=pre_post_sessions_orders.cart_session_id
order by 2;
#4 summarize
select time_period,
       count(distinct cart_session_id) as cart_sessions,
       sum(clicked_to_another_page) as clickthroughts,
       sum(clicked_to_another_page) /count(distinct cart_session_id) as cart_ctr,
       sum(items_purchased)/sum(placed_order) as products_per_order,
       sum(price_usd)/sum(placed_order) as aov,
       sum(price_usd)/count(distinct cart_session_id) as rev_per_cart_session
from full_data
group by 1;