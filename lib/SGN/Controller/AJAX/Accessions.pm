
=head1 NAME

SGN::Controller::AJAX::Accessions - a REST controller class to provide the
backend for managing accessions

=head1 DESCRIPTION

Managing accessions

=head1 AUTHOR

Jeremy Edwards <jde22@cornell.edu>

=cut

package SGN::Controller::AJAX::Accessions;

use Moose;
use JSON -support_by_pp;
use List::MoreUtils qw /any /;
use CXGN::BreedersToolbox::AccessionsFuzzySearch;
use CXGN::Stock::AddStocks;
use Data::Dumper;
#use JSON;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    map       => { 'application/json' => 'JSON', 'text/html' => 'JSON' },
   );

sub verify_accession_list : Path('/ajax/accession_list/verify') : ActionClass('REST') { }

sub verify_accession_list_POST : Args(0) {
  my ($self, $c) = @_;
  my $schema = $c->dbic_schema('Bio::Chado::Schema', 'sgn_chado');
  my $accession_list_json = $c->req->param('accession_list');
  my $do_fuzzy_search = $c->req->param('do_fuzzy_search');
  my $fuzzy_accession_search = CXGN::BreedersToolbox::AccessionsFuzzySearch->new({schema => $schema});
  my $fuzzy_search_result;
  my $max_distance = 0.2;
  my @accession_list;
  my @found_accessions;
  my @fuzzy_accessions;
  my @absent_accessions;


  if (!$c->user()) {
    $c->stash->{rest} = {error => "You need to be logged in to create a field book" };
    return;
  }
  if (!any { $_ eq "curator" || $_ eq "submitter" } ($c->user()->roles)  ) {
    $c->stash->{rest} = {error =>  "You have insufficient privileges to create a field book." };
    return;
  }

  @accession_list = @{_parse_list_from_json($accession_list_json)};

  $fuzzy_search_result = $fuzzy_accession_search->get_matches(\@accession_list, $max_distance);
  print STDERR "\n\nResult:\n".Data::Dumper::Dumper($fuzzy_search_result)."\n\n";

  @found_accessions = $fuzzy_search_result->{'found'};
  @fuzzy_accessions = $fuzzy_search_result->{'fuzzy'};
  @absent_accessions = $fuzzy_search_result->{'absent'};
  $c->stash->{rest} = {success => "1", absent => @absent_accessions, fuzzy => @fuzzy_accessions, found => @found_accessions};
  return;
}

sub add_accession_list : Path('/ajax/accession_list/add') : ActionClass('REST') { }

sub add_accession_list_POST : Args(0) {
  my ($self, $c) = @_;
  my $schema = $c->dbic_schema('Bio::Chado::Schema', 'sgn_chado');
  my $accession_list_json = $c->req->param('accession_list');
  my $species_name = $c->req->param('species_name');
  my @accession_list;
  my $stock_add;
  my $validated;
  my $added;
  my $dbh = $c->dbc->dbh;
  my $user_id;
  my $owner_name;
  my $phenome_schema = $c->dbic_schema("CXGN::Phenome::Schema");

  if (!$c->user()) {
    $c->stash->{rest} = {error => "You need to be logged in to create a field book" };
    return;
  }

  $user_id = $c->user()->get_object()->get_sp_person_id();
  $owner_name = $c->user()->get_object()->get_username();

  if (!any { $_ eq "curator" || $_ eq "submitter" } ($c->user()->roles)  ) {
    $c->stash->{rest} = {error =>  "You have insufficient privileges to create a field book." };
    return;
  }

  @accession_list = @{_parse_list_from_json($accession_list_json)};
  $stock_add = CXGN::Stock::AddStocks->new({ schema => $schema, stocks => \@accession_list, species => $species_name, owner_name => $owner_name,phenome_schema => $phenome_schema, dbh => $dbh} );
  $validated = $stock_add->validate_stocks();
  if (!$validated) {
    $c->stash->{rest} = {error =>  "Stocks already exist in the database" };
  }
  $added = $stock_add->add_accessions();
  if (!$added) {
    $c->stash->{rest} = {error =>  "Could not add stocks to the database" };
  }
  $c->stash->{rest} = {success => "1"};
  return;
}


sub _parse_list_from_json {
  my $list_json = shift;
  my $json = new JSON;
  if ($list_json) {
    my $decoded_list = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($list_json);
    #my $decoded_list = decode_json($list_json);
    my @array_of_list_items = @{$decoded_list};
    return \@array_of_list_items;
  }
  else {
    return;
  }
}


1;
