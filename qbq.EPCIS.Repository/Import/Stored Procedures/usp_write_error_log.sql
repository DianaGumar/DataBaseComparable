-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2012  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- Procedure fügt SQL-Error Informationen sowie eigene Fehler-Logs in die Fehlerlog-Tabelle
-- log.Error ein.
-- 
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 06.03.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_write_error_log](
	@AddInformation nvarchar(2048) = NULL,  --Optionale Information
	@ObjectID       bigint = 0				--Optionale Information indirekte Referenz auf PK des Fehlerobjekt
	)
AS
BEGIN
	SET NOCOUNT ON
	
	-- Speicher Error Eintrag
	INSERT INTO [Import].[Error] (
		[TimeStampGeneration]
		,[AdditionalInformation]
		,[ErrorNumber]
		,[ErrorSeverity]
		,[ErrorProcedure]
		,[ErrorMessage]
		,[ErrorLine]
		,[ErrorState]
		,[ObjectID] )
    SELECT
		getdate()								   as TimeStampGeneration
		,isnull(@AddInformation, 'none')		   as AdditionalInformation
        ,isnull(ERROR_NUMBER(), 0)				   as ErrorNumber
        ,isnull(ERROR_SEVERITY(), 0)			   as ErrorSeverity
        ,isnull(ERROR_PROCEDURE(), ' ')            as ErrorProcedure
		,isnull(ERROR_MESSAGE(), ' ')              as ErrorMessage
        ,isnull(ERROR_LINE(), 0)                   as ErrorLine
        ,isnull(ERROR_STATE(), 0)                  as ErrorState 
		,@ObjectID								   as ObjectID
	
	RETURN 0
END