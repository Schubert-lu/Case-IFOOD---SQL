------------------------------------------------------------------------------------------------------------
------------------------------------------------	BEGIN	------------------------------------------------
------------------------------------------------------------------------------------------------------------
/*
	O script abaixo cria e e popula os dados nas estruturas de tabelas criadas a fim de possibilitar a execução das consultas do questionário
*/

---- Criação da tabela de clientes
DROP TABLE IF EXISTS tb_customers
CREATE TABLE tb_customers (
	 customerId INT IDENTITY(1,1) PRIMARY KEY
	,customerDoc CHAR(14)
	,firstName VARCHAR(32)
	,lastName VARCHAR(32)
	,birthDate DATE
)
-- Criação da tabela de produtos
DROP TABLE IF EXISTS tb_products;
CREATE TABLE tb_products (
    productId INT IDENTITY(1,1) PRIMARY KEY,
    productName VARCHAR(50),
    price DECIMAL(10, 2)
);

-- Criação da tabela de pedidos
DROP TABLE IF EXISTS tb_orders;
CREATE TABLE tb_orders (
    orderId INT IDENTITY(1,1) PRIMARY KEY,
    customerId INT FOREIGN KEY REFERENCES tb_customers(customerId),
    orderDate DATE
);

-- Criação da tabela de itens de pedidos
DROP TABLE IF EXISTS tb_order_items;
CREATE TABLE tb_order_items (
    orderItemId INT IDENTITY(1,1) PRIMARY KEY,
    orderId INT FOREIGN KEY REFERENCES tb_orders(orderId),
    productId INT FOREIGN KEY REFERENCES tb_products(productId),
    quantity INT
);

-- Índices para otimização de consultas
CREATE NONCLUSTERED INDEX ix_customerDoc on tb_customers (customerDoc) INCLUDE (customerId)
CREATE NONCLUSTERED INDEX ix_customerId ON tb_orders (customerId);
CREATE NONCLUSTERED INDEX ix_orderId ON tb_order_items (orderId);
CREATE NONCLUSTERED INDEX ix_productId ON tb_order_items (productId);

--- População de dados na tabela de tb_customers
INSERT INTO tb_customers (customerDoc, firstName, lastName, birthDate)
SELECT
    RIGHT('00000000000' + CAST(ABS(CHECKSUM(NEWID())) % 100000000000000 AS VARCHAR), 11) AS customerDoc,
    LEFT(NEWID(), 32) AS firstName,
    LEFT(NEWID(), 32) AS lastName,
    DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 36525, '1906-01-01') AS birthDate
FROM
    (SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS r FROM sys.columns) AS Numbers;

-- População de dados na tabela de produtos
INSERT INTO tb_products (productName, price)
VALUES
    ('Notebook', 2100.00),
    ('Smartphone', 1200.00),
    ('Tablet', 800.00),
    ('Headphones', 150.00),
    ('Monitor', 500.00),
    ('Keyboard', 80.00),
    ('Mouse', 40.00),
    ('Printer', 250.00),
    ('Webcam', 100.00),
    ('Speakers', 75.00),
    ('External Hard Drive', 130.00),
    ('USB Flash Drive', 20.00),
    ('Router', 90.00),
    ('Smartwatch', 250.00),
    ('Fitness Tracker', 100.00);

-- População de dados na tabela de pedidos
DECLARE @COUNT INT = 0, @LIM INT = 5
WHILE @COUNT <= @LIM BEGIN
	INSERT INTO tb_orders (customerId, orderDate)
	SELECT
		customerId,
		DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 365, GETDATE()) AS orderDate
	FROM
		tb_customers
	WHERE
		customerId <= (SELECT ABS(CHECKSUM(NEWID())) % 1000)

	SET @COUNT += 1

END

-- População de dados na tabela de itens de pedidos
DECLARE @COUNT1 INT = 0, @LIM1 INT = 10
WHILE @COUNT1 <= @LIM1 BEGIN
INSERT INTO tb_order_items (orderId, productId, quantity)
SELECT
    o.orderId,
    p.productId,
    ABS(CHECKSUM(NEWID())) % 5 + 1 AS quantity 
FROM
    tb_orders o
    CROSS JOIN tb_products p
WHERE
    ABS(CHECKSUM(NEWID())) % 10 < 3; 

	SET @COUNT1 += 1
END

------------------------------------------------------------------------------------------------------------
------------------------------------------------	END		------------------------------------------------
------------------------------------------------------------------------------------------------------------

/*

1.	Crie uma consulta que retorne apenas o item mais pedido e a quantidade total de pedidos.

*/


SELECT TOP 1
	productName,
	SUM(quantity) as quantidade
FROM tb_order_items
JOIN tb_products
ON tb_order_items.productId = tb_products.productId
GROUP BY productName
ORDER BY quantidade DESC

/*

2.	Crie uma consulta que retorne todos os clientes que realizaram mais de 4 pedidos no último ano em ordem decrescente.

*/



SELECT 
	firstName,
	COUNT(orderId) AS n_pedidos
FROM tb_orders 
JOIN tb_customers
ON tb_orders.customerId = tb_customers.customerId
WHERE orderDate BETWEEN '2025/01/01' AND '2025/12/31'
GROUP BY firstName
HAVING COUNT(orderID) >= 4
ORDER BY n_pedidos DESC


/*

3.	Crie uma consulta de quantos pedidos foram realizados em cada mês do último ano.

*/


SELECT 
	DATENAME(month,orderDate) as Mes ,
	count(orderDate) as n_pedidos
