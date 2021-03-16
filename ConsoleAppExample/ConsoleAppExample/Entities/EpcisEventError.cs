namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventError
    {
        //-----------------------------------------------------------------
        //-- Tabelle zum Zwischenspeichern von Eventfehlerklassen
        //-----------------------------------------------------------------
        //create table #EPCISEvent_Error
        //(
        //EPCISEventID  	 bigint			 not null,
        //Reason		 	 nvarchar(4000)  not null
        //);

        public long EpcisEventId { get; set; }
        public string Reason { get; set; }
    }
}
