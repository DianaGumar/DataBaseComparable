namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventVocabulary
    {
        //-----------------------------------------------------------------
        //-- Tabelle zum Zwischenspeichern der hierachischen Vokabeln, da IDs erst bekannt sind,
        //    -- wenn alles andere vorher eingetragen ist.
        //-----------------------------------------------------------------

        //create table #EPCISEvent_Vocabulary
        //(
        //VocabularyTypeURN	nvarchar(512)	not null,
        //VocabularyURN		nvarchar(512)	not null,
        //VocabularyTypeID	bigint			null,
        //ID				bigint			null,
        //EPCISEventID		bigint			not null
        //);

        public long Id { get; set; }
        public string VocabularyTypeUrn { get; set; }
        public string VocabularyUrn { get; set; }
        public long VocabularyTypeId { get; set; }
        public long EpcisEventId { get; set; }
    }
}
