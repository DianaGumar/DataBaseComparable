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
-- 17.02.2015 | 1.0.0.0 | Florian Wagner      | Merged BusinessTransaction
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_Import_MergeBusinessTransaction]
	@BusinessTransactionIDURN  nvarchar(512),
	@BusinessTransactionTypeID bigint
AS
BEGIN

		merge into Event.BusinessTransactionID WITH (HOLDLOCK) as target			
		using (	select 
					@BusinessTransactionTypeID as BusinessTransactionTypeID, @BusinessTransactionIDURN as BusinessTransactionIDURN 
			) as source
		on target.BusinessTransactionTypeID = source.BusinessTransactionTypeID and target.URN = source.BusinessTransactionIDURN
		when not matched by target then
			insert (URN, BusinessTransactionTypeID)
				values (source.BusinessTransactionIDURN, source.BusinessTransactionTypeID);

	    select 
			ID,
			URN,
			BusinessTransactionTypeID 
		from 
			Event.BusinessTransactionID
		where URN = @BusinessTransactionIDURN and BusinessTransactionTypeID = @BusinessTransactionTypeID;

END;
