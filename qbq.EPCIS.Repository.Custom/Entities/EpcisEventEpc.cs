namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventEpc
    {
        //-----------------------------------------------------------------
        //-- Tabelle zum Zwischenspeichern der EPCs
        //-----------------------------------------------------------------
	
        //create table #EPCISEvent_EPC
        //(
        //EPCURN		nvarchar(512)	not null,
        //EPCID			bigint			null,
        //EPCISEventID	bigint			not null,
        //IsParentID	bit				not null,
        //IsInput		bit				not null,
        //IsOutput		bit				not null,
        //);

        public string EpcUrn { get; set; }
        public long EpcId { get; set; }
        public long EpcisEventId { get; set; }
        public bool IsParent { get; set; }
        public bool IsInput { get; set; }
        public bool IsOutput { get; set; }
    }
}
