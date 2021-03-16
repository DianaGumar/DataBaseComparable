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
        internal static List<List<object>> CheckTablesSimilarity(string StrConn, string foolTableName, string foolTableName2)
        {
            var data = new List<List<object>>();

            SqlConnection conn = new SqlConnection(StrConn);
            SqlCommand cmd = new SqlCommand();

            cmd.Connection = conn;
            cmd.CommandText = $"SELECT * FROM {foolTableName2} EXCEPT SELECT * FROM {foolTableName}";

            cmd.Connection.Open();

            SqlDataReader reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                object[] inside = new object[reader.FieldCount];
                reader.GetValues(inside);

                var internalData = new List<object>();
                foreach (var item in inside)
                {
                    internalData.Add(item);
                }
                data.Add(internalData);
            }

            reader.Close();
            cmd.Dispose();
            conn.Close();

            return data;
        }
    }
}
