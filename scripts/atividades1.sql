select od.order_id idpedido, od.quantity quantidade, p.product_name produto, 
od.unit_price preco_pedido, p.unit_price preco_tabela, 
p.unit_price - od.unit_price diferenca, od.discount
from order_details od , products p
where od.unit_price < p.unit_price 
and od.product_id = p.product_id
order by 6 desc