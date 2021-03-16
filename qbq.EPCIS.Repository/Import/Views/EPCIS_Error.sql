-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2014  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- 
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 03.09.2014 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE VIEW [Import].[EPCIS_Error]
WITH SCHEMABINDING
AS
SELECT
	 [QueueID]
    ,[Client]
    ,[EPCISMasterData] as [Xml]
	,[EPCISMasterDataOriginal] as [XmlOriginal]
    ,[Processed]
    ,[Error]
	,[ErrorID]
    ,[TimeStampGeneration]
    ,[AdditionalInformation]
    ,[ErrorNumber]
    ,[ErrorSeverity]
    ,[ErrorProcedure]
    ,[ErrorMessage]
    ,[ErrorLine]
    ,[ErrorState]
    ,[ObjectID]
FROM [Import].[EPCISMasterData_Error]
UNION ALL
SELECT
	 [QueueID]
    ,[Client]
    ,[EPCISEvent] as [Xml]
	,[EPCISEventOriginal] as [XmlOriginal]
    ,[Processed]
    ,[Error]
	,[ErrorID]
    ,[TimeStampGeneration]
    ,[AdditionalInformation]
    ,[ErrorNumber]
    ,[ErrorSeverity]
    ,[ErrorProcedure]
    ,[ErrorMessage]
    ,[ErrorLine]
    ,[ErrorState]
    ,[ObjectID]
FROM [Import].[EPCISEvent_Error];
