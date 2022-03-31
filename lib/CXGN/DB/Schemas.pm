
package CXGN::DB::Schemas;

use Moose;

use DBI;
use Bio::Chado::Schema;
use CXGN::Phenome::Schema;
use SGN::Schema;
use CXGN::Metadata::Schema;

my $logger = Log::Log4perl->get_logger();


has 'dbh' => (
		is => 'rw',
    );

has 'bcs_schema' => (isa => 'Bio::Chado::Schema',
		     is => 'rw',
    );

has 'phenome_schema' => (isa => 'CXGN::Phenome::Schema', 
			 is => 'rw',
    );

has 'sgn_schema' => (isa => 'SGN::Schema',
		     is => 'rw',
    );

has 'metadata_schema' => (isa => 'CXGN::Metadata::Schema', 
			  is => 'rw',
    );

has 'username' => (isa => 'Str', 
		   is => 'rw',
    );

has 'password' => (isa => 'Str', 
		   is => 'rw',
    );

has 'dbname' => (isa => 'Str',
		 is => 'rw',
    );

has 'dbhost' => (isa => 'Str', 
		 is => 'rw',
    );

has 'dbuser' => (isa => 'Str', 
		 is => 'rw',
    );

has 'dbpass' => (isa => 'Str',
		 is => 'rw',
    );

sub BUILD { 
    my $self = shift;

    my $dsn = 'dbi:Pg:database='.$self->dbname().";host=".$self->dbhost().";port=5432";
    
    if (! $self->dbh()) { 
	if (!$self->dbuser() && !$self->dbpass()) { 
	    die "Need dbuser and dbpass";
	}
	$self->dbh(DBI->connect($dsn, $self->dbuser(), $self->dbpass()));
    }

    $logger->debug("Setting the search path...");
    $self->dbh()->do("SET search_path TO phenome, metadata, sgn_people, public, sgn");

    $logger->debug("Connecting to the schemas...");
    $self->bcs_schema(Bio::Chado::Schema->connect( sub { $self->dbh(); }));
    
    $self->phenome_schema(CXGN::Phenome::Schema->connect( sub { $self->dbh() }));
                
    
    $self->sgn_schema(SGN::Schema->connect( sub { $self->dbh(); }));
    
    $self->metadata_schema(CXGN::Metadata::Schema->connect( sub { $self->dbh(); }));

}

1;
