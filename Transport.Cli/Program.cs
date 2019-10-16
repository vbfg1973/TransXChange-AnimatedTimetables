using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Serialization;
using Transport.BusStops;
using Transport.TransXChange;

namespace Transport.Cli
{
    class Program
    {
        static void Main(string[] args)
        {
            var path = args[0];

            if (Directory.Exists(path))
            {
                foreach (var file in Directory.EnumerateFiles(path).Where(x => x.EndsWith(".xml")))
                {
                    //Console.WriteLine(file);
                    var txc = new TXCParser(file);
                }
            }

            else if (File.Exists(path))
            {
                //Console.WriteLine(path);
                var txc = new TXCParser(path);
            }
        }
    }
}
