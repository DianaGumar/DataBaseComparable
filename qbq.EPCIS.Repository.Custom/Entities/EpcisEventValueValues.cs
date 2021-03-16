using System;
using qbq.EPCIS.EF.Repository;

namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventValueValues
    {
        //create table #EPCISEvent_Value_Values
        //(
        //EPCISEvent_ValueID				bigint          not null,
        //ValueTypeURN						nvarchar(512)	not null,
        //DataTypeURN						nvarchar(512)	not null,
        //IntValue							bigint			null,
        //FloatValue						float			null,
        //TimeValue							datetimeoffset	null,
        //StringValue 						nvarchar(max)	null,
        //ParentURN							nvarchar(512)	not null,
        //Parent_EPCISEvent_ValueID			bigint			null,
        //Depth								int				not null
        //);

        public EPCISEvent_Value EpcisEventValue{ get; set; }
        public string ValueTypeUrn { get; set; }
        public string DataTypeUrn { get; set; }
        public int IntValue { get; set; }
        public float FloatValue { get; set; }
        public DateTimeOffset TimeValue { get; set; }
        public string StringValue { get; set; }
        public string ParentUrn { get; set; }
        public long ParentEpcisEventValueId { get; set; }
        public int Depth { get; set; }
    }
}
