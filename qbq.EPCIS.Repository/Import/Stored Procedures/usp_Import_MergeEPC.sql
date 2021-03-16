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
-- 17.02.2015 | 1.0.0.0 | Florian Wagner      | Merged EPCs
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_Import_MergeEPC]
	@URN nvarchar(512)
AS
BEGIN

		merge into Event.EPC WITH (HOLDLOCK) as target									
		using (select @URN as EPCURN ) as source
		on target.URN = source.EPCURN
		when not matched by target then
			insert(URN)
				values (source.EPCURN);

	    select 
			ID,
			URN 
		from 
			Event.EPC
		where URN = @URN;

END;
