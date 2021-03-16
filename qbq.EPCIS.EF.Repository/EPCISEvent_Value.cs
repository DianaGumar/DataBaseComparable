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
    
    public partial class EPCISEvent_Value
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public EPCISEvent_Value()
        {
            this.EPCISEvent_Value_Hierarchy = new HashSet<EPCISEvent_Value_Hierarchy>();
            this.EPCISEvent_Value_Hierarchy1 = new HashSet<EPCISEvent_Value_Hierarchy>();
            this.EPCISEvent_Value_String = new HashSet<EPCISEvent_Value_String>();
        }
    
        public long ID { get; set; }
        public long EPCISEventID { get; set; }
        public long ValueTypeID { get; set; }
        public long DataTypeID { get; set; }
    
        public virtual EPCISEvent EPCISEvent { get; set; }
        public virtual EPCISEvent_Value_Datetime EPCISEvent_Value_Datetime { get; set; }
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<EPCISEvent_Value_Hierarchy> EPCISEvent_Value_Hierarchy { get; set; }
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<EPCISEvent_Value_Hierarchy> EPCISEvent_Value_Hierarchy1 { get; set; }
        public virtual EPCISEvent_Value_Numeric EPCISEvent_Value_Numeric { get; set; }
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<EPCISEvent_Value_String> EPCISEvent_Value_String { get; set; }
        public virtual Vocabulary Vocabulary { get; set; }
        public virtual Vocabulary Vocabulary1 { get; set; }
    }
}
