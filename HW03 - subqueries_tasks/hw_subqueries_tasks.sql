/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT
	[FullName],
	[PersonID]
FROM [Application].[People] p
left join (Select [SalespersonPersonID] from [Sales].[Invoices] where [InvoiceDate] ='2015-07-04') i on p.[PersonID]=i.SalespersonPersonID
where [IsSalesperson]= 1 and i.SalespersonPersonID is null;

WITH Invoices_CTE 
as
(
Select 
	[SalespersonPersonID] 
FROM [Sales].[Invoices] where [InvoiceDate] ='2015-07-04'
),
People_CTE
as
(
SELECT
	[FullName],
	[PersonID] 
FROM [Application].[People] where [IsSalesperson]= 1
)
SELECT 
	[FullName],
	[PersonID] 
FROM People_CTE
left join Invoices_CTE  on [PersonID]=[SalespersonPersonID]
where SalespersonPersonID is null;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT 
	[StockItemID],
	[StockItemName],
	[UnitPrice]      
FROM [Warehouse].[StockItems]
where [UnitPrice] = 
( 
SELECT 
	min([UnitPrice])      
FROM [Warehouse].[StockItems]
);

SELECT TOP 1
	[StockItemID],
	[StockItemName],
	[UnitPrice]
FROM [Warehouse].[StockItems]
order by [UnitPrice];

WITH UnitPriceMin_CTE
as
(
SELECT 
	min([UnitPrice]) as [UnitPriceMin]     
FROM [Warehouse].[StockItems]
)
Select 
	[StockItemName],
	[StockItemID],
	[UnitPrice] 
From [Warehouse].[StockItems] si 
join  UnitPriceMin_CTE on si.[UnitPrice]=UnitPriceMin_CTE.[UnitPriceMin]

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

SELECT TOP 5 
	c.CustomerName,      
	sum([TransactionAmount])  as [TransactionAmount]
FROM [WideWorldImporters].[Sales].[CustomerTransactions] ct
inner join [Sales].[Customers] c on ct.CustomerID=c.CustomerID
  group by c.CustomerName
  order by [TransactionAmount] Desc;

with CustomerTransactions_CTE
AS
(
SELECT TOP 5 
	[CustomerID],      
	sum([TransactionAmount])  as [TransactionAmount]
FROM [WideWorldImporters].[Sales].[CustomerTransactions]
group by [CustomerID]
order by [TransactionAmount] Desc
)
SELECT 
	c.CustomerName,
	[TransactionAmount] 
from CustomerTransactions_CTE 
inner join [Sales].[Customers] c on CustomerTransactions_CTE.CustomerID= c.CustomerID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

SELECT DISTINCT 
	[DeliveryCityID],
	[CityName],
	p.FullName 
FROM [Sales].[Customers] c
inner join [Sales].[Invoices] i on c.CustomerID=i.CustomerID
inner join [Application].[Cities] Ci on c.[DeliveryCityID]=Ci.[CityID]
inner join [Sales].[InvoiceLines] il on i.InvoiceID=il.InvoiceID
inner join 
(
	SELECT TOP 3 
		StockItemID,
		UnitPrice,
		StockItemName 
	FROM Warehouse.StockItems
	ORDER BY UnitPrice DESC
) si on il.StockItemID=si.StockItemID
inner join [Application].[People] p on i.PackedByPersonID=p.[PersonID];

with StockItems_CTE
AS

(
	SELECT TOP 3 
		StockItemID,
		UnitPrice,
		StockItemName 
	FROM WideWorldImporters.Warehouse.StockItems
	ORDER BY UnitPrice DESC
)
SELECT DISTINCT 
	[DeliveryCityID],
	[CityName],
	[FullName]
FROM StockItems_CTE
inner join [Sales].[InvoiceLines] il on StockItems_CTE.StockItemID=il.StockItemID
inner join [Sales].[Invoices] i on i.InvoiceID=il.InvoiceID
inner join [Sales].[Customers] c on c.CustomerID=i.CustomerID
inner join [Application].[Cities] Ci on c.[DeliveryCityID]=Ci.[CityID]
inner join [Application].[People] p on i.PackedByPersonID=p.[PersonID];

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --
/*Выбрать id продаж, даты продаж, имя продовца. По этим полям показать 
общую сумму для товаров где общая сумма продаж больше 27000*/
with SalesTotals_CTE
As
(
SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
)
,
TotalSummForPickedItems_CTE
AS 
(SELECT OrderId ,SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) as TotalSummForPickedItems
		FROM Sales.OrderLines group by OrderId
		)
SELECT 	i.InvoiceID, 
	i.InvoiceDate, p.FullName as SalesPersonName, TotalSumm as TotalSummByInvoice,TotalSummForPickedItems  FROM SalesTotals_CTE
inner join Sales.Invoices i  ON i.InvoiceID = SalesTotals_CTE.InvoiceId
inner join Application.People p ON i.SalespersonPersonID=p.PersonID
inner join Sales.Orders o on o.OrderId = i.OrderID
inner join TotalSummForPickedItems_CTE on i.OrderID=TotalSummForPickedItems_CTE.OrderID
WHERE o.PickingCompletedWhen IS NOT NULL and TotalSumm > 27000	 
ORDER BY TotalSumm DESC;
------
SELECT 
	i.InvoiceID, 
	i.InvoiceDate,
	p.FullName as SalesPersonName,
	TotalSummForPickedItems,
	il.TotalSumm
FROM Sales.Invoices i
inner join Application.People p on i.SalespersonPersonID=p.PersonID
inner join Sales.Orders o on i.OrderId = o.OrderId
inner join (SELECT OrderId ,SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) as TotalSummForPickedItems
		FROM Sales.OrderLines group by OrderId) ol on o.OrderID=ol.OrderID
inner join (SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId HAVING SUM(Quantity*UnitPrice) > 27000) il on i.InvoiceID = il.InvoiceID
WHERE o.PickingCompletedWhen IS NOT NULL 
ORDER BY il.TotalSumm DESC
