namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventSourceDestination
    {
        //-----------------------------------------------------------------
        //-- Tabelle zum Zwischenspeichern der SourceDestination
        //-----------------------------------------------------------------

        //create table #EPCISEvent_SourceDestination
        //(
        //EPCISEventID				bigint		  not null,
        //IsSource					bit			  not null,
        //SourceDestinationURN		nvarchar(512) not null,
        //SourceDestinationTypeURN	nvarchar(512) not null,
        //SourceDestinationID		bigint		  null,
        //SourceDestinationTypeID	bigint		  null,
        //);

        public long EpcisEventId { get; set; }
        public bool IsSource { get; set; }
        public string SourceDestinationUrn { get; set; }
        public string SourceDestinationTypeUrn { get; set; }
        public long SourceDestinationId { get; set; }
        public long SourceDestinationTypeId { get; set; }
    }
}