FROM tb_orders 
WHERE orderDate BETWEEN '2025/01/01' AND '2025/12/31'
GROUP BY DATENAME(month,orderDate), MONTH(orderDate)
ORDER BY MONTH(orderDate)


/*

4.	Crie uma consulta que retorne APENAS as informações do nome 
do produto e valor total de pedidos dos 5 produtos mais pedidos.

*/


SELECT TOP 5
	productName, 
	SUM(price * quantity) as totalAmount
FROM tb_products
JOIN tb_order_items
ON tb_products.productId = tb_order_items.productId
GROUP BY productName
ORDER BY totalAmount DESC


/*

5.	Crie uma consulta liste todos os clientes que não realizaram nenhum pedido.

*/


SELECT 
	b.customerId,
	b.firstName,
	a.orderId as total_pedidos
FROM tb_orders a
RIGHT JOIN tb_customers b
ON a.customerId = b.customerId
WHERE orderId IS NULL


/*

6.	Crie uma consulta que retorne a data e o nome do produto do último 
pedido realizado pelos clientes onde o customerId são 94, 130, 300 e 1000.

*/


WITH DataMaximaOrdens AS (
    SELECT
        customerId,
        MAX(orderDate) AS ultimaData
    FROM tb_orders
    WHERE customerId IN (94, 130, 300, 1000)
    GROUP BY customerId
)

SELECT
    A.customerId,
    A.orderDate,
    C.productName
FROM tb_orders A
JOIN DataMaximaOrdens M
ON A.customerId = M.customerId AND A.orderDate = M.ultimaData
JOIN tb_order_items B
ON A.orderId = B.orderId
JOIN tb_products C
ON C.productId = B.productId
ORDER BY A.customerId ASC;

/*

7.	Com base na estrutura das tabelas fornecidas (tb_order_items, tb_orders, tb_products, tb_customers), 
.crie uma nova tabela para armazenar informações sobre vendedores. A tabela deve seguir os conceitos básicos de modelo relacional. 
Certifique-se de definir claramente as colunas da tabela e suas relações com outras tabelas, se aplicável.

*/


CREATE TABLE tb_vendors (
    vendor_id INT IDENTITY(1,1) PRIMARY KEY,
    vendor_name NVARCHAR(255) NOT NULL,
);

ALTER TABLE tb_orders
ADD vendor_id INT;

ALTER TABLE tb_orders
ADD CONSTRAINT FK_tb_orders_vendor_id
FOREIGN KEY (vendor_id) REFERENCES tb_vendors(vendor_id);


/*

8.	Crie uma procedure que insira dados na tabela de vendedores criada anteriormente.
a.	Validar se o vendedor já existe na tabela.
b.	Se o vendedor não existir, inserir um novo registro com os dados fornecidos.
c.	Retornar uma mensagem indicando se a inserção foi bem-sucedida ou se o vendedor já está na tabela.
		Escreva a implementação completa da procedure, incluindo a validação e a mensagem de retorno.

*/


CREATE PROCEDURE InsertVendor
    @VendorName NVARCHAR(255),
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN

    SET @Message = '';
    
    IF EXISTS (SELECT 1 FROM tb_vendors WHERE vendor_name = @VendorName)
    BEGIN
        SET @Message = 'O vendedor já está na tabela.';
    END
    ELSE
    BEGIN
        INSERT INTO tb_vendors (vendor_name)
        VALUES (@VendorName);
        
        SET @Message = 'O vendedor foi inserido com sucesso.';
    END
END;

DECLARE @ResultMessage NVARCHAR(255);
EXEC InsertVendor @VendorName = 'Roberta', @Message = @ResultMessage OUTPUT;
PRINT @ResultMessage;

SELECT * FROM tb_vendors

/*

9.	Escreva um código em Python que se conecte a um banco de dados SQL Server e 
chame a procedure criada anteriormente para inserir um novo vendedor na tabela criada. 
Certifique-se de incluir o código de conexão ao banco de dados e a chamada da procedure 
com os parâmetros corretos.

CODIGO A SEGUIR EM PYTHON:

*/

!pip install pyodbc

import pyodbc

## Conectando com o BD

dados_conexao = (
    "Driver={SQL Server};"
    "Server=Lucas;"
    "Database=master;"
    )

conexao = pyodbc.connect(dados_conexao)

cursor = conexao.cursor()

comando = """DECLARE @ResultMessage NVARCHAR(255);
EXEC InsertVendor @VendorName = 'Julia', @Message = @ResultMessage OUTPUT;
PRINT @ResultMessage;"""

cursor.execute(comando)
cursor.commit()


/*

10.	Em Python, escreva um código que carregue a tabela "pedidos" 
em um DataFrame e, a partir desse DataFrame, retorne os 10 produtos mais vendidos 
"numberOfOrders" em ordem decrescente. 
Observação: o agrupamento dos dados deve ser realizado utilizando Python.

CODIGO A SEGUIR EM PYTHON:

*/

!pip install pyodbc
!pip install pandas

import pyodbc
import pandas as pd

dados_conexao = (
    "Driver={SQL Server};"
    "Server=Lucas;"
    "Database=master;"
    )

conexao = pyodbc.connect(dados_conexao)

cursor = conexao.cursor()

Dataframe = pd.read_sql("""
                        SELECT
                        	a.productName,
                        	b.quantity
                        FROM tb_products a
                        JOIN tb_order_items b
                        ON a.productId = b.productId
                        """,conexao)

print(Dataframe)

numberOfOrders = Dataframe.groupby('productName').sum()

numberOfOrders = numberOfOrders.sort_values('quantity', ascending = False)

numberOfOrders = numberOfOrders.head(10)
