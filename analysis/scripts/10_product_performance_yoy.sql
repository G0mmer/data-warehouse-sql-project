/*
--------------------------------------------------------------------------------
product_performance_yoy
purpose:
    - compares product sales to annual averages
    - calculates year-over-year (yoy) growth or decline
    - flags products as "above avg", "increase yoy", etc.
--------------------------------------------------------------------------------
*/

--products performence to avg sales and last year avg
with cte as(
    select 
        p.product_name,
        datetrunc(month,s.order_date) as year_and_month,
        s.sales_amount,
        sum(s.sales_amount) over (partition by p.product_name,datetrunc(month,s.order_date) order by s.order_date) as sales,
        sum(s.sales_amount) over (partition by p.product_name,year(s.order_date) ) as sales_an
    from gold.fact_sales s
    left join gold.dim_products p
    on s.product_key=p.product_key
    where s.order_date is not null
)

select 
    cte.product_name,
    cte.year_and_month,
    max(cte.sales) as sales,
    max(cte.sales_an) as anual_sales,
    cast(1.00*max(cte.sales)/max(cte.sales_an) as decimal(9,2)) as percent_total_anual_product_sales
from cte
group by cte.product_name, cte.year_and_month
order by cte.product_name, cte.year_and_month;

--avg analyses and yoy flagging
with yearly_product_sales as(
    select
        year(s.order_date) as order_year,
        p.product_name,
        sum(s.sales_amount) as current_total
    from gold.fact_sales s
    left join gold.dim_products p
    on s.product_key=p.product_key
    where s.order_date is not null 
    group by 
        year(s.order_date),
        p.product_name
    )

select 
    a.product_name,
    a.current_sales,
    a.avg_sales,
    a.diff_avg,
    case 
        when a.diff_avg>0 then 'Above avg'
        when a.diff_avg<0 then 'Below avg'
        else 'Avg' end 
    as avg_flag,
    isnull(a.py_sales,0) as py_sales,
    isnull(a.py_diff,0) as py_diff,
    case 
        when a.py_diff>0 then 'Increase yoy'
        when a.py_diff<0 then 'Decrese yoy'
        when a.py_diff is null then 'First year'
        else 'No change yoy' end
    as yoy_flag

from (
    select 
        ys.product_name,
        ys.order_year,
        ys.current_total as current_sales,
        avg(ys.current_total) over (partition by ys.product_name) as avg_sales, 
        ys.current_total-avg(ys.current_total) over (partition by ys.product_name) as diff_avg,
        lag(ys.current_total) over (partition by product_name order by ys.order_year) as py_sales,
            ys.current_total - lag(ys.current_total) over (partition by product_name order by ys.order_year) as py_diff
    from yearly_product_sales ys
    )a
order by 
        a.product_name,
        a.order_year;