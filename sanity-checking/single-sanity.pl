#!/usr/bin/perl

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Response;
use JSON qw( encode_json decode_json );
use DateTime;
use DateTime::Format::ISO8601;
use Data::Dumper;
use Digest::SHA qw(sha256_hex);

sub get_now() {
    my $dt = DateTime->now();
    my $isodate = DateTime::Format::ISO8601->parse_datetime( $dt ) . "";
    return $isodate;
}

use Net::Ping;
use IO::Socket;

use lib "/usr/lib/perfsonar/lib";

use perfSONAR_PS::Utils::Host qw( discover_primary_address );

my $EXPECTED_SERVICE_COUNT = 4;
my @EXPECTED_SERVICES=( "runner", "ticker", "scheduler", "archiver" );
my $host_status = {};
my $hosts = [];
my $hosts_obj = {};
my $config_archive;

$hosts_obj->{'hosts'} = $hosts;

my $check_esmond = 0;

# TODO: ADD CHECKS FOR ARCHIVE BACKLOGS

my $external_addresses = discover_primary_address(allow_rfc1918 => 1);

warn "external_addresses " . Dumper $external_addresses;

my $primary_address = $external_addresses->{'primary_address'};


#my $psconfig_file = $ARGV[0] || "testbed-nightly-psconfig.json";
#my $psconfig_file = $ARGV[0] || "psconfig-netsage-mesh.json";

#my $file = $psconfig_file;

warn `ls -l /app`;
warn `ls -l /usr/lib/perfsonar/lib/perfSONAR_PS/Utils/`;
#`./sanity.sh $psconfig_file`;
#open(FH,"<",$file) or die "$file file doesn't exists!\n";
#my $data = <FH>;

#my $psconfigObj = JSON::decode_json( $data );

#warn "psconfigObj: " . Dumper $psconfigObj;

#$hosts_obj->{'collection_name'} = $psconfigObj->{'_meta'}->{'display-name'} || "Host collection";
$hosts_obj->{'run_start'} = get_now();

#my $run_id = sha256_hex( $hosts_obj->{'collection_name'} . $hosts_obj->{'run_start'} );
#$hosts_obj->{'run_id'} = $run_id;

my @addresses = ();

my $address = $ARGV[0] or die "Error running; $!\n";

warn "address " . Dumper $address;

my $bundle = $ARGV[1];
my $repo = $ARGV[2];

push @addresses, $address;

$hosts_obj->{'collection_name'} = "$bundle $repo $address single host collection";

warn "addresses " . Dumper \@addresses;

warn "ifconfig " . `ifconfig`;

warn "primary_address " . Dumper $primary_address;

$hosts_obj->{'probe_address'} = $primary_address;

my $p = Net::Ping->new("icmp"); # for some reason icmp requires root
$p->bind( $primary_address );

