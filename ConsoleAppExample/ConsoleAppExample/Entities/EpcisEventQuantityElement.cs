namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventQuantityElement
    {
        //-----------------------------------------------------------------
        //-- Tabelle zum Zwischenspeichern der QuantityElements
        //-----------------------------------------------------------------

        //create table #EPCISEvent_QuantityElement
        //(
        //EPCISEventID			bigint			not null,
        //EPCClassURN			nvarchar(512)	not null,
        //EPCClassID			bigint			null,
        //Quantity				float(53)		not null,
        //UOM					nchar(3)		not null default (''),
        //IsInput				bit				not null,
        //IsOutput				bit				not null,
        //QuantityElementID		bigint			null,
        //);

        public long EpcisEventId { get; set; }
        public string EpcClassUrn { get; set; }
        public long EpcClassId { get; set; }
        public float Quantity { get; set; }
        public string Uom { get; set; }
        public bool IsInput { get; set; }
        public bool IsOutput { get; set; }
        public long QuantityElementId { get; set; }
    }
}
