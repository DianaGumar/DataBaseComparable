namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventTransformationId
    {
        //-----------------------------------------------------------------
        //-- Tabelle zum Zwischenspeichern der TransformationID
        //-----------------------------------------------------------------

        //create table #EPCISEvent_TransformationID
        //(
        //EPCISEventID  				bigint		  not null,
        //TransformationIDURN			nvarchar(512) not null,
        //TransformationIDID			bigint		  null,
        //);

        public long EpcisEventId { get; set; }
        public string TransformationIdUrn { get; set; }
        public long TransformationIdId { get; set; }
    }
}
