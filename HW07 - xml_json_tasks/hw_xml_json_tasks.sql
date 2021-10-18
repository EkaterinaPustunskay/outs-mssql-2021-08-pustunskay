/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Опционально - если вы знакомы с insert, update, merge, то загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
*/

DECLARE @xmlDoc  xml
DECLARE @docHandle int

SELECT @xmlDoc = BulkColumn
FROM OPENROWSET
(BULK 'F:\Ekaterina21\StockItems.xml', 
 SINGLE_CLOB)
as data 

EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDoc

SELECT 
	StockItemName, 
	SupplierID, 
	UnitPackageID, 
	OuterPackageID, 
	QuantityPerOuter, 
	TypicalWeightPerUnit, 
	LeadTimeDays, 
	IsChillerStock, 
	TaxRate, 
	UnitPrice
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] nvarchar (100) '@Name',
	[SupplierID]  int 'SupplierID',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID',
    [QuantityPerOuter]int'Package/QuantityPerOuter',
    [TypicalWeightPerUnit]decimal(18,3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays]int 'LeadTimeDays',
    [IsChillerStock]bit 'IsChillerStock',
    [TaxRate]decimal(18,3)'TaxRate',
    [UnitPrice]decimal(18,2)'UnitPrice'
	)

--- запрос на обновление через MERGE.

MERGE [Warehouse].[StockItems] as SI
USING (SELECT StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] nvarchar (100) '@Name',
	[SupplierID]  int 'SupplierID',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID',
    [QuantityPerOuter]int'Package/QuantityPerOuter',
    [TypicalWeightPerUnit]decimal(18,3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] int 'LeadTimeDays',
    [IsChillerStock]bit 'IsChillerStock',
    [TaxRate]decimal(18,3)'TaxRate',
    [UnitPrice]decimal(18,2)'UnitPrice'
	)) as xmlSI
ON SI.StockItemName=xmlSI.StockItemName
WHEN MATCHED THEN 
UPDATE SET
	SI.SupplierID = xmlSI.SupplierID, 
	SI.UnitPackageID= xmlSI.UnitPackageID, 
	SI.OuterPackageID= xmlSI.OuterPackageID, 
	SI.QuantityPerOuter= xmlSI.QuantityPerOuter, 
	SI.TypicalWeightPerUnit= xmlSI.TypicalWeightPerUnit, 
	SI.LeadTimeDays= xmlSI.LeadTimeDays, 
	SI.IsChillerStock= xmlSI.IsChillerStock, 
	SI.TaxRate= xmlSI.TaxRate, 
	SI.UnitPrice= xmlSI.UnitPrice;

EXEC sp_xml_removedocument @docHandle

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

SELECT 
	[StockItemName] as [Items/@Name],
	[SupplierID] as [Items/SupplierID], 
	[ColorID] as [Items/ColorID],
	[UnitPackageID] as [Items/Package/UnitPackageID],
	[OuterPackageID] as [Items/Package/OuterPackageID],
	[QuantityPerOuter] as [Items/Package/QuantityPerOuter],
	TypicalWeightPerUnit as [Items/Package/TypicalWeightPerUnit],
	[Brand] as [Items/Brand], 
	[Size] as [Items/ColorID],
	LeadTimeDays as [Items/LeadTimeDays],     
	[IsChillerStock] as [Items/IsChillerStock],
	[Barcode] as [Items/Barcode],
	[TaxRate] as [Items/TaxRate],
	[UnitPrice] as [Items/UnitPrice],
	[RecommendedRetailPrice] as [Items/RecommendedRetailPrice],
	[MarketingComments] as [Items/MarketingComments],
	[InternalComments] as [Items/InternalComments],
	[CustomFields] as [Items/CustomFields],
	[Tags] as [Items/Tags],
	[SearchDetails] as [Items/SearchDetails],
	[LastEditedBy] as [Items/LastEditedBy],
	[ValidFrom] as [Items/ValidFrom],
	[ValidTo] as [Items/ValidTo]
  FROM [Warehouse].[StockItems]
    FOR XML Path(''),ROOT('StockItem')


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT 
	StockItemID,
	StockItemName, 
	JSON_VALUE (CustomFields, '$.CountryOfManufacture') as CountryOfManufacture,
	JSON_VALUE (CustomFields, '$.Tags[0]') as Tags
FROM [Warehouse].[StockItems]

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

SELECT 
	StockItemName,
	StockItemID
FROM [Warehouse].[StockItems]
cross apply openjson (CustomFields, '$.Tags') as tags
where tags.value='Vintage'
