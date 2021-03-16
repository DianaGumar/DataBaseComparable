using qbq.EPCIS.EF.Repository;

namespace qbq.EPCIS.Repository.Custom.Entities
{
    class EpcisEventIds
    {
        //-----------------------------------------------------------------
        //-- Mapping-Tabelle zwischen SP und Tabellen EPCISEventID
        //-----------------------------------------------------------------

        //create table #EPCISEventIDs
        //(
        //    EPCISEventID		     bigint		  not null PRIMARY KEY,
        //    TechnicalEPCISEventID  bigint       not null
        //);

        public long EpcisEventId { get; set; }
        public EPCISEvent TechnicalEpcisEvent { get; set; }
    }
}
