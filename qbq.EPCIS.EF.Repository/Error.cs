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
    
    public partial class Error
    {
        public long ErrorID { get; set; }
        public System.DateTime TimeStampGeneration { get; set; }
        public string AdditionalInformation { get; set; }
        public int ErrorNumber { get; set; }
        public int ErrorSeverity { get; set; }
        public string ErrorProcedure { get; set; }
        public string ErrorMessage { get; set; }
        public int ErrorLine { get; set; }
        public int ErrorState { get; set; }
        public long ObjectID { get; set; }
    }
}