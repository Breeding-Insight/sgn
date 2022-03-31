
package CXGN::List::Validate::Plugin::Dataset;

use Moose;
use Module::Pluggable require => 1;
use Data::Dumper;
use SGN::Model::Cvterm;

my $logger = Log::Log4perl->get_logger();


sub name {
    return "dataset";
}

sub validate {
    my $self = shift;
    my $schema = shift;
    my $list = shift;
    my $validate = shift;
    my @missing;

    foreach my $list_item(@$list) {

      my ($type, $elements) = split(":(.+)", $list_item);
      my @elements = split(",", $elements);

      foreach my $p ($validate->plugins()) {
        if ($type eq $p->name()) {
          my $response = $p->validate($schema, \@elements);
          my $missing = $response->{'missing'};
          if ($missing && scalar @$missing > 0) {
            push @missing, $type . ": " . join(", ", @$missing);
          }
	      }
      }

    }

    $logger->debug("Total missing = ".Dumper(@missing)."");
    return { missing => \@missing };

}

1;
