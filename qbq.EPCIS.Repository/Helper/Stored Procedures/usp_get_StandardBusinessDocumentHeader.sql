-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- Erhöht den InstanceIdentifier Wert um eins oder fügt ihn Hinzu falls noch nicht vorhanden
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 06.09.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Helper].[usp_get_StandardBusinessDocumentHeader]
	@Client							nvarchar(512),
	@Username						nvarchar(512),
	@EventTyp						nvarchar(128),
	@StandardBusinessDocumentHeader xml OUTPUT,
	@InstanceIdentifier				int OUTPUT
AS
BEGIN

	SET NOCOUNT ON;

	SET @StandardBusinessDocumentHeader = [Helper].[svf_get_StandardBusinessDocumentHeader] (@Client, @Username, @EventTyp);
	
	EXECUTE [Helper].[usp_Update_InstanceIdentifier] 
		@Client             = @Client, 
		@Username           = @Username,
		@InstanceIdentifier = @InstanceIdentifier OUT;

END;