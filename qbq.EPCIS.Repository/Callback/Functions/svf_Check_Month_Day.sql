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
-- 15.07.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE FUNCTION [Callback].[svf_Check_Month_Day]
(
	@Day		tinyint,
	@Month		tinyint,
	@Year       int
)
RETURNS tinyint
AS
BEGIN
	DECLARE @DateString char(10);

	IF @Month in (4,6,9,11) and @Day = 31
		SET @Day = 1;
	IF @Month = 2 and @Day > 29
		SET @Day = 1;
	IF @Month = 2 and @Day = 29
	BEGIN
		-- nächstes valides Datum berechnen
		SET @DateString = CAST(@Year as char(4)) + '-' + CAST(@Month as char(2))+ '-' + CAST(@Day as char(2));
		IF ISDATE(@DateString) = 0
			SET @Day = 1;
	END;

	RETURN @Day;

END