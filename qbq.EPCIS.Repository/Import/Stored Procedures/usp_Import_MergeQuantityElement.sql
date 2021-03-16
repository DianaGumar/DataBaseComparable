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
-- 17.02.2015 | 1.0.0.0 | Florian Wagner      | Merged Quantity Element
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_Import_MergeQuantityElement]
	@EPCClassID  bigint,
	@Quantity    float,
	@UOM		 nchar(3)
AS
BEGIN

		merge into Event.QuantityElement WITH (HOLDLOCK) as target					
		using (	select 
					@EPCClassID as EPCClassID, @Quantity as Quantity, @UOM as UOM 
			) as source
		on target.EPCClassID = source.EPCClassID and target.Quantity = source.Quantity and target.UOM = source.UOM
		when not matched by target then
			insert (EPCClassID, Quantity, UOM)
				values (source.EPCClassID, source.Quantity, source.UOM);


	    select 
			ID,
			EPCClassID,
			Quantity,
			UOM
		from 
			Event.QuantityElement
		where EPCClassID = @EPCClassID and Quantity = @Quantity and UOM = @UOM;

END;
