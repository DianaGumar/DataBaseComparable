-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- Ermittelt die korrekte Systemparameter des Datentyps anhand Inputspalten
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 05.07.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE FUNCTION [Import].[svf_get_DataTypeURN]
(
	@IntValue bigint,
	@FloatValue float,
	@TimeValue datetime2(7),
	@StringValue nvarchar(max)
)
RETURNS nvarchar(255)
AS
BEGIN
	DECLARE @return nvarchar(255);

	if @IntValue is null
	begin
		if @FloatValue is null
		begin
			if @TimeValue is null
			begin
				if @StringValue is null
				begin
					set @return = N'urn:quibiq:epcis:cbv:datatype:xml'
				end
				else
					set @return =  N'urn:quibiq:epcis:cbv:datatype:string'
				end;
			else
			begin
				set @return =  N'urn:quibiq:epcis:cbv:datatype:time'
			end;
		end
		else
		begin
			set @return =  N'urn:quibiq:epcis:cbv:datatype:float'
		end;
	end
	else
	begin
		set @return =  N'urn:quibiq:epcis:cbv:datatype:int'
	end;

	return @return;
END;