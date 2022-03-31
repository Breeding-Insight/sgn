
package CXGN::GenotypeIOmain;

use Moose;

with 'MooseX::Object::Pluggable';
my $logger = Log::Log4perl->get_logger();

sub init {
    $logger->debug("GenotypeIOmain init CALLED");
}

sub next {
    $logger->debug("GenotypeIOmain NEXT CALLED");
}


1;
