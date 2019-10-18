#!/usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use Text::CSV_XS;

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

my $file = shift;

if (open (my $fh, "<", $file)) {
	my @header = $csv->getline ($fh);
	$csv->column_names(@header);
	say "BEGIN;";
	while (my $row = $csv->getline_hr($fh)) {
		foreach my $k (keys %{$row}) {
			$row->{$k} =~ s/\'/\'\'/g;
		}
		
		say "INSERT INTO stops (atcocode,commonname,street,bearing,easting,northing,stoptype,busstoptype,timingstatus) VALUES ('$row->{ATCOCode}','$row->{CommonName}','$row->{Street}','$row->{Bearing}',$row->{Easting},$row->{Northing},'$row->{StopType}','$row->{BusStopType}','$row->{TimingStatus}');";
    }

	say "COMMIT;";
	say "ANALYZE stops;";
}
