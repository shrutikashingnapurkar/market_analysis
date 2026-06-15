use [market analysis];

----  What are the top 10 aisles with the highest number of products?
    SELECT TOP 10
        a.aisle,
        COUNT(p.product_id) AS total_product
    FROM products p
    JOIN aisles a
    ON p.aisle_id = a.aisle_id
    WHERE a.aisle IS NOT NULL
    AND a.aisle <> 'missing'
    GROUP BY a.aisle
    ORDER BY total_product DESC;

    -- How many unique departments are there in the dataset?
   select  count(distinct department) as total_departments
    from departments
    where department <> 'missing'
       and department is not null;

-- What is the distribution of products across departments?

select department,
count(product_id) as distribution_of_product
from departments  d join products p
on  d.department_id = p.department_id
where department <>'missing'
group by department
order by distribution_of_product desc;

---- What are the top 10 products with the highest reorder rates?
    select top 10
    p.product_name,
    ROUND(COUNT(case when op.reordered = 1  then 1 end ) *100
    / count(*),2)as reorder_rates
    from products p join order_products_train op
    on p.product_id = op.product_id 
    group by p.product_name
    HAVING COUNT(*) > 100
    order by reorder_rates desc;

---- How many unique users have placed orders in the dataset?
    select count(distinct user_id) as total_users
    from orders;

---- What is the average number of days between orders for each user?
     select distinct user_id,
     round(avg(days_since_prior_order),2) as avg_days_between_orders
     from orders
     WHERE days_since_prior_order IS NOT NULL 
     group by user_id
     order by avg_days_between_orders desc;

 ----What are the peak hours of order placement during the day?
     select order_hour_of_day,
     count(order_id) as total_order
     from orders
     group by order_hour_of_day
     order by total_order desc;

-----How does order volume vary by day of the week?
     select count(order_id) as total_order,
     order_dow 
     from orders
     group by order_dow 
     order by order_dow desc;

 ----What are the top 10 most ordered products?
     select  top 10 p.product_name,
     count(op.product_id) as total_orders
     from products p join order_products_train op
     on p.product_id = op.product_id
     group by product_name 
     order by total_orders desc;

-----how many users have placed orders in each department
     select d.department, 
     count(distinct o.user_id) as total_users
     from orders o join order_products_train op
     on o.order_id = op.order_id
     join products p
     on p.product_id = op.product_id
     join departments d
     on d.department_id = p.department_id
     group by department
     order by total_users desc;

----What is the average number of products per order?
  select avg(cast(product_count as decimal(10,2)))as avg_product_per_order
  from (
     select order_id,
     count(product_id) as product_count
     from order_products_train
     group by order_id) as order_count;

----What are the most reordered products in each department?
    select p.product_name, 
    d.department,
    COUNT(case when op.reordered = 1  then 1 end ) as count_reorder
    from products p join departments d
    on d.department_id = p.department_id
    join order_products_train op
    on op.product_id = p.product_id
    group by department,product_name
    order by count_reorder desc;
