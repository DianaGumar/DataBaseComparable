using System;

namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventValue
    {
        //-----------------------------------------------------------------
        //-- Tabelle zum Zwischenspeichern der Values wie z.B. quantity und extension fields
        //-----------------------------------------------------------------

        //create table #EPCISEvent_Value
        //(
        //ValueTypeURN  		nvarchar(512)	not null,
        //ValueTypeTypeURN  	nvarchar(512)	not null,
        //DataTypeURN			nvarchar(512)	not null,
        //DataTypeTypeURN		nvarchar(512)	not null,
        //ValueTypeID			bigint			null,
        //ValueTypeTypeID		bigint			null,
        //DataTypeID			bigint			null,
        //DataTypeTypeID		bigint			null,
        //EPCISEventID  		bigint			not null,
        //IntValue  			bigint			null,
        //FloatValue			float			null,
        //TimeValue 			datetimeoffset	null,
        //StringValue   		nvarchar(max)	null,
        //ParentURN 			nvarchar(512)	null,
        //Depth		    		int				not null,
        //ExtensionType         bit             not null
        //);

        public string ValueTypeUrn { get; set; }
        public string ValueTypeTypeUrn { get; set; }
        public string DataTypeUrn { get; set; }
        public string DataTypeTypeUrn { get; set; }
        public long ValueTypeId { get; set; }
        public long ValueTypeTypeId { get; set; }
        public long DataTypeId { get; set; }
        public long DataTypeTypeId { get; set; }
        public long EpcisEventId { get; set; }
        public int IntValue { get; set; }
        public float FloatValue { get; set; }
        public DateTimeOffset TimeValue { get; set; }
        public string StringValue { get; set; }
        public string ParentUrn { get; set; }
        public int Depth { get; set; }
        public bool ExtensionType { get; set; }
    }
}
