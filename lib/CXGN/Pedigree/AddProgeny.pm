package CXGN::Pedigree::AddProgeny;

=head1 NAME

CXGN::Pedigree::AddProgeny - a module to add cross experiments.

=head1 USAGE

 my $progeny_add = CXGN::Pedigree::AddProgeny->new({ schema => $schema, cross_name => $cross_name, progeny_names => \@progeny_names} );
 my $progeny_validated = $progeny_add->validate_progeny(); #is true when the cross name exists and the progeny names to be assigned are valid.
 $progeny_add->add_progeny();

=head1 DESCRIPTION

Adds progeny to a cross and creates corresponding new stocks of type accession. The cross must already exist in the database, and the verify function does this check.   This module is intended to be used in independent loading scripts and interactive dialogs.

=head1 AUTHORS

 Jeremy D. Edwards (jde22@cornell.edu)

=cut

use Moose;
use MooseX::FollowPBP;
use Moose::Util::TypeConstraints;
use Try::Tiny;
use CXGN::Stock::StockLookup;
use CXGN::Location::LocationLookup;
use CXGN::BreedersToolbox::Projects;

has 'chado_schema' => (
		 is       => 'rw',
		 isa      => 'DBIx::Class::Schema',
		 predicate => 'has_chado_schema',
		 required => 1,
		);
has 'phenome_schema' => (
		 is       => 'rw',
		 isa      => 'DBIx::Class::Schema',
		 predicate => 'has_phenome_schema',
		 required => 1,
		);
has 'dbh' => (is  => 'rw',predicate => 'has_dbh', required => 1,);
has 'cross_name' => (isa =>'Str', is => 'rw', predicate => 'has_cross_name', required => 1,);
has 'progeny_names' => (isa =>'ArrayRef[Str]', is => 'rw', predicate => 'has_progeny_names', required => 1,);
has 'owner_name' => (isa => 'Str', is => 'rw', predicate => 'has_owner_name', required => 1,);

