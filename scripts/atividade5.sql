with result as (
  select  c.category_name categoria, DATE_PART(year, o.order_date) ano, 
  sum(od.unit_price * od.quantity - od.discount) total ,
  row_number() over (partition by ano order by ano,total desc) as res 
  from categories c
  inner join products p on (c.category_id = p.category_id)
  inner join order_details od on (p.product_id = od.product_id)
  inner join orders o on (o.order_id = od.order_id)
  group by categoria, ano
),
filtro as (
  select * from result where res <=5
)
  select categoria, ano, total from filtro