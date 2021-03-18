using System.IO;
using System.Text;
using ConsoleAppExample.View;
using ConsoleAppExample.DAL;
using System.Linq;
using System.Configuration;

namespace ConsoleAppExample
{
    class Program
    {
        static void Main(string[] args)
        {
            string StrConnDb = ConfigurationManager.ConnectionStrings["DB"].ConnectionString;
            string StrConnDb2 = ConfigurationManager.ConnectionStrings["DB2"].ConnectionString;

            // get BD tables info
            var tablesDb = TableView.GetTablesInfo(StrConnDb);
            var tablesDb2 = TableView.GetTablesInfo(StrConnDb2);

            // delete keys
            tablesDb.ForEach(t => {
                t.CellsNames = GeneralDBOperations.GetTableCellsNamesExceptKeys(t.CellsNames);
            });
            tablesDb2.ForEach(t => {
                t.CellsNames = GeneralDBOperations.GetTableCellsNamesExceptKeys(t.CellsNames);
            });

            // delete tables that cells has keys only
            tablesDb = tablesDb.Where(t => t.CellsNames.Count > 0).ToList();
            tablesDb2 = tablesDb2.Where(t => t.CellsNames.Count > 0).ToList();

            // get unsimilar data
            var sb = new StringBuilder();
            if(tablesDb.Count == tablesDb.Count)
            {
                for (int i = 0; i < tablesDb.Count; i++)
                {
                    sb.Append(TableView.CheckTablesSimilarityView(StrConnDb,
                        tablesDb[i], tablesDb2[i]));
                    sb.Append("\n");
                }
            }

            // visualising
            var path = ConfigurationManager.AppSettings.Get("ResultPath");
            using (StreamWriter sw = new StreamWriter(path, false, Encoding.UTF8))
            {
                sw.WriteLine(sb.ToString());
            }
        }
    }
}
