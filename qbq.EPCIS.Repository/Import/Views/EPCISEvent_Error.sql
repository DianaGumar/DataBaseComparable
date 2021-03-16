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
CREATE VIEW [Import].[EPCISEvent_Error]
WITH SCHEMABINDING
AS
SELECT eq.ID as [QueueID]
      ,[Client]
      ,CAST([EPCISEvent] as nvarchar(max)) as [EPCISEvent]
	  ,CAST([EPCISEventOriginal] as nvarchar(max)) as [EPCISEventOriginal]
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
  FROM [Import].[EPCISEvent_Queue] eq
  JOIN [Import].[Error]			er on er.ObjectID = eq.ID
  WHERE eq.Error = 1 and er.AdditionalInformation = N'ObjectID: EPCISEvent_QUEUE';
