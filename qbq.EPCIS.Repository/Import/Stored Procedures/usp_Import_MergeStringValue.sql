-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS1_1
-- Firma:    QUIBIQ
-- (c) 2015  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- 
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 17.02.2015 | 1.0.0.0 | Florian Wagner      | Merged String Value
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_Import_MergeStringValue]
	@StringValue    nvarchar(1024)
AS
BEGIN

		merge into Event.Value_String WITH (HOLDLOCK) as target			
		using ( select 
					   @StringValue as Value
				)
		as source
		on 
		  target.Value              = source.Value 
		when not matched by target then
			insert (Value) 
			values (source.Value);

	    select 
			ID,
			Value
		from 
			Event.Value_String
		where Value = @StringValue;

END;
