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
CREATE VIEW [Import].[EPCISMasterData_Error]
WITH SCHEMABINDING
AS
	  SELECT eq.ID as [QueueID]
      ,[Client]
      ,CAST([EPCISMasterData] as nvarchar(max)) as [EPCISMasterData]
	  ,CAST([EPCISMasterDataOriginal] as nvarchar(max)) as [EPCISMasterDataOriginal]
      ,[Processed]
      ,[Error]
	  ,[ErrorID]
      ,CAST([TimeStampGeneration] as datetime) as [TimeStampGeneration]
      ,[AdditionalInformation]
      ,[ErrorNumber]
      ,[ErrorSeverity]
      ,[ErrorProcedure]
      ,[ErrorMessage]
      ,[ErrorLine]
      ,[ErrorState]
      ,[ObjectID]
  FROM [Import].[EPCISMasterData_Queue] eq
  JOIN [Import].[Error]			     er on er.ObjectID = eq.ID
  WHERE eq.Error = 1 and er.AdditionalInformation = N'ObjectID: EPCISMasterData_QUEUE'
