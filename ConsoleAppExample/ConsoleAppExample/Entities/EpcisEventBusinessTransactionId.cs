namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventBusinessTransactionId
    {
        //-----------------------------------------------------------------
        //-- Tabelle zum Zwischenspeichern der BusinessTransactions
        //-----------------------------------------------------------------
	
        //create table #EPCISEvent_BusinessTransactionID
        //(
        //BusinessTransactionIDURN	    nvarchar(512)	not null,
        //BusinessTransactionTypeURN	nvarchar(512)	not null,
        //VocabularyTypeURN			    nvarchar(512)	not null,
        //BusinessTransactionIDID		bigint			null,
        //BusinessTransactionTypeID	    bigint			null,
        //VocabularyTypeID			    bigint			null,
        //EPCISEventID				    bigint			not null
        //);

        public string BusinessTransactionIdUrn { get; set; }
        public string BusinessTransactionTypeUrn { get; set; }
        public string VocabularyTypeUrn { get; set; }
        public long BusinessTransactionIdId { get; set; }
        public long BusinessTransactionTypeId { get; set; }
        public long VocabularyTypeId { get; set; }
        public long EpcisEventId { get; set; }
    }
}
