using System;
using System.Collections.Generic;
using System.Xml.Serialization;

namespace Transport.BusStops
{
    public class Stop
    {
        public string ATCOCode { get; set; }
        public string NaptanCode { get; set; }
        public string PlateCode { get; set; }
        public string CleardownCode { get; set; }
        public string CommonName { get; set; }
        public string CommonNameLang { get; set; }
        public string ShortCommonName { get; set; }
        public string ShortCommonNameLang { get; set; }
        public string Landmark { get; set; }
        public string LandmarkLang { get; set; }
        public string Street { get; set; }
        public string StreetLang { get; set; }
        public string Crossing { get; set; }
        public string CrossingLang { get; set; }
        public string Indicator { get; set; }
        public string IndicatorLang { get; set; }
        public string Bearing { get; set; }
        public string NptgLocalityCode { get; set; }
        public string LocalityName { get; set; }
        public string ParentLocalityName { get; set; }
        public string GrandParentLocalityName { get; set; }
        public string Town { get; set; }
        public string TownLang { get; set; }
        public string Suburb { get; set; }
        public string SuburbLang { get; set; }
        public string LocalityCentre { get; set; }
        public string GridType { get; set; }
        public int Easting { get; set; }
        public int Northing { get; set; }
        public double Longitude { get; set; }
        public double Latitude { get; set; }
        public string StopType { get; set; }
        public string BusStopType { get; set; }
        public string TimingStatus { get; set; }
        public string DefaultWaitTime { get; set; }
        public string Notes { get; set; }
        public string NotesLang { get; set; }
        public string AdministrativeAreaCode { get; set; }
        public DateTime? CreationDateTime { get; set; }
        public DateTime? ModificationDateTime { get; set; }
        public int RevisionNumber { get; set; }
        public string Modification { get; set; }
        public string Status { get; set; }
    }
}