sub add_progeny {
  my $self = shift;
  my $chado_schema = $self->get_chado_schema();
  my $phenome_schema = $self->get_phenome_schema();
  my @progeny_names = @{$self->get_progeny_names()};
  my $cross_stock;
  my $female_parent;
  my $male_parent;
  my $organism_id;
  my $transaction_error;
  my @added_stock_ids;

  #lookup user by name
  my $owner_name = $self->get_owner_name();;
  my $dbh = $self->get_dbh();
  my $owner_sp_person_id = CXGN::People::Person->get_person_by_username($dbh, $owner_name); #add person id as an option.


  #add all progeny in a single transaction
  my $coderef = sub {

    my $female_parent_cvterm = $chado_schema->resultset("Cv::Cvterm")
      ->create_with( { name   => 'female_parent',
		       cv     => 'stock relationship',
		       db     => 'null',
		       dbxref => 'female_parent',
		     });
    my $male_parent_cvterm = $chado_schema->resultset("Cv::Cvterm")
      ->create_with({ name   => 'male_parent',
		      cv     => 'stock relationship',
		      db     => 'null',
		      dbxref => 'male_parent',
		    });
    my $member_cvterm = $chado_schema->resultset("Cv::Cvterm")
      ->create_with({ name   => 'member_of',
		      cv     => 'stock relationship',
		      db     => 'null',
		      dbxref => 'member_of',
		    });
    my $accession_cvterm = $chado_schema->resultset("Cv::Cvterm")
      ->create_with({
		     name   => 'accession',
		     cv     => 'stock type',
		     db     => 'null',
		     dbxref => 'accession',
		    });

    my $cross_name_cvterm = $chado_schema->resultset("Cv::Cvterm")->find(
								   { name   => 'cross_name',
								   });
    if (!$cross_name_cvterm) {
      $cross_name_cvterm = $chado_schema->resultset("Cv::Cvterm")
	->create_with( { name   => 'cross_name',
			 cv     => 'local',
			 db     => 'null',
			 dbxref => 'cross_name',
		       });
    }

    #Get stock of type cross matching cross name
    $cross_stock = $self->_get_cross($self->get_cross_name());
    if (!$cross_stock) {
      print STDERR "Cross could not be found\n";
      return;
    }

    #Get organism id from cross
    $organism_id = $cross_stock->organism_id();

    #get experiment
    my $experiment = $chado_schema->resultset('NaturalDiversity::NdExperiment')
      ->find({
	      'nd_experiment_stocks.stock_id' => $cross_stock->stock_id,
	     },
	     {
	      join => 'nd_experiment_stocks',
	     });
    if (!$experiment) {
      print STDERR "\n\n\nCross experiment could not be found\n";
      return;
    }

    $female_parent = $chado_schema->resultset("Stock::Stock")
      ->find({
	      'nd_experiment_stocks.nd_experiment_id' => $experiment->nd_experiment_id(),
	      'nd_experiment_stocks.type_id'  =>  $female_parent_cvterm->cvterm_id(),
	     },
	     {
	      join => 'nd_experiment_stocks',
	     });

    $male_parent = $chado_schema->resultset("Stock::Stock")
      ->find({
	      'nd_experiment_stocks.nd_experiment_id' => $experiment->nd_experiment_id(),
	      'nd_experiment_stocks.type_id'  =>  $male_parent_cvterm->cvterm_id(),
	     },
	     {
	      join => 'nd_experiment_stocks',
	     });

    foreach my $progeny_name (@progeny_names) {

      #create progeny
      my $accession_stock = $chado_schema->resultset("Stock::Stock")
	->create({
		  organism_id => $organism_id,
		  name       => $progeny_name,
		  uniquename => $progeny_name,
		  type_id     => $accession_cvterm->cvterm_id,
		 } );

      #add stock_id of cross to an array so that the owner can be associated in the phenome schema after the transaction on the chado schema completes
      push (@added_stock_ids,  $accession_stock->stock_id());


      #create relationship to cross population
      $accession_stock
	->find_or_create_related('stock_relationship_objects', {

								type_id => $member_cvterm->cvterm_id(),
								object_id => $cross_stock->stock_id(),
								subject_id => $accession_stock->stock_id(),
							       } );
      #create relationship to female parent
      if ($female_parent) {
	$accession_stock
	  ->find_or_create_related('stock_relationship_objects', {
								  type_id => $female_parent_cvterm->cvterm_id(),
								  object_id => $accession_stock->stock_id(),
								  subject_id => $female_parent->stock_id(),
								 });
      }

      #create relationship to male parent
      if ($male_parent) {
       	$accession_stock
       	  ->find_or_create_related('stock_relationship_objects', {
       								  type_id => $male_parent_cvterm->cvterm_id(),
       								  object_id => $accession_stock->stock_id(),
       								  subject_id => $male_parent->stock_id(),
       								 });
      }

    }

  };

  #try to add all crosses in a transaction
  try {
    $chado_schema->txn_do($coderef);
  } catch {
    $transaction_error =  $_;
  };

  if ($transaction_error) {
    print STDERR "Transaction1 error creating a cross: $transaction_error\n";
    return;
  }

  foreach my $stock_id (@added_stock_ids) {
    #add the owner for this stock
    $phenome_schema->resultset("StockOwner")
      ->find_or_create({
			stock_id     => $stock_id,
			sp_person_id =>  $owner_sp_person_id,
		       });
  }

  return 1;
}


sub _get_cross {
  my $self = shift;
  my $cross_name = shift;
  my $chado_schema = $self->get_chado_schema();
  my $stock_lookup = CXGN::Stock::StockLookup->new(schema => $chado_schema);
  my $stock;
  my $cross_cvterm = $chado_schema->resultset("Cv::Cvterm")
    ->create_with({
		   name   => 'cross',
		   cv     => 'stock type',
		   db     => 'null',
		   dbxref => 'accession',
		  });
  $stock_lookup->set_stock_name($cross_name);
  $stock = $stock_lookup->get_stock_exact();

  if (!$stock) {
    print STDERR "Cross name does not exist\n";
    return;
  }

  if ($stock->type_id() != $cross_cvterm->cvterm_id()) {
    print STDERR "Cross name is not a stock of type cross\n";
    return;
  }

  return $stock;
}

#######
1;
#######
