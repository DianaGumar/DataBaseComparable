using ConsoleAppExample.DAL;
using System;
using System.Collections.Generic;
using System.Text;

namespace ConsoleAppExample.View
{
    // simple DTO
    internal class Table
    {
        internal string FoolName;
        internal string SimpleName;
        internal string DirectoryName;
        internal string DBName;
        internal List<string> CellsNames;
    }

    internal static class TableView
    {
        // make presentable data view
        internal static StringBuilder CheckTablesSimilarityView(string connStr, Table table, Table table2)
        {
            StringBuilder sb = new StringBuilder();

            try
            {
                var data = GeneralDBOperations.CheckTablesSimilarity(connStr, table.FoolName, 
                    table2.FoolName, table.CellsNames.ToArray());

                sb.Append($"{ table.FoolName }\n{ table2.FoolName }\n");
                sb.Append($"{string.Join("|", table.CellsNames)}\n");
                if (data.Count > 0)
                {                
                    data.ForEach(str => {
                        str.ForEach(item => { sb.Append(item); sb.Append("\t"); }); sb.Append("\n");
                    });
                }
            }
            catch (Exception e)
            {
                // после добавления проверки xml в запрос- убрать try catch
                sb.Append($"{e.Message}\n");
            }

            return sb;
        }

        // get tables names and cells names from db
        internal static List<Table> GetTablesInfo(string connStr)
        {
            var tables = new List<Table>();

            var namesRepository = GeneralDBOperations.GetDBTablesFoolNames(connStr);
            namesRepository.ForEach(n =>
            {
                var cellsNames = GeneralDBOperations.GetTableCellsNames(connStr, n[1], n[2]);
                tables.Add(new Table
                {
                    DBName = n[0],
                    DirectoryName = n[1],
                    SimpleName = n[2],
                    FoolName = $"[{n[0]}].[{n[1]}].[{n[2]}]",
                    CellsNames = cellsNames
                });
            });

            return tables;
        }
    }
}
