using System;
using System.Data.SqlClient;
using System.Xml.Linq;
using qbq.EPCIS.Repository.Custom.Business;

namespace qbq.EPCIS.Repository.Custom.TestApp
{
    class Program
    {
        static void Main(string[] args)
        {

	        var executed = new DateTime();

	        executed = DateTime.Now;
	        
            ///////////////////////////////////////////
            //  hard-code parameters values
            ///////////////////////////////////////////
            
            var client = "urn:quibiq:epcis:cbv:client:gmos";

   //          var xEpcisEventDoc = XDocument.Parse(@"
			// <epcis:EPCISDocument xmlns:epcis='urn:epcglobal:epcis:xsd:1'
			//                      xmlns:frische='http://migros.net/frische/'
			//                      xmlns:migros='http://migros.net/migros/'
			//                      xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
			//                      xmlns:sbdh='http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader'
			//                      creationDate='2014-09-11T11:30:47.0Z'
			//                      schemaVersion='1.1'>
			// 	<EPCISHeader>
			// 		<sbdh:StandardBusinessDocumentHeader>
			// 			<sbdh:HeaderVersion>1.0</sbdh:HeaderVersion>
			// 			<sbdh:Sender>
			// 				<sbdh:Identifier Authority='EAN.UCC'>0614141107340</sbdh:Identifier>
			// 			</sbdh:Sender>
			// 			<sbdh:Receiver>
			// 				<sbdh:Identifier Authority='EAN.UCC'>0614141107340</sbdh:Identifier>
			// 			</sbdh:Receiver>
			// 			<sbdh:DocumentIdentification>
			// 				<sbdh:Standard>EPCglobal</sbdh:Standard>
			// 				<sbdh:TypeVersion>1.0</sbdh:TypeVersion>
			// 				<sbdh:InstanceIdentifier>M050_Request</sbdh:InstanceIdentifier>
			// 				<sbdh:Type>Events</sbdh:Type>
			// 				<sbdh:CreationDateAndTime>2006-06-07T05:30:00.0Z</sbdh:CreationDateAndTime>
			// 			</sbdh:DocumentIdentification>
			// 		</sbdh:StandardBusinessDocumentHeader>
			// 	</EPCISHeader>
			// 	<EPCISBody>
			// 		<EventList>
			// 			<extension>
			// 				<TransformationEvent>
			// 					<eventTime>2020-11-09T04:00:00Z</eventTime>
			// 					<recordTime>2020-11-09T04:00:06Z</recordTime>
			// 					<eventTimeZoneOffset>+00:00</eventTimeZoneOffset>
			// 					<parentID>urn:epc:id:sscc:0614141.1234567890</parentID>
			// 					<childEPCs>
			// 						<epc>urn:epc:id:sgtin:0614141.107346.2017</epc>
			// 						<epc>urn:epc:id:sgtin:0614141.107346.2018</epc>
			// 					</childEPCs>
			// 					<inputEPCList>
			// 						<epc>urn:epc:id:sgtin:8436541.060000.0</epc>
			// 					</inputEPCList>
			// 					<inputQuantityList>
			// 						<quantityElement>
			// 							<epcClass>urn:epc:class:lgtin:8436541.060000.291702</epcClass>
			// 							<quantity>528</quantity>
			// 							<uom>KGM</uom>
			// 						</quantityElement>
			// 					</inputQuantityList>
			// 					<outputEPCList>
			// 						<epc>urn:epc:id:sgtin:7617027.095350.0</epc>
			// 					</outputEPCList>
			// 					<outputQuantityList>
			// 						<quantityElement>
			// 							<epcClass>urn:epc:class:lgtin:7617027.095350.291702</epcClass>
			// 							<quantity>528</quantity>
			// 							<uom>KGM</uom>
			// 						</quantityElement>
			// 					</outputQuantityList>
			// 					<transformationID>urn:epcglobal:cbv:xform:0614141123452:ABC123</transformationID>
			// 					<bizStep>urn:epcglobal:cbv:bizstep:receiving</bizStep>
			// 					<bizLocation>
			// 						<id>urn:epc:id:sgln:76300438.0000.0</id>
			// 					</bizLocation>
			// 					<bizTransactionList>
			// 						<bizTransaction type='urn:epcglobal:cbv:btt:po'>urn:epcglobal:cbv:bt:7630043800003:291702</bizTransaction>
			// 					</bizTransactionList>
			// 					<sourceList>
			// 						<source type='http://migros.net/migros/ele/dest/SU'>urn:epc:id:sgln:8436541.60000.0</source>
			// 					</sourceList>
			// 					<quantity>2200</quantity>
			// 					<epcList>
			// 						<epc>urn:epc:id:sgtin:7613269.066708.0</epc>
			// 						<epc>urn:epc:id:sgtin:7617027.055237.0</epc>
			// 						<epc>urn:epc:id:sgtin:7617027.085546.0</epc>
			// 						<epc>urn:epc:id:sgtin:7610632.095312.0</epc>
			// 						<epc>urn:epc:id:sgtin:7617027.055275.0</epc>
			// 						<epc>urn:epc:id:sgtin:7617027.084527.0</epc>
			// 						<epc>urn:epc:id:sgtin:7617027.055193.0</epc>
			// 						<epc>urn:epc:id:sgtin:7617027.055209.0</epc>
			// 						<epc>urn:epc:id:sgtin:7613269.058370.0</epc>
			// 						<epc>urn:epc:id:sgtin:7617027.055446.0</epc>
			// 						<epc>urn:epc:id:sgtin:7617027.095350.0</epc>
			// 					</epcList>
			// 					<action>ADD</action>
			// 			        <bizStep>urn:epcglobal:cbv:bizstep:commissioning</bizStep>
			// 			        <disposition>urn:epcglobal:cbv:disp:active</disposition>
			// 			        <readPoint>
			// 			          <id>urn:epc:id:sgln:0614141.73467.0</id>
			// 			        </readPoint>
			// 			        <bizLocation>
			// 			          <id>urn:epc:id:sgln:0614141.73467.1</id>
			// 			        </bizLocation>
			// 					<ilmd>
			// 						<migros:ArticleAttrSaleBeforeDate>2014-12-14T12:00:00</migros:ArticleAttrSaleBeforeDate>
			// 						<migros:ArticleAttrExpiryDate>2015-05-01T12:00:00</migros:ArticleAttrExpiryDate>
			// 					</ilmd>
			// 				</TransformationEvent>
			// 			</extension>
			// 		</EventList>
			// 	</EPCISBody>
			// </epcis:EPCISDocument>
			// ");
            
            var xEpcisEventDoc = XDocument.Load(@"d:\work\quibiq\EPCIS-V2\Source\EPCIS.Standard\Main\qbq.EPCIS\qbq.EPCIS.Repository.Custom\TestApp\TestData\1.65MB 907Events.xml");

            var importer = new EventImporter();
            
            importer.ImportEvents(xEpcisEventDoc, client);
            
            Console.WriteLine((DateTime.Now - executed).ToString());
            executed = DateTime.Now;
            
            var sqlCmd = "[Import].[usp_Import_Event_to_Queue]";
            var cmd = new SqlCommand(sqlCmd, new SqlConnection(@"Server=DESKTOP-TCQPHAV\SQLEXPRESS;Database=qbq.EPCIS.RepositoryOld;Integrated Security=SSPI;Timeout=45"))
            {
	            CommandType = System.Data.CommandType.StoredProcedure
            };
            
            cmd.Parameters.AddWithValue("@Client", client);
            cmd.Parameters.AddWithValue("@EPCISEvent", xEpcisEventDoc.ToString());
            cmd.Connection.Open();
            
            var reader = cmd.ExecuteXmlReader();
            var retMsg = XDocument.Load(reader).ToString();
            
            cmd.Connection.Close();
            Console.WriteLine(retMsg);
            

            Console.WriteLine((DateTime.Now - executed).ToString());
            
        }
    }
}