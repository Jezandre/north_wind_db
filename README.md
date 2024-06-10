# Projeto de Engenharia de dados - NorthWinddb

 ## Introdução

 O presente artigo é referente a um dos projetos disponíveis no curso do [Fernando Amaral](https://www.linkedin.com/in/fernando-amaral/) no curso [Formação Engenharia de Dados: Domine Big Data!](https://www.udemy.com/course/engenheiro-de-dados/learn/lecture/15289778?start=0) disponível na Udemy. O projeto consiste na criação de um pipeline utilizando ferramentas da nuvem AWS e responder a cinco perguntas de negócio utilizando SQL.

 Para isso usaremos as seguintes ferramentas:

 - Um bucket na AWS S3
 - Um banco de dados no AWS Redshift
 - linguagem SQL para criar as tabelas, inserir as informações e criar as consultas
 - Visualizar as informações em um dataViz

O projeto é bem simples, porém uma dica que eu recebi e que gosto de passar a frente é sempre escreva sobre o que aprendeu. Se possível escreva a mão. Isso ajuda a manter os conceitos aprendidos vivos.

![image](https://github.com/Jezandre/north_wind_db/assets/63671761/1f4e60e5-6822-400e-9c79-17656339e7cf)


## Materiais

Os materiais utilizados foram todos disponibilizados no curso. Mas basicamente faremos um estudo sobre informações de vendas e produtos de um conjunto de dados salvos no CSV chamado Northwinddd. Os materiais se encontram disponíveis nesse repositório caso tenham curiosiadade de aprender um pouco e se desenvolver. As perguntas que iremos responder serão as seguintes:

1. Temos realizado vendas com valor abaixo do preço de tabela?
2. Como está perfomance dos vendedores em relaçao ao ano anterior?
3. Quais os produtos mais caros?
4. Avaliar a diferença de perfomance dos produtos por fornecedor nos ultimos dois anos
5. Quais os 5 produtos mais venderam em cada ano?

Essas perguntas nos permitirão abordar vários conceitos tanto de engenharia quanto em análise.

O esquema a seguir será o que nos basearemos para resolver cada questão.

![Eschema banco de dados](https://github.com/Jezandre/north_wind_db/assets/63671761/7ca0f3d4-1e34-4622-802e-0d578dc8d6e5)

O fluxo de dados seguirá da seguinte forma:

os dados são obtidos atrvés de arquivos cvs salvos dentro de um bucket S3. Através de SQL, os dados são inseridos num banco de dados no redshift e a partir daí elaboramos as consultas sql que podem ser enviadas para um dataviz.

![Untitled (7)](https://github.com/Jezandre/north_wind_db/assets/63671761/8b761ac3-b67e-44c7-8e39-ed300649a326)

Vale ressaltar que os serviços da AWS costumam ter algumas cobrança, então fique atento e consulte as documentações
###Importando dados para um bucket S3

O primeiro passo em todo o processo é criar um bucket S3. Para isso é necessário utilizar um nome único para seu bucket. Dentro deste bucket criamos uma pasta e utilizei a função para importar para importar os arquivos CSV.
Importante:

- Anote a região em que o bucket foi criado.

###Criar um instâcia no Redshift

Para importar os dados no redshift, eu não segui todos os passos que o Fernando Amaral descreve no curso. Unicamente por causa dos custos, a Amazon oferece um serviço serveless que te da 300 dolares para consumir durante um certo período. Eu fiquei na duvida se isso incluiria o serviço de cluster, por isso só criei a máquina serverless e fiz o passo a passo indicado para criação dos bancos de dados e das tabelas. Então nesse caso eu vou utilizar uma gambiarra. Na verdade é basicamente utilizar python e inserir os dados em um banco MySql na minha máquina para apresentar os dados no dataViz, mas finjam que não leram isso, e caso queiram criem um cluster. Dessa maneira é possível conectar diretamente no redshift da amazon. Falo que é caro pois utilizei o freetier em uns tres dias e consumiu cerca de 70 dolares...

O primeiro passo é criar o banco de dados. Para isso basta utilizar o seguinte comando no editor do Redshift:

```SQL
CREATE DATABASE engDados;
```
Abaixo estão todos os comando para criar as tabelas com as colunas e esquema, acredito que esta parte seja bem simples então apenas copiem e colem.

```SQL
CREATE TABLE categories (
    category_id smallint NOT NULL,
    category_name varchar(15) NOT NULL,
    description VARCHAR(max)
);
CREATE TABLE customers (
    customer_id varchar(40) NOT NULL,
    company_name varchar(40) NOT NULL,
    contact_name varchar(30),
    contact_title varchar(30),
    address varchar(60),
    city varchar(15),
    region varchar(15),
    postal_code varchar(10),
    country varchar(15),
    phone varchar(24)
);
CREATE TABLE employees (
    employee_id smallint NOT NULL,
    last_name varchar(20) NOT NULL,
    first_name varchar(10) NOT NULL,
    title varchar(30),
    title_of_courtesy varchar(25),
    birth_date date,
    hire_date date,
    address varchar(60),
    city varchar(15),
    region varchar(15),
    postal_code varchar(10),
    country varchar(15),
    home_phone varchar(24),
    extension varchar(4),
    notes varchar(max),
    reports_to smallint,
    photo_path varchar(255),
	salary real
);
CREATE TABLE order_details (
    order_id smallint NOT NULL,
    product_id smallint NOT NULL,
    unit_price real NOT NULL,
    quantity smallint NOT NULL,
    discount real NOT NULL
);

CREATE TABLE orders (
    order_id smallint NOT NULL,
    customer_id bpchar,
    employee_id smallint,
    order_date date,
    required_date date,
    shipped_date date,
    ship_via smallint,
    freight real,
    ship_name varchar(40),
    ship_address varchar(60),
    ship_city varchar(15),
    ship_region varchar(15),
    ship_postal_code varchar(10),
    ship_country varchar(15)
);
CREATE TABLE products (
    product_id smallint NOT NULL,
    product_name varchar(40) NOT NULL,
    supplier_id smallint,
    category_id smallint,
    quantity_per_unit varchar(20),
    unit_price real,
    units_in_stock smallint,
    units_on_order smallint,
    reorder_level smallint,
    discontinued integer NOT NULL
);

CREATE TABLE shippers (
    shipper_id smallint NOT NULL,
    company_name varchar(40) NOT NULL,
    phone varchar(24)
);
CREATE TABLE suppliers (
    supplier_id smallint NOT NULL,
    company_name varchar(40) NOT NULL,
    contact_name varchar(30),
    contact_title varchar(30),
    address varchar(60),
    city varchar(15),
    region varchar(15),
    postal_code varchar(10),
    country varchar(15),
    phone varchar(24),
    fax varchar(24),
    homepage varchar(max)
);

```

Tabelas criadas, hora de popular utilizando a função copy do Redshift. Essa função é bem interessante, pelo menos pra mim. A partir dela é possível localizar um arquivo no bucket S3 e importar os dados. 

```SQL

copy <<nome_tabela>>
from 's3://<<nome_do_bucket>>/<<nome_do_arquivo.csv>>' 
CREDENTIALS 'aws_access_key_id=<<sua_id>>;aws_secret_access_key=<<sua_chave>>' 
delimiter ';' 
region '<<regiao_do_bucket>>'
IGNOREHEADER 1
DATEFORMAT AS 'YYYY-MM-DD HH:MI:SS'
removequotes;
```
Como podem ver, o comando identifica a tabela que será alimentada com o comando copy e obtém os arquivos do endereço do bucket que você quer passar. 
Um detalhe importante é que você precisará das credencias IAM você pode criá-las ou obter seguindo o passo a passo a seguir:
  
  1. Faça login no Console de Gerenciamento da AWS em https://aws.amazon.com/console/.
  2. No canto superior direito, clique na sua conta e selecione "Minhas Credenciais de Segurança" no menu suspenso.
  3. Clique em "Credenciais de acesso (chave de acesso ID e chave secreta)".
  4. Se solicitado, insira sua senha.
  5. Aqui você pode visualizar suas chaves de acesso existentes ou criar uma nova chave de acesso clicando em "Criar nova chave de acesso".
  6. Se você criar uma nova chave de acesso, será fornecida a chave de acesso (Access Key ID) e a chave secreta (Secret Access Key). É importante salvar essas informações em um local seguro, pois elas serão necessárias para autenticar com a AWS em aplicativos ou ferramentas de linha de comando.
  7. Depois de salvar suas chaves de acesso, você pode usá-las para autenticar solicitações à AWS em aplicativos, scripts ou outras ferramentas que interagem com os serviços da AWS. Certifique-se de seguir as melhores práticas de segurança, como não armazenar suas chaves de acesso em texto simples e restringir as permissões apenas ao que é necessário para suas operações.

Tabelas criadas e alimentadas, o próximo passo é resolver os problemas de negócio.


### 1. Temos realizado vendas com valor abaixo do preço de tabela?

Esta questão ela quer saber quais os produtos foram vendidos abaixo do preço, ou seja quais produtos tiveram descontos na sua venda. Para isso precisaremos das colunas que trazem os detalhes do produto da tabela produtos, preço e quantidade da tabela detalhes de pedido, e basicamente avaliar se há diferenças entre o preço unitário e o preço vendido. Para isso utilizei a seguinte query no Redshift:


```SQL
SELECT
    p.product_name,
    od.order_id,
    od.product_id,
    p.unit_price,
    od.unit_price,
    od.quantity,
    od.discount,
    (p.unit_price - od.unit_price) as diference
FROM products AS p
LEFT JOIN order_details AS od ON p.product_id = od.product_id
WHERE p.unit_price - od.unit_price <> 0
ORDER BY diference DESC
;
```

- p.product_name: Seleciona o nome do produto da tabela products, que será exibido na consulta.
- od.order_id: Seleciona o ID do pedido da tabela order_details.
- od.product_id: Seleciona o ID do produto da tabela order_details.
- p.unit_price: Seleciona o preço unitário do produto da tabela products.
- od.unit_price: Seleciona o preço unitário do produto do pedido da tabela order_details.
- od.quantity: Seleciona a quantidade do produto do pedido da tabela order_details.
- od.discount: Seleciona o desconto aplicado ao produto do pedido da tabela order_details.
- (p.unit_price - od.unit_price) as diference: Calcula a diferença entre o preço unitário do produto e o preço unitário do pedido e dá a essa diferença o alias "difference".
- LEFT JOIN order_details AS od ON p.product_id = od.product_id: Realiza uma junção esquerda entre as tabelas products e order_details com base no ID do produto. Isso significa que todas as linhas da tabela products serão incluídas na consulta, mesmo se não houver correspondência na tabela order_details.
- WHERE p.unit_price - od.unit_price <> 0: Filtra os resultados para mostrar apenas as linhas onde há uma diferença entre o preço unitário do produto e o preço unitário do pedido.
- ORDER BY diference DESC: Ordena os resultados pela diferença em ordem decrescente, ou seja, da maior diferença para a menor.

![image](https://github.com/Jezandre/north_wind_db/assets/63671761/3f738e15-a92a-4e08-a9f3-0c63ff88b9cc)


### 2. Como está perfomance dos vendedores em relaçao ao ano anterior?

Neste caso o objetivo é avaliarmos a perfomance do vendedores em realação ao ano anterior. Como essa base não é deste ano parti do pré-suposto que o ano anterior seria o ano máximo menos um. E para essa análise precisaremos trazer dados das tabelas: vendas, vendedores e detalhes de venda agrupando o valor total pelo nome do vendedor e filtrando pelo ano anterior.

```SQL
WITH ANO_ATUAL AS (SELECT EXTRACT(YEAR FROM max(order_date)) from orders)
SELECT 
    (e.first_name ||' '|| e.last_name) AS Name,
    to_char(SUM(od.unit_price*od.quantity - od.discount), 'FMR$999,999,999,999.99') AS ValorTotal,
    COUNT(od.order_id) AS quantidade_total
FROM orders AS o
INNER JOIN employees AS e ON e.employee_id = o.employee_id
INNER JOIN order_details AS od ON od.order_id = o.order_id
WHERE EXTRACT(YEAR FROM order_date) = (SELECT * FROM ANO_ATUAL)-1
GROUP BY 
    e.first_name,
    e.last_name
ORDER BY SUM(od.unit_price*od.quantity - od.discount)
```
- WITH ANO_ATUAL AS (SELECT EXTRACT(YEAR FROM max(order_date)) from orders): Define uma expressão de tabela comum (Common Table Expression - CTE) chamada ANO_ATUAL, que calcula o ano atual baseado na data máxima presente na coluna order_date da tabela orders.
- SELECT: Indica que estamos selecionando dados de uma tabela.(e.first_name ||' '|| e.last_name) AS Name: Concatena o primeiro nome e o último nome do funcionário da tabela employees e os renomeia como Name.
to_char(SUM(od.unit_price*od.quantity - od.discount), 'FMR$999,999,999,999.99') AS ValorTotal: Calcula o total de vendas (preço unitário multiplicado pela quantidade menos o desconto) para cada funcionário e formata o resultado como uma string no formato monetário especificado ('FMR$999,999,999,999.99').
- COUNT(od.order_id) AS quantidade_total: Conta o número total de pedidos para cada funcionário.
- FROM orders AS o: Especifica que estamos selecionando dados da tabela orders e a abrevia como o.
- INNER JOIN employees AS e ON e.employee_id = o.employee_id: Realiza uma junção interna entre as tabelas employees e orders com base no ID do funcionário.
- INNER JOIN order_details AS od ON od.order_id = o.order_id: Realiza uma junção interna entre as tabelas order_details e orders com base no ID do pedido.
- WHERE EXTRACT(YEAR FROM order_date) = (SELECT * FROM ANO_ATUAL)-1: Filtra os resultados para mostrar apenas os pedidos feitos no ano anterior ao ano atual.
- GROUP BY e.first_name, e.last_name: Agrupa os resultados pelo primeiro nome e pelo último nome do funcionário.
- ORDER BY SUM(od.unit_price*od.quantity - od.discount): Ordena os resultados pelo total de vendas em ordem decrescente.

![image](https://github.com/Jezandre/north_wind_db/assets/63671761/cb829fad-c3c6-4630-a097-c4d69f830ab7)


### 3. Quais os 10 produtos mais caros?

É uma questão bem simples o objetivo aqui é apenas determinar quais os 10 produtos mais caros que são vendidos então uma query bem curtinha apenas utilizando o order by.

```SQL
SELECT product_name, unit_price FROM products
ORDER BY unit_price DESC
LIMIT 10
```

- product_name: Seleciona o nome do produto da tabela products.
- unit_price: Seleciona o preço unitário do produto da tabela products.
- FROM products: Especifica que estamos selecionando dados da tabela products.
- ORDER BY unit_price DESC: Ordena os resultados pela coluna unit_price em ordem decrescente, ou seja, do maior preço unitário para o menor.
- LIMIT 10: Limita o número de linhas retornadas para 10. A consulta irá retornar apenas os 10 produtos com os preços unitários mais altos.

![image](https://github.com/Jezandre/north_wind_db/assets/63671761/9c98f34b-c51c-4e74-9be1-a28e08017dfc)

### 4. Avaliar a diferença de perfomance dos produtos por fornecedor nos ultimos dois anos

Una questão um pouco mais desafiadora. Neste caso precisamos mostrar na mesma tabela a performance dos fornecedores nos dois anos anteriores, então precisaremos subtrair o ano atual -1 e -2 conforme foi feito na questão anterior. Para isso utilizaremos CTE para selecionarmos os valores referentes a cada ano em colunas. Além disso para compararmos o desempenho vamos avliar percentualmente e a diferença entre os valores vendidos.

```SQL
WITH 
    ANO_ATUAL AS 
    (SELECT EXTRACT(YEAR FROM max(order_date)) from orders),
    VENDAS_ANO_ANTERIOR AS 
    (SELECT
        s.supplier_id    
        ,SUM(od.unit_price*od.quantity) as total    
    FROM suppliers AS s
    INNER JOIN products AS p ON p.supplier_id = s.supplier_id
    INNER JOIN order_details AS od ON od.product_id = p.product_id
    INNER JOIN orders AS o ON o.order_id = od.order_id
    WHERE EXTRACT(YEAR FROM order_date) = (SELECT * FROM ANO_ATUAL) - 1
    GROUP BY 
        s.supplier_id),
    VENDAS_2ANO_ANTERIOR AS 
    (SELECT
        s.supplier_id    
        ,SUM(od.unit_price*od.quantity) as total
        
    FROM suppliers AS s
    INNER JOIN products AS p ON p.supplier_id = s.supplier_id
    INNER JOIN order_details AS od ON od.product_id = p.product_id
    INNER JOIN orders AS o ON o.order_id = od.order_id
    WHERE EXTRACT(YEAR FROM order_date) = (SELECT * FROM ANO_ATUAL) - 2
    GROUP BY 
        s.supplier_id)
SELECT 
    s.company_name
    ,ROUND(a.total, 2) as vendas_ano_2021
    ,ROUND(b.total, 2) as vendas_ano_2020
    ,ROUND((a.total - b.total), 2) as diferenca
    ,ROUND(((a.total - b.total) / b.total) * 100, 2) as percentual
FROM suppliers AS s
INNER JOIN VENDAS_ANO_ANTERIOR AS a ON a.supplier_id = s.supplier_id
INNER JOIN VENDAS_2ANO_ANTERIOR AS b ON b.supplier_id = s.supplier_id
ORDER BY ((a.total - b.total) / b.total) * 100 DESC;

```

- WITH ANO_ATUAL AS (SELECT EXTRACT(YEAR FROM max(order_date)) from orders): Define uma CTE chamada ANO_ATUAL, que calcula o ano atual baseado na data máxima presente na coluna order_date da tabela orders.
- VENDAS_ANO_ANTERIOR AS (...): Define uma CTE chamada VENDAS_ANO_ANTERIOR, que calcula as vendas de cada fornecedor no ano anterior ao ano atual.
- VENDAS_2ANO_ANTERIOR AS (...): Define uma CTE chamada VENDAS_2ANO_ANTERIOR, que calcula as vendas de cada fornecedor no ano anterior ao ano anterior ao ano atual.
- SELECT (...): Seleciona os dados dos fornecedores, as vendas do ano atual, as vendas do ano anterior, calcula a diferença e o percentual de mudança entre essas vendas.
- INNER JOIN VENDAS_ANO_ANTERIOR AS a ON a.supplier_id = s.supplier_id: Junta os resultados da CTE VENDAS_ANO_ANTERIOR com os dados dos fornecedores com base no ID do fornecedor.
- INNER JOIN VENDAS_2ANO_ANTERIOR AS b ON b.supplier_id = s.supplier_id: Junta os resultados da CTE VENDAS_2ANO_ANTERIOR com os dados dos fornecedores com base no ID do fornecedor.
- ORDER BY ((a.total - b.total) / b.total) * 100 DESC: Ordena os resultados pela mudança percentual nas vendas em ordem decrescente.

![image](https://github.com/Jezandre/north_wind_db/assets/63671761/62e8073a-e9ce-49e9-9ed2-17549cd54833)


### 5. Quais os 5 produtos mais venderam em cada ano?

Esse certamente é o mais desafiador, pois tive que utilizar uma função de janela. Essa era uma função um pouco desconhecida pra mim, mas como poderão ver, é uma função bem útil em diversos contextos. Basicmanete o que ela faz é criar uma CTE e quebrar a tabela por ano de maneira a identificar os top itens com maior valor de venda no no ano. Ela ranqueia e no fim filtramos o top 5.

```SQL
WITH  RESULTADO AS
    (SELECT
        c.category_name
        ,SUM(od.unit_price*od.quantity-od.discount) AS total
        ,EXTRACT(YEAR FROM o.order_date) AS ano
        ,row_number() over (PARTITION BY ano ORDER BY ano, total DESC) AS number_colocation
    FROM categories AS c
    INNER JOIN products AS p ON p.category_id = c.category_id
    INNER JOIN order_details AS od ON od.product_id = p.product_id
    INNER JOIN orders AS o ON o.order_id = od.order_id
    GROUP BY 
        c.category_name,
        ano
    ORDER BY
        ano,
        total desc),
    FILTRO AS
        (SELECT * FROM RESULTADO WHERE number_colocation <= 5)
SELECT 
    category_name,
    ano,
    CAST(total AS DECIMAL(10, 2)) AS total    
    FROM FILTRO!
```

- WITH RESULTADO AS (...): Define uma expressão de tabela comum (CTE) chamada RESULTADO, que calcula a receita total para cada categoria de produto em cada ano, além de atribuir um número de classificação para cada categoria com base na sua receita. A função row_number() é usada para isso.
- SELECT ... FROM categories AS c INNER JOIN ...: Esta parte da consulta seleciona os dados das tabelas categories, products, order_details e orders, unindo-as conforme necessário para calcular a receita total por categoria em cada ano.
- GROUP BY c.category_name, ano: Agrupa os resultados pelo nome da categoria e pelo ano.
- ORDER BY ano, total DESC: Ordena os resultados pelo ano e pela receita total de forma decrescente.
- FILTRO AS (...): Define uma segunda CTE chamada FILTRO, que filtra os resultados para incluir apenas as cinco principais categorias de produtos em cada ano, com base no número de classificação calculado na CTE RESULTADO.
- SELECT category_name, ano, CAST(total AS DECIMAL(10, 2)) AS total FROM FILTRO: Finalmente, esta parte da consulta seleciona os dados das cinco principais categorias de produtos em cada ano, convertendo a receita total para um formato decimal com duas casas decimais.

### Visualização de dados

Desta maneira temos todas as querys necessárias para criarmos nossas visualizações. Irei utilizar o Google stutio para que possamos visaulizar gráficamente os dados que demonstramos via query.

Para a elaboração do dashboard, não utilizei a conexão direta com a aws para evitar custos desnecessário. Então utilizei a seguinte função python para inserir os dados dentro de um banco mysql que tenho na minha máquina e adaptei as querys para o mysql. Dessa maneira consegui trazer as visualizações sem muitos problemas.

Basicamente esta função utiliza a biblioteca SQLaclchemy e de acordo com os parametros que eu informar os dados serão inseridos no banco sem muito esforço.

```Python

class InserirDados:
from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.sql import select

    def inserirDadosMysql(df, tabela, comando):

        # Conexão bd 
        usuario = <<Usiario do banco de dados>>
        senha = <<Senha>>
        host = <<host>> 
        nome_do_banco = <<nome do banco de dados>>

        # Configurando Engine do MySQL
        engine = create_engine(f'mysql+mysqlconnector://{usuario}:{senha}@{host}/{nome_do_banco}')        

        # Comando criar tabela, atualizar e inserir registros na tabela
        df.to_sql(name=tabela, con=engine, if_exists=comando, index=False)
        con = engine.connect()
        con.close()

        print(f'Dados inseridos com sucesso na tabela {tabela}')

```
Exemplo de uso.

```Python

import datetime
import pandas as pd
import os

tabela = 'orderdetails'
pasta = f"L:/Curso Engenharia de dados/17.Projeto Final I/scripts/{tabela}.csv"
df = pd.read_csv(pasta, sep=";")
print(df)
InserirDados.inserirDadosMysql(df=df, tabela=tabela, comando='replace')

```

Daí foi só conectar e criar a visualização, confesso que não me preocupei muito com o visual nem com os filtros, pois eu queria apenas mostrar como seria o resultado do exercio de maneira mais visual e amigável para os gestores.

![image](https://github.com/Jezandre/north_wind_db/assets/63671761/cdb9ed1c-a539-4d9b-aa3e-30aaaebf8980)


## Conclusão

Este projeto, apesar de simples, me proporcionou absorver conhecimentos relacionados a:
- Utilização de Ferramentas da Nuvem AWS: Como por exemplo o bucket S3 e redshift e entender o poder destas ferramentas para o processamento de dados.
- Manipulação de Dados com SQL: Através da criação de consultas voltadas para as atividades relacionadas.
- Visualização de Dados: Para simplificar o entendimento dos questionamentos feitos pelo gestor
- Desenvolvimento de Projetos Práticos: Isso permitiu o entendimento mais claro de todo o conteúdo aprendido durante o curso

Em resumo, este projeto de engenharia de dados proporcionou uma experiência abrangente e prática, envolvendo desde a configuração de infraestrutura na nuvem até a análise e visualização de dados. Foi uma excelente oportunidade para adquirir habilidades essenciais e consolidar o conhecimento em engenharia de dados.
