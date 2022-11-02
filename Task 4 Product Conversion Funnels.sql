#1 select pageviews
create temporary table sessions_seeing_product_pages
select website_session_id,
       website_pageview_id,
	   pageview_url as product_page_seen
from website_pageviews
where created_at < '2013-04-10'
      and created_at>'2013-01-06'
      and pageview_url in ('/the-original-mr-fuzzy','/the-forever-love-bear');
      
#2 find  right pageview_urls to build funnels
select distinct website_pageviews.pageview_url
from sessions_seeing_product_pages
left join website_pageviews
on website_pageviews.website_session_id=sessions_seeing_product_pages.website_session_id
   and website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id;

#3 pull all pageviews and identify the funnel steps
create temporary table pageview_level
select sessions_seeing_product_pages.website_session_id,
       sessions_seeing_product_pages.product_page_seen,
       case when pageview_url='/cart' then 1 else 0 end as cart_page,
       case when pageview_url='/shipping' then 1 else 0 end as shipping_page,
       case when pageview_url='/billing-2' then 1 else 0 end as billing_page,
       case when pageview_url='/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from sessions_seeing_product_pages
left join website_pageviews
on website_pageviews.website_session_id=sessions_seeing_product_pages.website_session_id
   and website_pageviews.website_pageview_id>sessions_seeing_product_pages.website_pageview_id
order by 1, website_pageviews.created_at;

create temporary table session_product_level_made_it_flags
select website_session_id,
       case when product_page_seen='/the-original-mr-fuzzy' then 'mrfuzzy'
            when product_page_seen='/the-forever-love-bear' then 'lovebear'
            else 'uh oh...check logic'
            end as product_seen,
		max(cart_page) as cart_made_it,
        max(shipping_page) as shipping_made_it,
        max(billing_page) as billing_made_it,
        max(thankyou_page) as thankyou_made_it
from pageview_level
group by 1,2;

#4 create session-level conversion funnel view
select product_seen,
       count(distinct website_session_id) as sessions,
       count(distinct case when cart_made_it=1 then website_session_id else null end) as to_cart,
       count(distinct case when shipping_made_it=1 then website_session_id else null end) as to_shipping,
       count(distinct case when billing_made_it=1 then website_session_id else null end) as to_billing,
       count(distinct case when thankyou_made_it=1 then website_session_id else null end) as to_thankyou
from session_product_level_made_it_flags
group by 1;

#5 summarize
select product_seen,
       count(distinct case when cart_made_it=1 then website_session_id else null end)/count(distinct website_session_id) as product_page_click_rt,
       count(distinct case when shipping_made_it=1 then website_session_id else null end)/count(distinct case when cart_made_it=1 then website_session_id else null end) as cart_click_rt,
       count(distinct case when billing_made_it=1 then website_session_id else null end)/count(distinct case when shipping_made_it=1 then website_session_id else null end) as shipping_click_rt,
       count(distinct case when thankyou_made_it=1 then website_session_id else null end)/count(distinct case when billing_made_it=1 then website_session_id else null end) as billing_click_rt
from session_product_level_made_it_flags
group by 1;