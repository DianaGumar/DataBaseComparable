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
    
    public partial class VocabularyType_Client
    {
        public long ClientID { get; set; }
        public long VocabularyTypeID { get; set; }
        public bool Deleted { get; set; }
    
        public virtual Vocabulary Vocabulary { get; set; }
        public virtual VocabularyType VocabularyType { get; set; }
    }
}
