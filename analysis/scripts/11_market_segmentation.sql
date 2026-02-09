/*
--------------------------------------------------------------------------------
market_segmentation
purpose:
    - calculates part-to-whole ratios (category share of total sales)
    - segments products into price buckets and cost ranges
    - segments customers into 'vip', 'regular', and 'new' clusters
--------------------------------------------------------------------------------
*/

--categories contribiution in total sales
declare @total_sales int =  (select sum(sales_amount) from gold.fact_sales);
    
select 
    p.category_name,
    sum(sales_amount) as sales_amount,
    @total_sales as total_sales,
    concat(cast(100.00*sum(s.sales_amount)/@total_sales as decimal(9,2)),'%') as sales_percent
from gold.fact_sales as s
left join gold.dim_products as p
on s.product_key = p.product_key
group by p.category_name
order by sales_percent;

--segment products into price ranges (buckets)
declare @bucket_number int = 6; 
declare @min_val int = (select min(price) from gold.fact_sales);
declare @max_val int = (select max(price) from gold.fact_sales);
declare @bucket_size decimal(10,2);

-- calculate size of one bucket
set @bucket_size = (@max_val - @min_val + 1.0) / @bucket_number;
with cte as(
    select
    p.product_name,
    price,
    floor((price - @min_val) / @bucket_size) + 1 as bucket_id
    from gold.dim_products p
    left join gold.fact_sales s
    on s.product_key=p.product_key
    where price is not null
)
select 
    bucket_id,
    avg(price) as avg_price_in_bucket
from cte
group by bucket_id
order by bucket_id;

--segment products into cost ranges
with cte as (
    select
        product_key,
        product_name,
        production_cost,
        case 
            when production_cost<100 then 'Below 100'
            when production_cost between 100 and 500 then 'Between 100 and 500'
            when production_cost between 501 and 1000 then 'Between 501 and 1000'
            else 'Above 1000' end
        as cost_range
    from gold.dim_products
)
select
    cost_range,
    count(distinct cte.product_key) as items_count,
    count(distinct s.product_key) as items_sold_count,
    avg(production_cost) as avg_production_cost,
    avg(s.sales_amount) as avg_sales_amount,
    avg(s.price) as avg_price,
    avg(s.sales_amount)- avg(production_cost)*avg(s.quantity) as avg_roi
from cte
left join gold.fact_sales s
on cte.product_key=s.product_key
group by cost_range;

--customers structure (vip/regular/new)
with cte as (
    select 
        s.customer_key,
        c.first_name,
        c.last_name,
        min(s.order_date) as first_purchase,
        max(s.order_date) as last_order,
        sum(s.sales_amount) as total_spent, 
        datediff(month, min(s.order_date),max(s.order_date)) as history,
        case 
            when datediff(month, min(s.order_date),max(s.order_date))>=12 and sum(s.sales_amount)>5000 then 'VIP'
            when datediff(month, min(s.order_date),max(s.order_date))>= 12 and sum(s.sales_amount)<= 5000 then 'Regular'
            else 'New' end
        as label_
    from gold.fact_sales s
    left join gold.dim_customers c
    on c.customer_key=s.customer_key
    group by
        s.customer_key,
        c.first_name,
        c.last_name
)
select
    label_,
    count(*) as customers_in_cluster,
    avg(history) avg_livespan_of_acc_in_months,
    avg(total_spent) avg_bill
from cte
group by label_;