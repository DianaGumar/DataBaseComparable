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
    
    public partial class EPCISEvent_Value_Numeric
    {
        public long EPCISEvent_ValueID { get; set; }
        public double Value { get; set; }
    
        public virtual EPCISEvent_Value EPCISEvent_Value { get; set; }
    }
}
