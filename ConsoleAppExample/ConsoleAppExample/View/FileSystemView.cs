using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleAppExample.View
{
    internal static class FileSystemView
    {
        internal static void ExportToTxt(String path, String data)
        {
            using (StreamWriter sw = new StreamWriter(path, false, System.Text.Encoding.UTF8))
            {
                sw.WriteLine(data);
            }
        }
    }
}
