using System.Collections.Generic;
using System.Data.SqlClient;
using System.Text.RegularExpressions;

namespace ConsoleAppExample.DAL
{
    internal static class GeneralDBOperations
    {
        // TableName like simple name without [..]
        internal static List<string> GetTableCellsNames(string strConn,
            string tableDirectory, string simpleTableName)
        {
            List<string> names = new List<string>();

            SqlConnection conn = new SqlConnection(strConn);
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = conn;
            cmd.CommandText = " SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS " +
                "WHERE TABLE_NAME = @TableName and TABLE_SCHEMA = @DirectoryName";
            cmd.Parameters.Add("@TableName", System.Data.SqlDbType.NVarChar).Value = simpleTableName;
            cmd.Parameters.Add("@DirectoryName", System.Data.SqlDbType.NVarChar).Value = tableDirectory;

            cmd.Connection.Open();
            SqlDataReader reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                object[] inside = new object[reader.FieldCount];
                reader.GetValues(inside);
                names.Add(inside[0].ToString());
            }

            reader.Close();
            cmd.Dispose();
            conn.Close();

            return names;
        }

        internal static List<string> GetTableCellsNamesExceptKeys(List<string> cells)
        {
            var newCellNames = new List<string>();

            // delete primary key and secondary key cells
            var rx = new Regex(@"(\w+)?ID", RegexOptions.IgnoreCase);
            cells.ForEach(c => { if (!rx.IsMatch(c)) newCellNames.Add(c); });
            cells = newCellNames;

            return newCellNames;
        }

        internal static List<List<string>> GetDBTablesFoolNames(string strConn)
        {
            var names = new List<List<string>>();

            SqlConnection conn = new SqlConnection(strConn);
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

                var internalData = new List<string>();
                foreach (var item in inside)
                {
                    internalData.Add(item.ToString());
                }
                names.Add(internalData);
            }

            reader.Close();
            cmd.Dispose();
            conn.Close();

            return names;
        }

        // returns count unequal rows
        internal static List<List<object>> CheckTablesSimilarity(string strConn, 
            string foolTableName, string foolTableName2)
        {
            var data = new List<List<object>>();

            SqlConnection conn = new SqlConnection(strConn);
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

        // returns count unequal rows by spesific tables cells
        internal static List<List<object>> CheckTablesSimilarity(string strConn, 
            string foolTableName, string foolTableName2, string[] specificTableCells)
        {
            var data = new List<List<object>>();
            var cellNamesFormating = specificTableCells.Length > 0 ? string.Join(",", specificTableCells): " * ";

            SqlConnection conn = new SqlConnection(strConn);
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = conn;
            // potentialy sql injection
            cmd.CommandText = $"SELECT {cellNamesFormating} FROM {foolTableName2} " +
                $"EXCEPT SELECT {cellNamesFormating} FROM {foolTableName}";

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
