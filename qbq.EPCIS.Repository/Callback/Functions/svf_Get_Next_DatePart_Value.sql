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
CREATE FUNCTION [Callback].[svf_Get_Next_DatePart_Value]
(
	@DatePart    char(2),
	@Value		 tinyint
)
RETURNS tinyint
AS
BEGIN
	DECLARE @Result tinyint = @Value + 1;

	IF @DatePart = 'ss'
	BEGIN
		IF @Result > 59
			RETURN 0;
	END;

	IF @DatePart = 'mi'
	BEGIN
		IF @Result > 59
			RETURN 0;
	END;

	IF @DatePart = 'hh'
	BEGIN
		IF @Result > 23
			RETURN 0;
	END;

	IF @DatePart = 'dd'
	BEGIN
		IF @Result > 31
			RETURN 1;
	END;

	IF @DatePart = 'mm'
	BEGIN
		IF @Result > 12
			RETURN 1;
	END;

	IF @DatePart = 'dw'
	BEGIN
		IF @Result > 7
			RETURN 1;
	END;

	RETURN @Result;
END