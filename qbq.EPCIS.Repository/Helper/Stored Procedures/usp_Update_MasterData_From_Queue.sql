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
-- 10.09.2014 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Helper].[usp_Update_MasterData_From_Queue]
	@QueueID   bigint,
	@ClientURN nvarchar(512) = null,
	@Xml	   nvarchar(max)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	begin transaction;

		UPDATE Import.EPCISMasterData_Queue 
			SET EPCISMasterData = CAST(@Xml as XML)
		WHERE ID = @QueueID and (Client = @ClientURN or @ClientURN is null);

	commit transaction;

END