foreach my $host (@addresses) {
	
	warn "************** MNG For each of hosts - host: $host \n";
	
    my $isodate = get_now();
    warn "$host is ";
    my $host_status = {};

    # add values for global (config-level values)
    $host_status->{'_meta'}->{'collection_name'} = $hosts_obj->{'collection_name'};
    #$host_status->{'_meta'}->{'run_id'} = $hosts_obj->{'run_id'};
    $host_status->{'_meta'}->{'probe_address'} = $hosts_obj->{'probe_address'};
    $host_status->{'_meta'}->{'_repo'} = $repo;
    $host_status->{'_meta'}->{'_bundle'} = $bundle;

    $host_status->{ 'check_start' } = $isodate;
    #warn "host_status " . Dumper $host_status;
    push @$hosts, $host_status;
    #warn "hosts " . Dumper $hosts;
    $host_status->{ 'hostname' } = $host;
    $host_status->{'ping'} = {};
    my $status = $host_status->{'ping'};
    if ( $p->ping($host, 2) ) {
        $status->{ 'reachable' } = \1;
        warn "HOST IS REACHABLE";

    } else {
        warn "NOT ";
        $status->{ 'reachable' } = \0;
        #warn "HOST IS NOT REACHABLE; SKIPPING"; TODO: review this
        #next;

    }
    warn "reachable via ping.\n";
    
  
    $host_status->{'pscheduler'} = {};
    
    warn "************** MNG For each of hosts - hoststatus: $host_status \n";
    
    
    
    $status = $host_status->{'pscheduler'};
    $status->{'rest_api'} = {};
    my $rest_status = $status->{'rest_api'};
    my $pscheduler_url = "https://" . $host . "/pscheduler/";
    my $pscheduler_status = run_http_status_check( $pscheduler_url );
    $rest_status->{'root'} = $pscheduler_status;

    warn "pscheduler url: " . $pscheduler_url;
    warn "pscheduler status: " . Dumper $pscheduler_status;

    $pscheduler_url = "https://" . $host . "/pscheduler/status";
    my $pscheduler_api_status = run_http_status_check( $pscheduler_url, 1 );
    $rest_status->{'status'} = $pscheduler_api_status;

    my $archive_backlog_url = "https://" . $host . "/pscheduler/stat/archiving/backlog";
    my $archive_backlog_status = run_http_status_check( $archive_backlog_url, 1 );
    $pscheduler_api_status->{'archiving_backlog'} = $archive_backlog_status->{ $host };

    warn "pscheduler api url: " . $pscheduler_url;
    warn "pscheduler api status: " . Dumper $pscheduler_api_status;

    my $services_status = check_pscheduler_services ($pscheduler_api_status );
    $status->{'services'} = $services_status;


    $host_status->{'toolkit'} = {};
    $status = $host_status->{'toolkit'};
    
      warn "************** MNG For each of hosts - hoststatus: $host_status \n";
    


    my $toolkit_url = "http://" . $host . "/toolkit/";
    my $toolkit_status = run_http_status_check( $toolkit_url );
    $status->{'http_status'} = $toolkit_status;

    my $toolkit_ssl_url = "https://" . $host . "/toolkit/";
    my $toolkit_ssl_status = run_http_status_check( $toolkit_ssl_url );
    $status->{'ssl_status'} = $toolkit_ssl_status;

    my $host_json_url = "https://$host/toolkit/services/host.cgi?method=get_summary";
    my $host_json_status = run_http_status_check( $host_json_url );
    $status->{'host_json_status'} = $host_json_status->{ $host };



    $host_status->{'ports'} = {};
    $status = $host_status->{'ports'};

    my $owamp_port_status = check_port( $host, 861, "tcp" );
    $status->{'owamp'} = $owamp_port_status;
    #$status->{'owamp'}->{'port'} = '861/tcp';

    $host_status->{'esmond'} = {};
    
      warn "************** MNG For each of hosts - hoststatus: $host_status \n";
    

    my $esmond_rest_url = "https://$host/esmond/perfsonar/archive/?limit=1";
    my $esmond_rest_status = run_http_status_check( $esmond_rest_url );
    $host_status->{'esmond'}->{'rest_api'} = $esmond_rest_status;
    my $rest_ok = ($esmond_rest_status->{'code'} == 200 ? \1 : \0);
    $host_status->{'esmond'}->{'rest_api'}->{'ok'} = $rest_ok;
        #if ($rest_ok ) {
        #$host_status->{'esmond'}->{'rest_api'} = $esmond_rest_status;
        #}



    if ( $check_esmond ) {
        $status = $host_status->{'esmond'};
        # TODO add http check for esmond
	    my $source_url = $config_archive . "?source=" . $host . "&limit=1&time-range=86400&format=json";

	    check_esmond_data( $source_url, $status, "source");
	    check_esmond_data( $source_url, $status, "source", "throughput");
	    check_esmond_data( $source_url, $status, "source", "histogram-owdelay");

	    my $dest_url = $config_archive . "?destination=" . $host . "&limit=1&time-range=86400&format=json";

	    check_esmond_data( $dest_url, $status, "destination");
	    check_esmond_data( $dest_url, $status, "destination", "throughput");
	    check_esmond_data( $dest_url, $status, "destination", "histogram-owdelay");
    }

    #sleep(1);

}
$p->close();

