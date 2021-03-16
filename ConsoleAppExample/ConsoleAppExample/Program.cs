using ConsoleAppExample.DAL;
using qbq.EPCIS.Repository.Custom.Business;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace ConsoleAppExample
{
    class Program
    {
        static void Main(string[] args)
        {
            //var executed = new DateTime();
            //executed = DateTime.Now;

            //var client = "urn:quibiq:epcis:cbv:client:gmos";
            //var pathToXml = @"E:\MBycycle\ConsoleApp1\ConsoleAppExample\ConsoleAppExample\TestApp\TestData\1.65MB 907Events.xml";
            //var xEpcisEventDoc = XDocument.Load(pathToXml);

            //Console.WriteLine((DateTime.Now - executed).ToString());
            //executed = DateTime.Now;

            //string StrConn = @"Data Source=DESKTOP-137JOC2;Database=qbq.EPCIS.Repository2;Integrated Security=True;Timeout=60";

            //SqlConnection conn = new SqlConnection(StrConn);
            //SqlCommand cmd = new SqlCommand();
            //cmd.Connection = conn;
            //cmd.CommandText = "[Import].[usp_Import_Event_to_Queue]";
            //cmd.CommandType = System.Data.CommandType.StoredProcedure;
            //cmd.CommandTimeout = 60;

            //cmd.Parameters.AddWithValue("@Client", client);
            //cmd.Parameters.AddWithValue("@EPCISEvent", xEpcisEventDoc.ToString());

            //cmd.Connection.Open();

            //var reader = cmd.ExecuteXmlReader();
            //var retMsg = XDocument.Load(reader).ToString();

            //cmd.Dispose();
            //cmd.Connection.Close();

            //Console.WriteLine(retMsg);
            //Console.WriteLine((DateTime.Now - executed).ToString());
            //Console.ReadLine();


            string StrConnRepository = @"Data Source=DESKTOP-137JOC2;Database=qbq.EPCIS.Repository;Integrated Security=True;Timeout=60";
            string StrConnRepository2 = @"Data Source=DESKTOP-137JOC2;Database=qbq.EPCIS.Repository2;Integrated Security=True;Timeout=60";

            // look likes [qbq.EPCIS.Repository].[Event].[BusinessTransactionID]
            var namesRepository = GeneralDBOperations.GetDBTablesNames(StrConnRepository);
            var namesRepository2 = GeneralDBOperations.GetDBTablesNames(StrConnRepository2);

            StringBuilder sb = new StringBuilder();

            for (int i = 0, count; i < namesRepository.Count; i++)
            {
                try
                {
                    count = GeneralDBOperations.CheckTablesSimilarity(StrConnRepository,
                    namesRepository[i], namesRepository2[i]);

                    //if (count > 0) 
                    sb.Append($"{count} \t {namesRepository[i]} \t | {namesRepository2[i]}\n");
                }
                catch(Exception e)
                {
                    sb.Append($"uncomparable {namesRepository[i]} | {namesRepository2[i]}\n");
                }
            }
            
            Console.WriteLine(sb.ToString());
            Console.ReadLine();
        }
    }
}
