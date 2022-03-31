
package CXGN::List::Validate::Plugin::VectorConstructs;

use Moose;
use SGN::Model::Cvterm;

my $logger = Log::Log4perl->get_logger();

sub name { 
    return "vector_constructs";
}

sub validate { 
    my $self = shift;
    my $schema = shift;
    my $list = shift;

    my $type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'vector_construct', 'stock_type')->cvterm_id();
    
    #$logger->error("Vector Construct TYPE ID $type_id");

    my @missing = ();
    foreach my $l (@$list) { 
	my $rs = $schema->resultset("Stock::Stock")->search(
	    { 
		type_id=>$type_id,
		uniquename => $l, 
	    });	
	if ($rs->count() == 0) { 
	    push @missing, $l;
	}
    }
    return { missing => \@missing };
}

1;
