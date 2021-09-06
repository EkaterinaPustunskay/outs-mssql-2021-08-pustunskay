/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID,StockItemName 
FROM Warehouse.StockItems
where StockItemName like '%urgent%' or StockItemName like 'Animal%'


/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT t1.SupplierID, SupplierName 
FROM [WideWorldImporters].[Purchasing].[Suppliers] t1
left join  [WideWorldImporters].[Purchasing].[PurchaseOrders] t2 on t1.SupplierID=t2.SupplierID
where t2.[PurchaseOrderID] is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT t1.OrderID,
convert (varchar,OrderDate, 104) as OrderDate, DATENAME (month,OrderDate) as [MonthName], Datepart(q,OrderDate) as [QuarterNum], (Datepart(m,OrderDate)-1)/4+1 as QQ,
t3.[CustomerName]
FROM [WideWorldImporters].[Sales].[Orders] t1
inner join [WideWorldImporters].Sales.OrderLines t2 on t1.OrderID=t2.OrderID
inner join [WideWorldImporters].Sales.Customers t3 on t1.CustomerID=t3.CustomerID
where UnitPrice>100 or (Quantity> 20 and t1.PickingCompletedWhen is not null)
order by QuarterNum ASC, QQ ASC, OrderDate ASC

SELECT t1.OrderID,
convert (varchar,OrderDate, 104) as OrderDate, DATENAME (month,OrderDate) as [MonthName], Datepart(q,OrderDate) as [QuarterNum], (Datepart(m,OrderDate)-1)/4+1 as QQ,
t3.[CustomerName]
FROM [WideWorldImporters].[Sales].[Orders] t1
inner join [WideWorldImporters].Sales.OrderLines t2 on t1.OrderID=t2.OrderID
inner join [WideWorldImporters].Sales.Customers t3 on t1.CustomerID=t3.CustomerID
where UnitPrice>100 or (Quantity> 20 and t1.PickingCompletedWhen is not null)
order by QuarterNum ASC, QQ ASC, OrderDate ASC
OFFSET 1000 Rows FETCH FIRST  100 Rows Only

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

Select Distinct ExpectedDeliveryDate, DeliveryMethodName,[SupplierName],[FullName] as ContactPerson  From [WideWorldImporters].[Purchasing].[Suppliers] t1
inner join [WideWorldImporters].[Purchasing].[PurchaseOrders] t2 on t1.[SupplierID]=t2.[SupplierID]
inner join [WideWorldImporters].[Application].[DeliveryMethods] t3 on t1.DeliveryMethodID=t3.DeliveryMethodID
inner join [WideWorldImporters].[Application].[People] t4 on t1.[LastEditedBy]=t4.[PersonID]
where ExpectedDeliveryDate between '2013-01-01' and '2013-01-31' and (DeliveryMethodName = 'Air Freight' or  DeliveryMethodName ='Refrigerated Air Freight')
and IsOrderFinalized =1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT  CustomerName,[FullName] as SalespersonPerson,[OrderDate]     
FROM [WideWorldImporters].[Sales].[Orders] t1
  inner join [WideWorldImporters].[Application].[People]t2 on t1.[SalespersonPersonID]=t2.[PersonID]
  inner join [WideWorldImporters].[Sales].[Customers] t3 on t1.[CustomerID] = t3.[CustomerID]
  order by [OrderDate] DESC
  OFFSET 0 Rows FETCH FIRST  10 Rows Only

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT t1.[CustomerID], t2.CustomerName, t2.PhoneNumber
  FROM [WideWorldImporters].[Sales].[Invoices]t1
  inner join [WideWorldImporters].[Sales].[Customers] t2 on t1.[CustomerID] = t2.[CustomerID]
  inner join [WideWorldImporters].[Sales].[InvoiceLines] t3 on t1.[InvoiceID]=t3.InvoiceID
  inner join [WideWorldImporters].[Warehouse].[StockItems] t4 on t3.StockItemID=t4.[StockItemID]
  where StockItemName = 'Chocolate frogs 250g'

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT Datepart(YEAR,[InvoiceDate]) as InvoiceYear,Datepart(MONTH,[InvoiceDate]) as InvoiceMonth, 
avg([ExtendedPrice]) as AvgExtendedPrice,
sum([ExtendedPrice]) as SumExtendedPrice
FROM [WideWorldImporters].[Sales].[Invoices] t1
inner join [WideWorldImporters].[Sales].[InvoiceLines] t3 on t1.[InvoiceID]=t3.InvoiceID
group by Datepart(YEAR,[InvoiceDate]),Datepart(MONTH,[InvoiceDate])
order by InvoiceYear,InvoiceMonth

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT Datepart(YEAR,[InvoiceDate]) as InvoiceYear,Datepart(MONTH,[InvoiceDate]) as InvoiceMonth, 
sum([ExtendedPrice]) as SumExtendedPrice
  FROM [WideWorldImporters].[Sales].[Invoices] t1
  inner join [WideWorldImporters].[Sales].[InvoiceLines] t3 on t1.[InvoiceID]=t3.InvoiceID
  group by Datepart(YEAR,[InvoiceDate]),Datepart(MONTH,[InvoiceDate])
  Having sum([ExtendedPrice])>10000
  order by InvoiceYear,InvoiceMonth

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT Datepart(YEAR,[InvoiceDate]) as InvoiceYear,Datepart(MONTH,[InvoiceDate]) as InvoiceMonth, [StockItemName],
sum([ExtendedPrice]) as SumExtendedPrice,min([InvoiceDate]) DateFirsSale,
sum([Quantity]) as SumQuantity
  FROM [WideWorldImporters].[Sales].[Invoices] t1
  inner join [WideWorldImporters].[Sales].[InvoiceLines] t3 on t1.[InvoiceID]=t3.InvoiceID
  inner join [WideWorldImporters].[Warehouse].[StockItems] t4 on t3.StockItemID=t4.[StockItemID]
  group by Datepart(YEAR,[InvoiceDate]),Datepart(MONTH,[InvoiceDate]),[StockItemName]
  Having sum([Quantity])<50
  order by InvoiceYear,InvoiceMonth,[StockItemName]

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
