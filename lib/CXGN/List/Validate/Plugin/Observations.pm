
package CXGN::List::Validate::Plugin::Observations;

use Moose;

my $logger = Log::Log4perl->get_logger();

sub name {
    return "observations";
}

sub validate {
    my $self = shift;
    my $schema = shift;
    my $list = shift;

    my @missing = ();
    foreach my $l (@$list) {
    	my $rs = $schema->resultset("Phenotype::Phenotype")->search({ phenotype_id=>$l });
    	if ($rs->count() == 0) {
            # $logger->error("Couldn't find $l");
    	    push @missing, $l;
    	}
    }
    return { missing => \@missing };
}

1;
