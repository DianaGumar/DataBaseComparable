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
CREATE FUNCTION [Callback].[svf_Check_Schedule_Part]
(
	@DatePart char(2),
	@Value    tinyint
)
RETURNS BIT
AS
BEGIN

	-- 2 stellige Nomenklatur Analog DATEPART http://msdn.microsoft.com/de-de/library/ms174420.aspx

	IF @DatePart = 'ss'
	BEGIN
		IF @Value between 0 and 59
			RETURN 1;
	END;

	IF @DatePart = 'mi'
	BEGIN
		IF @Value between 0 and 59
			RETURN 1;
	END;

	IF @DatePart = 'hh'
	BEGIN
		IF @Value between 0 and 23
			RETURN 1;
	END;

	IF @DatePart = 'dd'
	BEGIN
		IF @Value between 1 and 31
			RETURN 1;
	END;

	IF @DatePart = 'mm'
	BEGIN
		IF @Value between 1 and 12
			RETURN 1;
	END;

	IF @DatePart = 'dw'
	BEGIN
		IF @Value between 1 and 7
			RETURN 1;
	END;

	RETURN 0;
END