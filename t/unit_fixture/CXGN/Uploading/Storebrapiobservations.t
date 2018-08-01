use strict;
use warnings;

use lib 't/lib';
use SGN::Test::Fixture;
use Test::More;
use Test::WWW::Mechanize;
use SGN::Model::Cvterm;
use Data::Dumper;
use JSON;
use HTTP::Request;
use LWP::UserAgent;

my $f = SGN::Test::Fixture->new();
my $schema = $f->bcs_schema;

my $mech = Test::WWW::Mechanize->new(timeout=>30000);
my $response;

my $plot_id1 = $schema->resultset('Stock::Stock')->find({uniquename=>'test_trial210'})->stock_id;
my $plot_id2 = $schema->resultset('Stock::Stock')->find({uniquename=>'test_trial214'})->stock_id;

$mech->post_ok('http://localhost:3010/brapi/v1/token', [ "username"=> "janedoe", "password"=> "secretpw", "grant_type"=> "password" ]);
$response = decode_json $mech->content;
print STDERR Dumper $response;
is($response->{'metadata'}->{'status'}->[2]->{'message'}, 'Login Successfull');
my $sgn_session_id = $response->{access_token};


my $data = {
    observations => [
        {
            observationDbId => '',
            observationUnitDbId => $plot_id1,
            observationVariableDbId => 'dry matter content|CO_334:0000092',
            collector => 'collector1',
            observationTimeStamp => '2015-06-16T00:53:26Z',
            value => '11'
        },
        {
            observationDbId => '',
            observationUnitDbId => $plot_id2,
            observationVariableDbId => 'fresh shoot weight|CO_334:0000016',
            collector => 'collector1',
            observationTimeStamp => '2015-06-16T00:53:26Z',
            value => '110'
        },
    ]
};
my $j = encode_json $data;

my $req = HTTP::Request->new( "PUT" => "http://localhost:3010/brapi/v1/observations" );
$req->content_type( 'application/json' );
$req->content_length(
    do { use bytes; length( $j ) }
);
$req->content( $j );

my $ua = LWP::UserAgent->new();
my $res = $ua->request($req);
$response = decode_json $res->content;
print STDERR Dumper $response;
is_deeply($response, {
          'metadata' => {
                          'datafiles' => [],
                          'pagination' => {
                                            'totalCount' => 0,
                                            'totalPages' => 0,
                                            'currentPage' => 0,
                                            'pageSize' => 1
                                          },
                          'status' => [
                                        {
                                          'code' => 'info',
                                          'message' => 'BrAPI base call found with page=0, pageSize=10'
                                        },
                                        {
                                          'code' => 'info',
                                          'message' => 'Loading CXGN::BrAPI::v1::Observations'
                                        },
                                        {
                                          'message' => 'Permission Denied. Must have correct privilege.',
                                          'code' => '4003'
                                        },
                                        {
                                          'message' => 'Must have submitter privileges to upload phenotypes! Please contact us!',
                                          'code' => '400'
                                        }
                                      ]
                        },
          'result' => undef
        });

my $data = {
    access_token => $sgn_session_id,
    observations => [
        {
            observationDbId => '',
            observationUnitDbId => $plot_id1,
            observationVariableDbId => 'CO_334:0000092',
            collector => 'collector1',
            observationTimeStamp => '2015-06-16T00:53:26Z',
            value => '11'
        },
        {
            observationDbId => '',
            observationUnitDbId => $plot_id2,
            observationVariableDbId => 'CO_334:0000016',
            collector => 'collector1',
            observationTimeStamp => '2015-06-16T00:53:26Z',
            value => '110'
        },
    ]
};
$j = encode_json $data;
$req = HTTP::Request->new( "PUT" => "http://localhost:3010/brapi/v1/observations" );
$req->content_type( 'application/json' );
$req->content_length(
    do { use bytes; length( $j ) }
);
$req->content( $j );

$ua = LWP::UserAgent->new();
$res = $ua->request($req);
$response = decode_json $res->content;
print STDERR Dumper $response;

#Remove observationdbid from result because it is variable
foreach (@{$response->{result}->{data}}){
    delete $_->{observationDbId};
}

is_deeply($response, {
          'result' => {
                        'data' => [
                                    {
                                      'observationLevel' => 'plot',
                                      'uploadedBy' => 41,
                                      'observationTimeStamp' => '2015-06-16T00:53:26Z',
                                      'studyDbId' => 137,
                                      'observationUnitName' => 'test_trial210',
                                      'observationVariableName' => 'dry matter content percentage',
                                      'observationUnitDbId' => 38866,
                                      'collector' => 'collector1',
                                      'value' => '11',
                                      'observationVariableDbId' => 'dry matter content percentage|CO_334:0000092',
                                      'germplasmName' => 'test_accession3',
                                      'germplasmDbId' => 38842
                                    },
                                    {
                                      'germplasmName' => 'test_accession4',
                                      'germplasmDbId' => 38843,
                                      'observationUnitName' => 'test_trial214',
                                      'observationVariableName' => 'fresh shoot weight measurement in kg',
                                      'observationUnitDbId' => 38870,
                                      'collector' => 'collector1',
                                      'value' => '110',
                                      'observationVariableDbId' => 'fresh shoot weight measurement in kg|CO_334:0000016',
                                      'uploadedBy' => 41,
                                      'observationTimeStamp' => '2015-06-16T00:53:26Z',
                                      'studyDbId' => 137,
                                      'observationLevel' => 'plot'
                                    }
                                  ]
                      },
          'metadata' => {
                          'status' => [
                                        {
                                          'code' => 'info',
                                          'message' => 'BrAPI base call found with page=0, pageSize=10'
                                        },
                                        {
                                          'code' => 'info',
                                          'message' => 'Loading CXGN::BrAPI::v1::Observations'
                                        },
                                        {
                                          'message' => 'Request structure is valid',
                                          'code' => 'info'
                                        },
                                        {
                                          'message' => 'Request data is valid',
                                          'code' => 'info'
                                        },
                                        {
                                          'message' => 'File for incoming brapi obserations saved in archive.',
                                          'code' => 'info'
                                        },
                                        {
                                          'code' => '200',
                                          'message' => 'All values in your file are now saved in the database!'
                                        }
                                      ],
                          'datafiles' => [
                                         ],
                          'pagination' => {
                                            'totalCount' => 2,
                                            'totalPages' => 1,
                                            'pageSize' => 10,
                                            'currentPage' => 0
                                          }
                        }
        });

done_testing;