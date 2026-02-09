/*
--------------------------------------------------------------------------------
customer_anomalies
purpose:
    - complex filtering to find specific customer outliers
    - identifies the top 10 revenue generators
    - identifies the 3 customers with the lowest order volume
--------------------------------------------------------------------------------
*/

with cte as(
    select
        customer_id,    
        first_name,
        last_name,
        max(orders_placed) as orders_placed,
        max(rev) as rev
    from (
        select
            c.customer_id,
            c.first_name,
            c.last_name,
            count(*) over (partition by c.customer_id,c.first_name,c.last_name order by s.order_number) as orders_placed,
            sum(s.sales_amount) over (partition by c.customer_id,c.first_name,c.last_name order by s.order_number) as rev
        from gold.fact_sales s
        left join gold.dim_customers c
        on s.customer_key=c.customer_key)a
        group by 
            customer_id,
            first_name,
            last_name
        )
select
    case
        when orders_rank<=3 then 'no_' + cast(orders_rank as nvarchar(50)) +' customer with fewest orders'
        else 'no_'+cast(rev_rank as nvarchar(50)) +' customer with bigest revenue' 
        end as description, 
    customer_id,
    first_name,
    last_name,
    orders_placed,
    rev
    from (
    select 
        customer_id,
        first_name,
        last_name,
        orders_placed,
        rev,
        rank() over (order by orders_placed) as orders_rank,
        rank() over (order by rev desc) as rev_rank
    from cte 
    )a
    where a.orders_rank<=3 or a.rev_rank<=10
    order by rev desc;