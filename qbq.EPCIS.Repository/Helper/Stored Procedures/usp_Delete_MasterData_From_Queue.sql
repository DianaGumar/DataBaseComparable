-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- 
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 06.08.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
-- 03.09.2014 | 1.0.1.0 | Florian Wagner      | Mandanten von aussen berücksichtigen
--            |         | FLW001              |
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Helper].[usp_Delete_MasterData_From_Queue]
	@QueueID   bigint = null,
	@ClientURN nvarchar(512) = null,	--FLW001+
	@All       bit    = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	IF @All = 0 and @QueueID is null
		THROW 51000, N'QueueID has to be set', 1;

	IF @All = 1 and @QueueID is not null
		THROW 51000, N'QueueID must not be set or @All has to be 0', 1;

	begin transaction;

		delete Import.Error
		from Import.Error er 
		join Import.EPCISMasterData_Queue eq on er.ObjectID = eq.ID
		where er.ErrorProcedure = N'usp_Import_MasterData' and eq.Error = 1 and (eq.ID = @QueueID or @QueueID is null) and (Client = @ClientURN or @ClientURN is null);	--FLW001~

		delete from Import.EPCISMasterData_Queue where Error = 1 and (ID = @QueueID or @QueueID is null) and (Client = @ClientURN or @ClientURN is null);	--FLW001~

	commit transaction;

END
