using System;

namespace Transport.TransXChange
{
    public class JourneyLink
    {
        public string ServiceCode { get; private set; }
        public string JourneyPatternId { get; private set; }
        public TimeSpan Arrive { get; private set; }
        public TimeSpan Depart { get; private set; }
        public string FromStop { get; private set; }
        public string ToStop { get; private set; }
        public TimeSpan Duration { get; private set; }

        public JourneyLink(string serviceCode, string journeyPatternId, TimeSpan arrive, TimeSpan depart, string fromStop, string toStop, TimeSpan duration)
        {
            ServiceCode = serviceCode;
            JourneyPatternId = journeyPatternId;
            Arrive = arrive;
            Depart = depart;
            FromStop = fromStop;
            ToStop = toStop;
            Duration = duration;
        }
    }
}