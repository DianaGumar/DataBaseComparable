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
-- 26.02.2015 | 1.0.0.0 | Florian Wagner      | Insert EPCISEvent_Value Vocabulary Element
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_Import_EPCISEvent_Value]
	@EPCISEventID    bigint,
	@ValueTypeID     bigint,
	@DataTypeID		 bigint
AS
BEGIN

		insert into Event.EPCISEvent_Value (
			[EPCISEventID],	
			[ValueTypeID],	
			[DataTypeID]
			)
		OUTPUT inserted.ID
		select
			@EPCISEventID as [EPCISEventID],
			@ValueTypeID as [ValueTypeID],
			@DataTypeID as [DataTypeID]

END;
