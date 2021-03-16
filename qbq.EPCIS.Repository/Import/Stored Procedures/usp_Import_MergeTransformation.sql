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
-- 17.02.2015 | 1.0.0.0 | Florian Wagner      | Merged Transformation
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_Import_MergeTransformation]
	@TransformationURN  nvarchar(512)
AS
BEGIN

		merge into Event.TransformationID WITH (HOLDLOCK) as target					
		using (	select 
					@TransformationURN as TransformationIDURN
			) as source
		on target.URN = source.TransformationIDURN
		when not matched by target then
			insert (URN)
				values (source.TransformationIDURN);


	    select 
			ID,
			URN 
		from 
			Event.TransformationID
		where URN = @TransformationURN;

END;
