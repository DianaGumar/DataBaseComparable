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
-- 12.04.2013 | 1.0.0.0 | Leo Martens         | Erstellt.
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_Validate_Event]
	@Mandant nvarchar(max),
	@EPCISEvent xml,
	@ValidationResult nvarchar(max) out
AS
	SET @ValidationResult = null;

RETURN 0