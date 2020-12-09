
package CXGN::Trait;

use Moose;
use Data::Dumper;

## to do: add concept of trait short name; provide alternate constructors for term, shortname, and synonyms etc.

has 'bcs_schema' => ( isa => 'Bio::Chado::Schema',
		  is => 'rw',
		  required => 1,
    );

has 'cvterm_id' => (isa => 'Maybe[Int]',
		    is => 'rw',
		    #required => 1,
    );

has 'cvterm' => ( isa => 'Bio::Chado::Schema::Result::Cv::Cvterm', 
		  is => 'rw');


has 'name' => ( isa => 'Str',
		is => 'rw',
		lazy => 1,
		default => sub { 
		    my $self = shift; 
		    return $self->cvterm->name(); 
		},

    );

has 'display_name' => (isa => 'Str',
		       is => 'ro',
		       lazy => 1,
		       default => sub { 
			   my $self = shift;
			   my $db = $self->db();
			   my $name = $self->name();
			   my $accession = $self->accession();
			   #print STDERR $db." ".$name." ".$accession."\n";
			   if ($db && $name && $accession ) { 
			       return $name ."|".$db.":".$accession;
			   }
			   return "";
		       }
    );

has 'accession' => (isa => 'Str',
		    is => 'ro',
		    lazy => 1,
		    default => sub { 
			my $self = shift;
			my $rs = $self->bcs_schema()->resultset("Cv::Cvterm")
			    -> search( { cvterm_id => $self->cvterm_id() }) 
			    -> search_related("dbxref");
			if ($rs->count() ==1) { 
			    my $accession = $rs->first()->get_column("accession");
			    return $accession;
			}
			return "";
		    }

    );

has 'term' => (isa => 'Str',
	       is => 'ro',
	       lazy => 1,
	       default => sub { 
		   my $self = shift;
		   my $accession = $self->accession();
		   my $db = $self->db();
		   if ($accession && $db) { 
		       return "$db:$accession";
		   }
		   return "";
	       }
    );

has 'db'   => ( isa => 'Str',
		is => 'ro',
		lazy => 1,
		default => sub { 
		    my $self = shift;
		    my $rs = $self->bcs_schema()->resultset("Cv::Cvterm")->search( { cvterm_id => $self->cvterm_id()})->search_related("dbxref")->search_related("db");
		    if ($rs->count() == 1) { 
			my $db_name =  $rs->first()->get_column("name");
			#print STDERR "DBNAME = $db_name\n";
			return $db_name;
		    }
		    return "";
			
		}
    );

has 'db_id'   => (
	isa => 'Int',
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $rs = $self->cvterm->search_related("dbxref");
		if ($rs->count() == 1) {
			my $db_id =  $rs->first()->get_column("db_id");
			#print STDERR "DBID = $db_id\n";
			return $db_id;
		}
		return "";
	}
);

has 'definition' => (isa => 'Maybe[Str]',
		     is => 'rw',
		     lazy => 1,
		     default => sub { 
			 my $self = shift;
			 return $self->cvterm->definition(); 
		     },

    );

has 'format' => (isa => 'Str',
		 is => 'ro',
		 lazy => 1,
		 default => sub { 
		     my $self = shift;

		     my $row = $self->bcs_schema()->resultset("Cv::Cvtermprop")->find( 
			 { 
			     cvterm_id => $self->cvterm_id(), 'type.name' => 'trait_format' 
			 }, 
			 { join => 'type'} 
			 );
		     
		     if ($row) { 
			 return $row->value();
		     }
		     return "";
		 }
    );

has 'default_value' => (
	isa => 'Str',
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $row = $self->bcs_schema()->resultset("Cv::Cvtermprop")->find(
			{ cvterm_id => $self->cvterm_id(), 'type.name' => 'trait_default_value' },
			{ join => 'type'}
		);

		if ($row) {
			return $row->value();
		}
		return "";
	}
);

has 'minimum' => (
	isa => 'Str',
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $row = $self->bcs_schema()->resultset("Cv::Cvtermprop")->find(
			{ cvterm_id => $self->cvterm_id(), 'type.name' => 'trait_minimum' },
			{ join => 'type'}
		);

		if ($row) {
			return $row->value();
		}
		return "";
	}
);

has 'maximum' => (
	isa => 'Str',
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $row = $self->bcs_schema()->resultset("Cv::Cvtermprop")->find(
			{ cvterm_id => $self->cvterm_id(), 'type.name' => 'trait_maximum' },
			{ join => 'type'}
		);

		if ($row) {
			return $row->value();
		}
		return "";
	}
);

has 'categories' => (
	isa => 'Str',
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $row = $self->bcs_schema()->resultset("Cv::Cvtermprop")->find(
			{ cvterm_id => $self->cvterm_id(), 'type.name' => 'trait_categories' },
			{ join => 'type'}
		);

		if ($row) {
			return $row->value();
		}
		return "";
	}
);

has 'associated_plots' => ( isa => 'Str',
			    is => 'ro',
			    lazy => 1,
			    default => sub { "not yet implemented" }
    );

has 'associated_accessions' =>  ( isa => 'Str',
				  is => 'ro',
				  lazy => 1,
				  default => sub { "not yet implemented" }
    );

