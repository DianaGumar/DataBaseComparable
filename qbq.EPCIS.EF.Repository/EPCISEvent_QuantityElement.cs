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
    
    public partial class EPCISEvent_QuantityElement
    {
        public long ID { get; set; }
        public long EPCISEventID { get; set; }
        public bool IsInput { get; set; }
        public bool IsOutput { get; set; }
        public long QuantityElementID { get; set; }
    
        public virtual EPCISEvent EPCISEvent { get; set; }
        public virtual QuantityElement QuantityElement { get; set; }
    }
}