-----------------------------------------------------------
    WITH ProductReorders AS (
    SELECT
        d.department,
        p.product_name,
        COUNT(*) AS reorder_count,
        ROW_NUMBER() OVER (
            PARTITION BY d.department
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM order_products_train opt
    JOIN products p
        ON opt.product_id = p.product_id
    JOIN departments d
        ON p.department_id = d.department_id
    WHERE opt.reordered = 1
    GROUP BY d.department, p.product_name
)
SELECT
    department,
    product_name,
    reorder_count
FROM ProductReorders
WHERE rn = 1
ORDER BY department;

------How many products have been reordered more than once?

SELECT COUNT(*) AS products_reordered_more_than_once
FROM (
    SELECT
        product_id,
        COUNT(*) AS reorder_count
    FROM order_products_train
    WHERE reordered = 1
    GROUP BY product_id
    HAVING COUNT(*) > 1
) AS reordered_products;

-----What is the average number of products added to the cart per order?
select 
avg(cast(product_count as decimal(10,2)))as avg_product_per_order
from
(
select order_id,
count(*) as product_count
from order_products_train
group by order_id) as order_count;

------alternatives
select avg(cast(total_product as decimal(10,2))) as avg_product_per_order
from
(
select order_id,
max(add_to_cart_order) as total_product
from order_products_train
group by order_id) as order_count;

-------How does the number of orders vary by hour of the day?

select count(order_id) as no_of_orders,
order_hour_of_day
from orders
group by order_hour_of_day 
order by order_hour_of_day desc;

--What is the distribution of order sizes (number of products per order)?
with order_sizes as(
select 
     order_id,
     count(*) as product_per_orders
     from order_products_train
     group by order_id
    )
    select 
         product_per_orders,
         count(*) as number_orders
         from order_sizes
         group by product_per_orders
         order by product_per_orders;

-------What is the average reorder rate for products in each aisle?

     select 
           a.aisle,
           round(
           100.0 * sum(case when op.reordered = 1 then 1 else 0 end ) 
           / count(*) 
           , 2) as avg_reorder_rate
           from order_products_train as op
           join products as p
           on op.product_id = p.product_id
           join aisles as a
           on  a.aisle_id = p.aisle_id
           group by a.aisle
           order by avg_reorder_rate desc;

------------How does the average order size vary by day of the week?
   with order_sizes as 
       (
        select order_id,
        count(product_id) as count_products
        from order_products_train
        group by order_id
        )
        select 
             order_dow,
     ROUND(avg(cast(count_products as decimal(10,2))),2)as avg_order_size
            from order_sizes os
            join orders o
            on os.order_id = o.order_id
            group by order_dow
            order by order_dow;

----------What are the top 10 users with the highest number of orders?
          select top 10
          user_id, 
          count(order_id) as no_of_orders
          from orders
          group by user_id
          order by no_of_orders desc;

------How many products belong to each aisle and department?
      
SELECT
    d.department,
    a.aisle,
    COUNT(p.product_id) AS total_products
FROM products p JOIN aisles a
     ON p.aisle_id = a.aisle_id
     JOIN departments d
     ON p.department_id = d.department_id
WHERE a.aisle IS NOT NULL
    AND a.aisle <> 'missing'
    and department <> 'missing'
    and department is not null
GROUP BY
    d.department,
    a.aisle
ORDER BY
    total_products DESC;

------ Top Customers by Number of Orders
  select user_id,
  count(order_id) as no_of_orders
  from orders
  group by user_id
  order by no_of_orders desc;

-------Average Order Size
 with order_sizes as
 (
  select order_id,
  count(*) as product_per_order
  from order_products_train
  group by order_id
  
  ) 
  select 
  avg(cast(product_per_order as decimal(10,2))) as avg_order_size
      from order_sizes;

------Orders by Day of Week
    select 
         order_dow,
         count(order_id) as total_orders
         from orders
         group by order_dow
         order by order_dow;

  -----Orders by Hour of Day
  select 
        order_hour_of_day,
        count(order_id) as total_orders
        from orders
        group by  order_hour_of_day
        order by  order_hour_of_day;

--------Top 10 Most Ordered Products
      select  top 10
           p.product_name,
            count(op.order_id) as total_orders
       from  products p
       join order_products_train op
       on p.product_id = op.product_id
       group by p.product_name
       order by total_orders desc;

-------Top Reordered Products
        select  top 10
        product_name,
        count(reordered) as total_reorders
        from products p
        join order_products_train op
        on p.product_id = op.product_id
        where reordered = 1
        group by product_name
        order by total_reorders desc;

------Reorder Rate by Product
      select top 10 
       p.product_name,
       round(
       100.0*sum(case when reordered = 1 then 1 else 0 end)
       /count(*),
       2) as reorder_rate
        from products p
        join order_products_train op
        on p.product_id = op.product_id
        where reordered = 1
        group by product_name
        order by reorder_rate desc;

------Products per Department
     select d.department,
            count(product_name) as total_products
            from departments d join products p
            on d.department_id = p.department_id
            group by d.department
            order by total_products desc;

-----Average Reorder Rate by Aisle
    
    SELECT
    a.aisle,
    ROUND(
        100.0 * SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
      ) AS reorder_rate
   FROM order_products_train opt
   JOIN products p
   ON opt.product_id = p.product_id
   JOIN aisles a
    ON p.aisle_id = a.aisle_id
   GROUP BY a.aisle
   ORDER BY reorder_rate DESC;
 
 
-------Users with Highest Reorders
    select  top 10 
    user_id,
    count(reordered) as total_reordered
    from orders o join order_products_train op
    on o.order_id = op.order_id
    where reordered =1
    group by user_id
    order by total_reordered desc;

------Days Between Orders
select 
avg(days_since_prior_order) as avg_days_between_orders
from orders;













        









     




     














    
    


     




     





      










  




