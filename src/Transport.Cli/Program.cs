using System;
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

            var degreeParallelism = new ExecutionDataflowBlockOptions()
            {
                MaxDegreeOfParallelism = Environment.ProcessorCount
            };

            var linkOptions = new DataflowLinkOptions { PropagateCompletion = true };

            var fileDiscoveryBlock = new TransformManyBlock<string, string>(dirName =>
                {
                    return Directory.EnumerateFiles(path).Where(x => x.EndsWith(".xml"));
                });

            var processingBlock = new ActionBlock<string>(file =>
            {
                Console.WriteLine(file);
                var txc = new TXCParser(file);
                var newFile = Path.ChangeExtension(file, "csv");
                txc.SaveCsv(newFile);

            }, degreeParallelism);

            if (Directory.Exists(path))
            {
                fileDiscoveryBlock.LinkTo(processingBlock, linkOptions);

                fileDiscoveryBlock.Post(path);

                fileDiscoveryBlock.Complete();
                processingBlock.Completion.Wait();
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
