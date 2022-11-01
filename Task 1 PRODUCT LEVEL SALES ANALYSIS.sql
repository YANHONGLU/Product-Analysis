select year(created_at) as yr,
       month(created_at) as  mo,
       count(distinct order_id) as number_of_sales,
       sum(price_usd) as total_revenue,
       sum(price_usd-cogs_usd) as total_margin
from orders
where created_at<'2013-01-04'
group by 1,2;