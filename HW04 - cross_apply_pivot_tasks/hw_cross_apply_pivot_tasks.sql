/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

SELECT 
	convert (varchar,InvoiceMonth, 104) as InvoiceMonth, 
	ISNULL([Sylvanite, MT], 0) AS [Sylvanite, MT],
	ISNULL([Peeples Valley, AZ], 0) AS [Peeples Valley, AZ],
	ISNULL([Medicine Lodge, KS], 0) AS [Medicine Lodge, KS],
	ISNULL([Gasport, NY], 0) AS [Gasport, NY],
	ISNULL([Jessie, ND], 0) AS [Jessie, ND]
FROM 
	(
		SELECT InvoiceMonth,
		replace (substring (CustomerName,CHARINDEX ('(',CustomerName)+1,len (CustomerName)), ')','') as CustomerName,
		count(*)  as col   
		FROM [Sales].[Invoices] ct
		CROSS APPLY (SELECT CAST(DATEADD(mm,DATEDIFF(mm,0,ct.InvoiceDate),0) AS DATE) AS InvoiceMonth) AS CA
		inner join  [Sales].[Customers] c on ct.CustomerID=c.CustomerID
			where ct.CustomerID between 2 and 6
			GROUP BY CA.InvoiceMonth,c.CustomerName
	) as cust
PIVOT 
(
	sum(col)
	FOR CustomerName IN 
		( 
			[Sylvanite, MT],
			[Peeples Valley, AZ],
			[Medicine Lodge, KS],
			[Gasport, NY],
			[Jessie, ND] 
		)
) as piv

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT 
	[CustomerName],
	[AddressLine] 
FROM 
(
	SELECT 
		[CustomerName],
		[DeliveryAddressLine1],
		[DeliveryAddressLine2],
		[PostalAddressLine1],
		[PostalAddressLine2]
	 FROM [Sales].[Customers]
		where [CustomerName] like 'Tailspin Toys%'
) as con
UNPIVOT ( AddressLine FOR [Address] IN ([DeliveryAddressLine1], [DeliveryAddressLine2],[PostalAddressLine1],[PostalAddressLine2])) AS unpt;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT 
[CountryID],
[CountryName],
Code 
From 
	(
		SELECT 
		cast([CountryID] as char(25)) as [CountryID],
		[CountryName],
		cast([IsoAlpha3Code] as nvarchar(25)) as [IsoAlpha3Code],
		cast([IsoNumericCode] as nvarchar(25)) as [IsoNumericCode1]   
		FROM [Application].[Countries]
	) ac
  UNPIVOT ( Code FOR Cantry IN ([IsoAlpha3Code], [IsoNumericCode1])) AS unpt;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT
	a.[CustomerID],
	c.CustomerName,
	a.StockItemID,
	a.[UnitPrice],
	a.[InvoiceDate]    
FROM [WideWorldImporters].[Sales].[Customers] c
  outer apply 
  (
	SELECT top 2 
		[StockItemName],
		si.[StockItemID], 
		i.CustomerID,
		[InvoiceDate],
		si.[UnitPrice]
	FROM [WideWorldImporters].[Warehouse].[StockItems] si
	inner join [Sales].[InvoiceLines] il on il.StockItemID= si.StockItemID
	inner join [Sales].[Invoices] i on i.InvoiceID=il.InvoiceLineID
	where i.CustomerID=c.CustomerID
	order by [UnitPrice] desc
  ) a
 order by c.CustomerName
