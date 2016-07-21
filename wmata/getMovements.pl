#!/usr/bin/env perl

use strict;
use warnings;
use Mojo::Redis2;
use Mojo::UserAgent;
use Mojo::IOLoop;
use Cpanel::JSON::XS;

my $api_key = "6b700f7ea9db408e9745c207da7ca827";
my ($trains, $buses);
my $coder = Cpanel::JSON::XS->new->ascii->allow_nonref;
my $redis = Mojo::Redis2->new(url => "redis://localhost:6379/2");
my $ua = Mojo::UserAgent->new;

$buses = Mojo::IOLoop->recurring(5 => sub {
                $ua->get('https://api.wmata.com/Bus.svc/json/jBusPositions' => {api_key => $api_key} => sub {
                my ($ua, $tx) = @_;
                if ($tx->success) {
                        my $json = $coder->decode($tx->res->body);
                        $json->{retrieved_on} = time;
                        $redis->rpush("buses",$coder->encode($json))
                        }
                });
        });

Mojo::IOLoop->timer(2.5 => sub { # Stagger calls by 2.5 seconds so both IOLoops aren't making requests at the same time
	$trains = Mojo::IOLoop->recurring(5 => sub {
		$ua->get('https://api.wmata.com/TrainPositions/TrainPositions?contentType=JSON' => {api_key => $api_key} => sub {
		my ($ua, $tx) = @_;
		if ($tx->success) {
			my $json = $coder->decode($tx->res->body);
			$json->{retrieved_on} = time;	
			$redis->rpush("trains",$coder->encode($json))
			}
		});
	});
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
