# Projeto de Engenharia de dados - NorthWinddb

 ## Introdução

 O presente artigo é referente a um dos projetos disponíveis no curso do [Fernando Amaral](https://www.linkedin.com/in/fernando-amaral/) no curso [Formação Engenharia de Dados: Domine Big Data!](https://www.udemy.com/course/engenheiro-de-dados/learn/lecture/15289778?start=0) disponível na Udemy. O projeto consiste na criação de um pipeline utilizando ferramentas da nuvem AWS e responder a cinco perguntas de negócio utilizando SQL.

 Para isso usaremos as seguintes ferramentas:

 - Um bucket na AWS S3
 - Um banco de dados no AWS Redshift
 - linguagem SQL para criar as tabelas, inserir as informações e criar as consultas
 - Visualizar as informações em um dataViz

O projeto é bem simples, porém uma dica que eu recebi e que gosto de passar a frente é sempre escreva sobre o que aprendeu. Se possível escreva a mão. Isso ajuda a manter os conceitos aprendidos vivos.

## Materiais

Os materiais utilizados foram todos disponibilizados no curso. Mas basicamente faremos um estudo sobre informações de vendas e produtos de um conjunto de dados salvos no CSV chamado Northwinddd. Os materiais se encontram disponíveis nesse repositório caso tenham curiosiadade de aprender um pouco e se desenvolver. As perguntas que iremos responder serão as seguintes:

1. Temos realizado vendas com valor abaixo do preço de tabela?
2. Como está perfomance dos vendedores em relaçao ao ano anterior?
3. Quais os produtos mais caros?
4. Avaliar a diferença de perfomance dos produtos por fornecedor nos ultimos dois anos
5. Quais os 5 produtos mais venderam em cada ano?

Essas perguntas nos permitirão abordar vários conceitos tanto de engenharia quanto em análise.

O esquema a seguir será o que nos basearemos para resolver cada questão.

###colocar imagem aqui###

O fluxo de dados seguirá da seguinte forma:

os dados são obtidos atrvés de arquivos cvs salvos dentro de um bucket S3. Através de SQL, os dados são inseridos num banco de dados no redshift e a partir daí elaboramos as consultas sql que podem ser enviadas para um dataviz.

###colocar a imagem aqui###

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


