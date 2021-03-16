using System.Collections.Generic;
using System.Data.SqlClient;

namespace ConsoleAppExample.DAL
{
    internal static class GeneralDBOperations
    {
        internal static List<string> GetDBTablesNames(string StrConn)
        {
            List<string> names = new List<string>();

            SqlConnection conn = new SqlConnection(StrConn);
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = conn;
            cmd.CommandText = "SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME " +
                "FROM INFORMATION_SCHEMA.TABLES where TABLE_TYPE = 'BASE TABLE';";

            cmd.Connection.Open();
            SqlDataReader reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                object[] inside = new object[reader.FieldCount];
                reader.GetValues(inside);

                names.Add($"[{inside[0]}].[{inside[1]}].[{inside[2]}]");
            }

            reader.Close();
            cmd.Dispose();
            conn.Close();

            return names;
        }

        // returns count unequal rows
        internal static int CheckTablesSimilarity(string StrConn, string foolTableName, string foolTableName2)
        {
            SqlConnection conn = new SqlConnection(StrConn);
            SqlCommand cmd = new SqlCommand();

            cmd.Connection = conn;
            cmd.CommandText = "select count(*) as TotalCount from (" +
                $"SELECT * FROM {foolTableName2} EXCEPT SELECT * FROM {foolTableName}) X;";
                //$"SELECT * FROM @foolTableName EXCEPT SELECT * FROM @foolTableName2) X;";

            cmd.Connection.Open();

            int countUnequal = (int)cmd.ExecuteScalar();

            cmd.Dispose();
            conn.Close();

            return countUnequal;
        }
    }
}
