//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace qbq.EPCIS.EF.Repository
{
    using System;
    using System.Collections.Generic;
    
    public partial class EPCISMasterData_Queue
    {
        public long ID { get; set; }
        public string Client { get; set; }
        public string EPCISMasterData { get; set; }
        public bool Processed { get; set; }
        public bool Error { get; set; }
        public string EPCISMasterDataOriginal { get; set; }
    }
}
