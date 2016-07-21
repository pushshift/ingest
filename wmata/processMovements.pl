#!/usr/bin/perl

use Sys::RunAlone silent=>1;
use strict;
use warnings;
use Redis::Fast;
use Cpanel::JSON::XS;
use DBI;
use Date::Parse;
use POSIX;

my $driver   = "Pg";
my $database = "wmata";
my $dsn = "DBI:$driver:dbname=$database;host=127.0.0.1;port=5432";
my $userid = "postgres";
my $password = "postgres";
my $dbh = DBI->connect($dsn, $userid, $password, { PrintError => 0, RaiseError => 1, ReadOnly => 0, AutoCommit => 0 }) or die $DBI::errstr;
my $insertTrainData = $dbh->prepare("INSERT INTO train_data(json) VALUES (?) ON CONFLICT DO NOTHING");
my $insertBusData = $dbh->prepare("INSERT INTO bus_data(json) VALUES (?) ON CONFLICT DO NOTHING");
my $r = Redis::Fast->new( server => "127.0.0.1:6379", on_connect => sub {$_[0]->select(2);} ) or die $!;
my $coder = Cpanel::JSON::XS->new->ascii->allow_nonref;

while (1) {

        my $data = $r->lrange("buses",0,99);
        my $num_of_elements = scalar @$data;

        for my $data_element (@$data) {
                my $json = decode_json($data_element);
		my $retrieved_on = $json->{retrieved_on};
		for my $busPosition (@{$json->{BusPositions}}) {
			$busPosition->{retrieved_on} = $retrieved_on;
			$busPosition->{TripStartTime} = str2time($busPosition->{TripStartTime},"ET");
			$busPosition->{TripEndTime} = str2time($busPosition->{TripEndTime},"ET");
			$busPosition->{DateTime} = str2time($busPosition->{DateTime},"ET");
			my $json_encoded = $coder->encode($busPosition);
			$insertBusData->execute($json_encoded);
			}
	}

        $dbh->commit or die $!;
        $r->ltrim("buses",$num_of_elements, -1) or die $!;

        $data = $r->lrange("trains",0,99);
        $num_of_elements = scalar @$data;

        for my $data_element (@$data) {
                my $json = decode_json($data_element);
                my $retrieved_on = $json->{retrieved_on};
                for my $trainPosition (@{$json->{TrainPositions}}) {
                        $trainPosition->{retrieved_on} = $retrieved_on;
                        my $json_encoded = $coder->encode($trainPosition);
                        $insertTrainData->execute($json_encoded);
                        }
        }

        $dbh->commit or die $!;
        $r->ltrim("trains",$num_of_elements, -1) or die $!;
        sleep(1);
}

__END__
