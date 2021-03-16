using System;

namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EventData
    {
        //-----------------------------------------------------------------
        //-- Tabelle zum Zwischenspeichern der Wurzel-Event Daten
        //-----------------------------------------------------------------
        //
        //create table #EventData
        //(
        //EPCISEventID			  bigint			 not null PRIMARY KEY IDENTITY(1,1),
        //[ClientID]              BIGINT             NOT NULL,
        //[EventTime]             DATETIME2 (0)      NOT NULL,
        //[RecordTime]            DATETIME2 (0)      NOT NULL,
        //[EventTimeZoneOffset]   DATETIMEOFFSET (7) NOT NULL,
        //[EPCISRepresentation]   XML                NOT NULL
        //);

        public long EpcisEventId { get; set; }
        public long ClientId { get; set; }
        public DateTime EventTime { get; set; }
        public DateTime RecordTime { get; set; }
        public DateTimeOffset EventTimeZoneOffset { get; set; }
        public string EpcisRepresentation { get; set; }
    }
}
