using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml;
using System.Xml.Serialization;
using CsvHelper;
using Transport.TransXChange.Xml;

namespace Transport.TransXChange
{
    public class TXCParser
    {
        private string _path;

        private Dictionary<string, JourneyPatternSectionStructure> _dictJPS;
        private Dictionary<string, VehicleJourneyStructure> _dictJourneyByRef;

        public TXCParser(string path)
        {
            _path = path;

            _dictJPS = new Dictionary<string, JourneyPatternSectionStructure>();
            _dictJourneyByRef = new Dictionary<string, VehicleJourneyStructure>();

            ParseXML();
        }

        public void SaveCsv(string path)
        {
            using (var writer = new StreamWriter(path))
            {
                using (var csv = new CsvWriter(writer))
                {
                    csv.WriteRecords(this.ParseXML());
                }
            }
        }

        public IEnumerable<JourneyLink> ParseXML()
        {
            XmlReaderSettings settings = new XmlReaderSettings();
            settings.ConformanceLevel = ConformanceLevel.Fragment;
            settings.IgnoreWhitespace = true;
            settings.IgnoreComments = true;

            using (XmlReader reader = XmlReader.Create(_path, settings))
            {
                XmlSerializer SerializerObj = new XmlSerializer(typeof(Xml.TransXChange));
                Xml.TransXChange txc = (Xml.TransXChange) SerializerObj.Deserialize(reader);

                // Build a JourneyPattern index by the section code
                foreach (var journeyPattern in txc.JourneyPatternSections)
                {
                    _dictJPS.Add(journeyPattern.id, journeyPattern);
                }

                // Build an index of vehicle journeys by the JP ref code for easy lookup
                foreach (var journey in txc.VehicleJourneys.VehicleJourney)
                {
                    //string journeyCode = journey.VehicleJourneyCode;
                    //DateTime journeyDepartureTime = journey.DepartureTime;
                    //string journeyOperatorRef = journey.OperatorRef.Value;


                    string jpRef = string.Empty;
                    if (journey.Item is VehicleJourneyRefStructure)
                    {
                        jpRef = journey.Item as string;
                    }

                    else if (journey.Item != null)
                    {
                        jpRef = (journey.Item as JourneyPatternRefStructure).Value;
                    }

                    if (!string.IsNullOrEmpty(jpRef))
                    {
                        if (_dictJourneyByRef.ContainsKey(jpRef))
                        {
                            System.Diagnostics.Debug.WriteLine($"Duplicate key: {jpRef} in file {_path}");
                        }

                        else
                        {
                            _dictJourneyByRef.Add(jpRef, journey);
                        }
                    }
                }

                // Now link all services to their journeys via the jp reference
                // The VehicleJourney contains the parent sequence of stops which is
                // then overridden by any JourneyPatternSectionRefs contained in the
                // JourneyPattern.

                foreach (var service in txc.Services)
                {
                    var standardService = service.StandardService;
                    string destination = standardService.Destination.Value;
                    string origin = standardService.Origin.Value;

                    foreach (var journeyPattern in standardService.JourneyPattern)
                    {
                        string jpId = journeyPattern.id;

                        var journey = _dictJourneyByRef[jpId];
                        var timeDeparture = journey.DepartureTime;

                        var timingLinks = new Dictionary<string, VehicleJourneyTimingLinkStructure>();

                        if (journey.VehicleJourneyTimingLink != null)
                        {
                            foreach (var timingLink in journey.VehicleJourneyTimingLink)
                            {
                                timingLinks.Add(timingLink.id, timingLink);
                            }
                        }

                        var timeDelta = new TimeSpan();
                        var timeWaitFrom = new TimeSpan();
                        var timeWaitTo = new TimeSpan();

                        foreach (var jpsId in journeyPattern.JourneyPatternSectionRefs.Select(x => x.Value))
                        {
                            var jps = _dictJPS[jpsId];
                            foreach (var timingLink in jps.JourneyPatternTimingLink)
                            {
                                var timeRun = XmlConvert.ToTimeSpan(timingLink.RunTime);
                                timeWaitFrom = timeWaitTo;
                                timeWaitTo = new TimeSpan();
                                if (!string.IsNullOrEmpty(timingLink.To.WaitTime))
                                {
                                    timeWaitTo = XmlConvert.ToTimeSpan(timingLink.To.WaitTime);
                                }

                                if (timingLinks.ContainsKey(timingLink.id))
                                {
                                    var vTimingLink = timingLinks[timingLink.id];
                                    if (!string.IsNullOrEmpty(vTimingLink.RunTime))
                                    {
                                        timeRun = XmlConvert.ToTimeSpan(vTimingLink.RunTime);

                                        if ((vTimingLink.To != null) && (!string.IsNullOrEmpty(vTimingLink.To.WaitTime)))
                                        {
                                            timeWaitTo = XmlConvert.ToTimeSpan(vTimingLink.To.WaitTime);
                                        }
                                    }
                                }

                                //Console.WriteLine($"{service.ServiceCode}\t{journeyPattern.id}\t{(timeDeparture + timeDelta).TimeOfDay}\t{(timeDeparture + timeDelta + timeWaitFrom).TimeOfDay}\t{timingLink.id}\t{timingLink.From.StopPointRef.Value}\t{timingLink.To.StopPointRef.Value}\t{timeRun}\t{timeWaitFrom}\t{timeWaitTo}");
                                var journeyLink = new JourneyLink(
                                    serviceCode: service.ServiceCode,
                                    journeyPatternId: journeyPattern.id,
                                    arrive: (timeDeparture + timeDelta).TimeOfDay,
                                    depart: (timeDeparture + timeDelta + timeWaitFrom).TimeOfDay,
                                    fromStop: timingLink.From.StopPointRef.Value,
                                    toStop: timingLink.To.StopPointRef.Value,
                                    duration: timeRun);

                                yield return journeyLink;

                                timeDelta = timeDelta + timeWaitFrom + timeRun;
                            }
                        }
                    }
                }
            }
        }
    }
}