warn "STATUS\n"; 
#warn Dumper $host_status;
#warn Dumper $hosts;
$hosts_obj->{'run_end'} = get_now();

foreach my $host ( @{$hosts_obj->{'hosts'}} ) {
    print encode_json( $host );
    print "\n";
}

sub check_pscheduler_services {
    my ( $status_obj ) = @_;
    my $out_obj = {};
    my $services_ok = \0;
    my $message;
    
      warn "************** MNG $host checking pscheduler services \n";
    

    if ( !$status_obj ) {
        $message = "Status object undefined";
        #return { services_ok => 0,
        #    message => $message };
    } else {
        my $services = $status_obj->{'content'}->{'services'};
        my $services_overdue = [];
        my @missing_services = ();
        my @services_running = ();
        my @services_not_running = ();
        my $num_services = keys( %$services );
        warn "services " . Dumper $services;
        warn "num_services" . Dumper $num_services;
        if ( ( !$services ) || $num_services  == 0 ) {
            $message = "NO services were found.";
            @missing_services = @EXPECTED_SERVICES;
        } elsif ( $num_services < $EXPECTED_SERVICE_COUNT ) {
            $message = "Not all services were found";
            $out_obj->{'services_all'} = $services;
            $out_obj->{'num_services_found'} = $num_services;
            #$out_obj->{'services_found'} = keys %{$content->{'services'}};
            foreach my $name ( @EXPECTED_SERVICES ) {
                if ( ! grep( /^$name$/, keys %$services ) ) {
                    push @missing_services, $name;

                }

            }

        } else {
            $message = "All services found";
            #$out_obj->{'services_found'} = keys %{$content->{'services'}};
            @{$out_obj->{'services_found'}} = keys %$services;
            $out_obj->{'num_services_found'} = $num_services;



        }
        $out_obj->{'services_missing'} = \@missing_services;
        @services_not_running = @missing_services;
        foreach my $name ( keys %$services ) {
            my $service = $services->{ $name };
            warn "Name: $name";
            warn "Service: " . Dumper $service;
            my $is_overdue = \0;
            if ( $service->{'overdue'} && $service->{'overdue'} ne "PT0" ) {
                $is_overdue = \1;
                push @$services_overdue, $name;
                push @services_not_running, $name;
            } else {
                push @services_running, $name;

            }
            $out_obj->{'is_overdue'} = $is_overdue;

        }
        $out_obj->{'services_running'} = \@services_running;
        my $num_services_running = keys @services_running;
        $out_obj->{'num_services_running'} = $num_services_running;
        if ( $num_services_running == 4 ) {
            $services_ok = \1;
        }
        $out_obj->{'services_not_running'} = \@services_not_running;

        #warn "out_obj " . Dumper $out_obj;
        #warn "status_obj" . Dumper $status_obj;
        warn "services found " .  $num_services;
        $out_obj->{'services_overdue'} = $services_overdue;

    }
    $out_obj->{'services_ok'} = $services_ok;
    $out_obj->{'message'} = $message;
    return $out_obj;
    #return { services_ok => $services_ok, message => $message };

}

