using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Xml.Serialization;
using Transport.BusStops;
using Transport.TransXChange;
using System.Threading.Tasks.Dataflow;


namespace Transport.Cli
{
    class Program
    {
        static void Main(string[] args)
        {
            var path = args[0];

            var dict = new ConcurrentDictionary<string, ConcurrentBag<string>>();

            var degreeParallelism = new ExecutionDataflowBlockOptions()
            {
                MaxDegreeOfParallelism = Environment.ProcessorCount
            };

            var linkOptions = new DataflowLinkOptions { PropagateCompletion = true };

            var fileDiscoveryBlock = new TransformManyBlock<string, string>(dirName =>
                {
                    return Directory.EnumerateFiles(path).Where(x => x.EndsWith(".xml"));
                });

            var routeBlock = new TransformManyBlock<string, JourneyLink>((file =>
            {
                Console.WriteLine(file);
                var txc = new TXCParser(file);

                return txc.ParseXML();
            }));

            var processingBlock = new ActionBlock<string>(file =>
            {
                //Console.WriteLine(file);
                var txc = new TXCParser(file);
                var newFile = Path.ChangeExtension(file, "csv");
                txc.SaveCsv(newFile);
            }, degreeParallelism);

            var routeSortBlock = new ActionBlock<JourneyLink>(jl =>
            {
                if (!dict.ContainsKey(jl.FromStop))
                {
                    dict.TryAdd(jl.FromStop, new ConcurrentBag<string>());
                }

                if (!dict[jl.FromStop].Contains(jl.ToStop))
                {
                    dict[jl.FromStop].Add(jl.ToStop);
                }

            }, degreeParallelism);

            if (Directory.Exists(path))
            {
                //fileDiscoveryBlock.LinkTo(processingBlock, linkOptions);
                fileDiscoveryBlock.LinkTo(routeBlock, linkOptions);
                routeBlock.LinkTo(routeSortBlock, linkOptions);

                fileDiscoveryBlock.Post(path);

                fileDiscoveryBlock.Complete();
                routeSortBlock.Completion.Wait();

                var cmd = "CREATE TABLE topology.routes (id SERIAL, from VARCHAR(15), to VARCHAR(15));";

                var l = new List<string>();
                l.Add(cmd);
                l.Add("COPY topology.routes (id, from, to) FROM stdin;");
                var count = 1;
                foreach (var from in dict.Keys)
                {
                    foreach (var to in dict[from])
                    {
                        l.Add($"{count++}\t{from}\t{to}");
                    }
                }
                l.Add("\\.");

                var newPath = Path.Combine(path, "routes");


                if (File.Exists(newPath))
                {
                    File.Delete(newPath);
                }

                File.WriteAllLines(newPath, l);
            }

            else if (File.Exists(path))
            {
                processingBlock.Post(path);
                processingBlock.Complete();
                processingBlock.Completion.Wait();
            }
        }
    }
}