has 'uri' => (isa => 'Str',
	is            => 'ro',
	lazy          => 1,
	default => sub {
		my $self = shift;
		my $row = $self->bcs_schema()->resultset("Cv::Cvtermprop")->find(
			{cvterm_id => $self->cvterm_id(), 'type.name' => 'uri'},
			{ join => 'type'}
		);

		if ($row) {
			return $row->value();
		}
		return "";
	}
);

has 'ontology_id' => (
	isa => 'Maybe[Int]',
	is => 'rw',
);

has 'synonyms' => (
	isa => 'Maybe[Any]',
	is  => 'rw'
);

sub BUILD { 
    #print STDERR "BUILDING...\n";
    my $self = shift;
    my $cvterm;

    if ($self->cvterm_id){
        $cvterm = $self->bcs_schema()->resultset("Cv::Cvterm")->find( { cvterm_id => $self->cvterm_id });
        $self->cvterm($cvterm);
    }
    if (defined $cvterm) {
        $self->name($self->name || $cvterm->name );
		$self->definition($self->definition());
		$self->ontology_id($self->ontology_id);
		$self->synonyms($self->synonyms());
    }

    #my $cvterm = $self->bcs_schema()->resultset("Cv::Cvterm")->find( { cvterm_id => $self->cvterm_id() });
    #if ($cvterm) {
	#print STDERR "Cvterm with ID ".$self->cvterm_id()." was found!\n";
    #}
    #$self->cvterm($cvterm);

    return $self;
}


sub store {
    my $self = shift;
    my $schema = $self->bcs_schema();
	my $error;

	# new variable
    my $name = _trim($self->name());
	my $description = $self->definition();
	my $ontology_id = $self->ontology_id();
	my $synonyms = $self->synonyms();

	# get cv_id from sgn_local.conf
	my $context = SGN::Context->new;
	my $cv_name = $context->get_conf('trait_ontology_cv_name');
	my $cvterm_name = $context->get_conf('trait_ontology_cvterm_name');

	# get cv_id for cv_name
	my $cv = $schema->resultset("Cv::Cv")->find(
		{
			name => $cv_name
		},
		{ key => 'cv_c1' }
	);
	my $cv_id = $cv->get_column('cv_id');

	# get cvterm_id for cvterm_name
	my $cvterm = $schema->resultset("Cv::Cvterm")->find(
		{
			name        => $cvterm_name,
			cv_id       => $cv_id,
			is_obsolete => 0
		},
		{ key => 'cvterm_c1' }
	);

	my $root_id = $cvterm->get_column('cvterm_id');

	# check to see if specified ontology exists
	my $db = $schema->resultset("General::Db")->find($ontology_id);

	if (!defined($db)) {
		return {error => "Ontology id does not exist"}
	}

	# check to see if cvterm name already exists and don't attempt if so
	my $cvterm_exists = $schema->resultset("Cv::Cvterm")->find(
		{
			name        => $name,
			cv_id       => $cv_id,
			is_obsolete => 0
		},
		{ key => 'cvterm_c1' }
	);

	if (defined($cvterm_exists)) {
		return {error => "Variable with that name already exists"}
	}

	# lookup last numeric accession number in ontology if one exists so we can increment off that
	my $q = "select accession from dbxref where db_id=".$ontology_id." and accession ~ ".q('^\d+$')." order by accession desc limit 1;";
	my $sth = $self->bcs_schema->storage->dbh->prepare($q);
	$sth->execute();
	my ($accession) = $sth->fetchrow_array();

	if (!defined($accession)) {
		$accession = '0000001';
	} else {
		$accession++;
	}

	# TODO: see if can setup transaction for rollbacks in case of error

	# add trait info to dbxref
	my $new_term_dbxref = $schema->resultset("General::Dbxref")->create(
		{   db_id     => $ontology_id,
			accession => $accession,
			version   => '1',
		},
		{ key => 'dbxref_c1' } ,
	);

	# add trait info to cvterm
	my $new_term = $schema->resultset("Cv::Cvterm")->create(
		{ 	cv_id  => $cv_id,
			name   => $name,
			definition => $description,
			dbxref_id  => $new_term_dbxref->dbxref_id(),
			is_obsolete => 0
		});

	# TODO: make sure relationship_type is set correctly

	# set cvtermrelationship VARIABLE_OF to put terms under ontology

	# get cvterm_id for VARIABLE_OF
	my $variable_of_cvterm = $schema->resultset("Cv::Cvterm")->find(
		{
			name        => 'VARIABLE_OF',
			cv_id       => $cv_id,
			is_obsolete => 0
		},
		{ key => 'cvterm_c1' }
	);

	my $variable_of_id = $variable_of_cvterm->get_column('cvterm_id');

	# add cvterm_relationship entry linking term to ontology root
	my $relationship = $schema->resultset("Cv::CvtermRelationship")->create(
		{ 	type_id  => $variable_of_id,
			subject_id   => $new_term->get_column('cvterm_id'),
			object_id => $root_id
		});

	# add synonyms
	foreach my $synonym (@{$synonyms}) {
		$new_term->add_synonym($synonym);
	}

	$self->cvterm_id($variable_of_id);
	$self->cvterm($cvterm);

	return { success => "Variable added successfully\n", variable=>$self };
}

# TODO: common utilities somewhere, used by Location also
sub _trim { #trim whitespace from both ends of a string
	my $s = shift;
	$s =~ s/^\s+|\s+$//g;
	return $s;
}

# gmod
sub numeric_id {
	my $id = shift;
	$id =~ s/.*\:(.*)$/$1/g;
	return $id;
}


1;
