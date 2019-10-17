using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using CsvHelper;

namespace Transport.BusStops
{
    public class StopReader
    {
        private string _path;

        public StopReader(string path)
        {
            _path = path;
        }

        public IEnumerable<Stop> BusStops()
        {
            Console.WriteLine("Stops called");
            using (var reader = new StreamReader(_path))
            {
                Console.WriteLine("Reader read");
                using (var csv = new CsvReader(reader))
                {
                    Console.WriteLine("Generating list from file");
                    var stops = csv.GetRecords<Stop>();

                    foreach (var stop in stops)
                    {
                        yield return stop;
                    }
                }
            }
        }
    }
}