sub check_esmond_data {
	
	  warn "************** MNG $host checking esmound data \n";
	
    my ( $url, $status, $dir, $test_type ) = @_;

    my $req = HTTP::Request->new( 'GET', $url );
    if ( $test_type ) {
        $url .= "&event-type=" . $test_type;

    }
    warn "ESMOND archive url " .  $url;
    my $lwp = LWP::UserAgent->new;
    $lwp->timeout(30);
    my $res = $lwp->request( $req );
    warn "Querying for direction: $dir";
    if ( $res->is_success ) {
        warn "Request successful; content: ";
        #warn $res->as_string();
        #warn $res->request();
        #warn $res->headers()->as_string;
        # check json content type
        if ( $res->header( "Content-Type" ) eq "application/json" ) {
            #warn "OK: Content type is application/json";
            #warn "content " . Dumper $res->content();
            my $content = decode_json( $res->content() );
            my $num_results = @{ $content };
            warn "num_results esmond data: " . Dumper $num_results;
            my $key = "archive_results_$dir";
            if ( $test_type ) {
                $key .= "_" . $test_type;
                
            }
            if ( $num_results > 0 ) {
                warn "OK: results found in archive in direction $dir!";
                $status->{ $key } = \1;
            } else {
                warn "WARNING: NOT found in central archive in direction $dir!";
                $status->{ $key } = \0;

            }

        } else {
            warn "ERROR: Content type is not application/json in direction $dir";
        }

    } else {
        warn "Error retrieving MA data for host in direction $dir. Error:";
        warn $res->status_line();

    }

}

# inputs should be ????
# url
# expected status code??
# expected content
# expected array lengh
# json????
#
sub run_http_status_check {
	
	  warn "************** MNG $host checking HTTP status \n";
	
    my ( $url, $return_data ) = @_;
    my $status = {};
    warn "url " .  $url;
    my $req = HTTP::Request->new( 'GET', $url );
    my $lwp = LWP::UserAgent->new;
    $lwp->timeout(30);
    $lwp->ssl_opts( verify_hostname => 0 ,SSL_verify_mode => 0x00);
    my $res = $lwp->request( $req );
    if ( $res->is_success ) {
        $status->{'code'} = $res->code();
        $status->{'message'} = $res->message();
        $status->{'status_line'} = $res->status_line();
        $status->{'success'} = \1;
        warn "content type " . $res->header( "Content-Type" );
        if ( $res->header( "Content-Type" ) eq "application/json" ) {
            $status->{'content'} = decode_json( $res->content() ) if $return_data;
        } else {
            #warn "NON-JSON content: " . Dumper $res->content();
            $status->{'content'} = $res->content() if $return_data;

        }

    } else {
        $status->{'success'} = \0;
        if ( $res->code() == 404 ) {
            warn "404 URL not found";
            $status->{'code'} = $res->code();
            $status->{'message'} = $res->message();

        } elsif ( $res->code() == 500 ) {
            if ( $res->header("Client-Warning") &&  $res->header( "Client-Warning" ) ne "Internal response" ) {
                warn "500 ERROR!!!1! SERVER SIDE!!!";
                $status->{'code'} = "500";
                $status->{'message'} = $res->message();
            } else {
                warn "500 CLIENT SIDE ERROR!!!!";
                $status->{'code'} = "500";
                $status->{'message'} = "CLIENT SIDE ERROR, probably timeout? err: " . $res->message();

            }
        } else {
            $status->{'error'} = "Unable to make request! ";
            $status->{'code'} = $res->code();
            $status->{'message'} = $res->message();
            warn  "Unable to make request " . Dumper $res;
        }

    }
    return $status;
}

sub check_port {
	
	  warn "************** MNG $host checking port \n";
	
    my ( $host, $port, $protocol ) = @_;
    my $ret;
    my $message = "";
    my $status = {};
    my $prot = $protocol || 'TCP';
    my $sock = new IO::Socket::INET ( Timeout => 5, PeerAddr => $host, PeerPort => $port, Proto => $prot );
    warn "Connected to $host $port? socket:";
     if ($sock){
        warn "YES!"; 
         $ret = \1;
         $message = "successsfully connected to $host on $port via $prot";
     } else {
         warn "NO!";
         $ret = \0;
     }
    warn Dumper $sock;
    $status->{'open'} = $ret;
    $status->{'message'} = $message;
    $status->{'port'} = "$port/$protocol";

    return $status;
}

