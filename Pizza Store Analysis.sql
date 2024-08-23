USE pizaa_store
#Selecting tables form the schemas
SELECT *
FROM pizaa_store.orders;
SELECT *
FROM pizaa_store.order_details;
SELECT *
FROM pizaa_store.pizzas;
SELECT *
FROM pizaa_store.pizza_types;
#-----------------------------
-- retriving total number of orders
select count(distinct order_id) as 'total if orders'
from orders;

-- total revenue
select order_details.order_id, order_details.quantity, pizzas.price
from order_details
join pizzas
on pizzas.pizza_id = order_details.pizza_id
-- answer of total revenue
select sum(order_details.quantity* pizzas.price)
from order_details
join pizzas
on pizzas.pizza_id = order_details.pizza_id
-- rank the pizzas based on highst price

select distinct pizza_types.name as 'pizza_name', pizzas.price
from pizza_types 
join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
order by price desc;
-- highst one using cte and window function
with rank_cte as(
select  distinct pizza_types.name, pizzas.price
rank() over(order by price desc) as rnk
from pizza_types 
join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
)
select [pizza_name], price
from rank_cte where rnk=1
#---------------------------------------
-- rank pizza based on the most ordered sizes
select pizzas.size, count(distinct order_details.order_id) as 'no of orders' , sum(order_details.quantity) as 'total ordered quantity'
from pizzas 
join order_details
on pizzas.pizza_id = order_details.pizza_id
group by pizzas.size
#--------------------------------------------
-- ranking the most 5 ordered types of pizzas

select pizza_types.category, sum(quantity) as 'Total Quantity Ordered'
from order_details
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.category 
order by sum(quantity)  desc

# distributiiom of orders by day

select datepart(hour, time) as 'orders_by_hours', count(distinct order_id) as 'NO_of_order'
from orders
group by datepart(hour, time)
order by [NO_of_order];
-- finding category diatribution of pizzas
select category , count(pizza_type_id) as 'No_of_pizzas' 
from (pizza_types)
group by category
order by count(pizza_type_id) desc
-- average number of oreder pizza per day
with cte as(
select orders.date as 'date', sum(order_details.quantity) as 'total_quantity'
from orders
join order_details
on orders.order_id = order_details.order_id
group by orders.date
)
select avg([total_quantity])
from cte

-- Determine the top 3 most ordered pizza types based on revenue.

select top 3 pizza_types.name, sum(order_details.quantity*pizzas.price) as 'Revenue from pizza'
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.name
order by [Revenue from pizza] desc

-- precentage of oredered pizzas revenue
select pizza_types.category, 
concat(cast((sum(order_details.quantity*pizzas.price) /
(select sum(order_details.quantity*pizzas.price) 
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id 
))*100 as decimal(10,2)), '%')
as 'Revenue contribution from pizza'
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.category

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

with cte as (
select category, name, cast(sum(quantity*price) as decimal(10,2)) as Revenue
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by category, name
-- order by category, name, Revenue desc
)
, cte1 as (
select category, name, Revenue,
rank() over (partition by category order by Revenue desc) as rnk
from cte 
)
select category, name, Revenue
from cte1 
where rnk in (1,2,3)
order by category, name, Revenue

-- Analyze the cumulative revenue generated over time.
-- use of aggregate window function (to get the cumulative sum)
with cte as (
select date as 'Date', sum(quantity*price)  as Revenue
from order_details 
join orders on order_details.order_id = orders.order_id
join pizzas on pizzas.pizza_id = order_details.pizza_id
group by date
-- order by [Revenue] desc
)
select Date, Revenue, sum(Revenue) over (order by date) as 'Cumulative Sum'
from cte 
group by date, Revenue