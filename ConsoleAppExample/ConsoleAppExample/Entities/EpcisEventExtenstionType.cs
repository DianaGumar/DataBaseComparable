namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventExtenstionType
    {
        //-----------------------------------------------------------------
        //-- Tabelle zum Zwischenspeichern der Extension-Typen wie
        //-----------------------------------------------------------------

        //create table #EPCISEvent_ExtenstionType
        //(
        //EPCISEventID		   bigint			not null,
        //ExtensionTypeURN	   nvarchar(512)	not null,
        //ExtensionTypeTypeURN nvarchar(512)	not null
        //);

        public long EpcisEventId { get; set; }
        public string ExtensionTypeUrn { get; set; }
        public string ExtensionTypeTypeUrn{ get; set; }
    }
}
