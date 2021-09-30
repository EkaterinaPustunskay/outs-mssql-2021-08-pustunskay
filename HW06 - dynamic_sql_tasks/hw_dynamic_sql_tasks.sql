/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/


DECLARE @dml AS NVARCHAR(MAX)
DECLARE @CustomerName AS NVARCHAR(MAX)

SELECT @CustomerName= ISNULL(@CustomerName + ',','') 
       + QUOTENAME(CustomerName)
	   FROM (
SELECT Distinct 
		replace (substring (CustomerName,CHARINDEX ('(',CustomerName)+1,len (CustomerName)), ')','') as CustomerName 
		FROM [Sales].[Customers] c 
			) CustomerName
 

SET @dml = 
  N'SELECT 
	convert (varchar,InvoiceMonth, 104) as InvoiceMonth, 
			'+@CustomerName +'
FROM 
	(
		SELECT InvoiceMonth,replace (substring (CustomerName,CHARINDEX (''('',CustomerName)+1,len (CustomerName)), '')'','''') as CustomerName
		,count(*)  as col   
		FROM [Sales].[Invoices] ct
		CROSS APPLY (SELECT CAST(DATEADD(mm,DATEDIFF(mm,0,ct.InvoiceDate),0) AS DATE) AS InvoiceMonth) AS CA
		inner join  [Sales].[Customers] c on ct.CustomerID=c.CustomerID
			GROUP BY CA.InvoiceMonth,c.CustomerName
	) as cust
PIVOT 
(
	sum(col)
	FOR CustomerName IN 
		(' + @CustomerName + ')
) as piv'
EXEC sp_executesql @dml
