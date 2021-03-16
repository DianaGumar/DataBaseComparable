namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventValueStringValueString
    {
        //create table #EPCISEvent_Value_String_Value_String
        //(
        //EPCISEvent_ValueID  bigint      not null,
        //Value_StringID	  bigint      not null
        //);

        public long EpcisEventValueId { get; set; }
        public long ValueStringId { get; set; }
    }
}
