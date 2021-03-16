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
-- 17.02.2015 | 1.0.0.0 | Florian Wagner      | Merged Vocabulary Element
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [Import].[usp_Import_MergeVocabulary]
	@VocabularyURN    nvarchar (512),
	@VocabularyTypeID bigint,
	@ClientID         bigint
AS
BEGIN

		merge into Vocabulary.Vocabulary WITH (HOLDLOCK) as target
		using ( select 
					 @VocabularyURN as VocabularyURN
					,@VocabularyTypeID as VocabularyTypeID
					,@ClientID as ClientID
		) as source
		on target.URN                = source.VocabularyURN and
		   target.VocabularyTypeID   = source.VocabularyTypeID and
		   target.ClientID           = source.ClientID
			when matched then
				update set Deleted = 0
		when not matched by target then
			insert (ClientID, VocabularyTypeID, URN) 
			values (source.ClientID, source.VocabularyTypeID, source.VocabularyURN);

	    select 
			ID,
			URN,
			VocabularyTypeID,
			ClientID
		from 
			Vocabulary.Vocabulary
		where URN = @VocabularyURN and VocabularyTypeID = @VocabularyTypeID and ClientID = @ClientID;

END;
