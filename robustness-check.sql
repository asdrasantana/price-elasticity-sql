with olist as (
select
	date_trunc('month', od.order_purchase_timestamp) as month,
	oi.product_id,
	count(oi.order_id) as order_count,
	avg(oi.price) as avg_price
from olist_order_items_dataset as oi
inner join olist_orders_dataset as od
	on oi.order_id = od.order_id
group by
	oi.product_id,
	date_trunc('month', od.order_purchase_timestamp)
),
product as (
select
	p.product_id,
	coalesce(cn.product_category_name_english, 'other / uncategorized') as product_category_name_english
from olist_products_dataset as p
left join olist_category_name_translation as cn
	on p.product_category_name = cn.product_category_name
),
prev as (
select
	month,
	product_id,
	order_count,
	avg_price,
	lag(order_count) over
		(partition by product_id order by month) as previous_order_count,
	lag(avg_price) over
		(partition by product_id order by month) as previous_avg_price
from olist
),
percent as (
select
	p.month,
	p.product_id,
	pd.product_category_name_english as product,
	p.order_count,
	p.avg_price,
	p.previous_order_count,
	p.previous_avg_price,
	(p.order_count - nullif(p.previous_order_count, 0))/nullif(p.previous_order_count, 0) as percent_order_count,
	(p.avg_price - nullif(p.previous_avg_price, 0))/nullif(p.previous_avg_price, 0) as percent_avg_price
from prev as p
left join product as pd
	on p.product_id = pd.product_id
),
final_ped as (
select
	month,
	product,
	order_count,
	avg_price,
	previous_order_count,
	previous_avg_price,
	(percent_order_count)/ nullif(percent_avg_price, 0) as ped
from percent
where percent_order_count is not null
	and percent_avg_price is not null
	and abs(percent_avg_price) > 0.02
	and previous_order_count >= 10
)
select
	product,
	count(*) as n_observations,
	round(avg(ped)::numeric, 2) as avg_ped,
	round((percentile_cont(0.5) within group (order by ped))::numeric, 2) as median_ped,
	round(min(ped)::numeric, 2) as min_ped,
	round(max(ped)::numeric, 2) as max_ped,
	round(stddev(ped)::numeric, 2) as stddev_ped
from final_ped
group by product
having count(*) >= 5
order by abs(avg(ped)) desc
