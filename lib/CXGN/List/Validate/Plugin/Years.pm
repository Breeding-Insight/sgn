
package CXGN::List::Validate::Plugin::Years;

use Moose;
use Data::Dumper;

my $logger = Log::Log4perl->get_logger();

sub name { 
    return "years";
}

sub validate { 
    my $self = shift;
    my $schema = shift;
    my $list = shift;

#    $logger->error("LIST: ".Data::Dumper::Dumper($list));

    my @missing = ();
    foreach my $term (@$list) { 

	my $rs = $schema->resultset("Project::Projectprop")->search( { value => $term } );

	if ($rs->count == 0) { 
	    push @missing, $term;
	}
    }
    return { missing => \@missing };

}

1;
