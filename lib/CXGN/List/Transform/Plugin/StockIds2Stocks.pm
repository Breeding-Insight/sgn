package CXGN::List::Transform::Plugin::StockIds2Stocks;

use Moose;
use Data::Dumper;

my $logger = Log::Log4perl->get_logger();

sub name {
    return "stock_ids_2_stocks";
}

sub display_name {
    return "stock IDs to stocks";
}

sub can_transform {
    my $self = shift;
    my $type1 = shift;
    my $type2 = shift;

    if (($type1 eq "stock_ids") and ($type2 eq "stocks")) {
        return 1;
    }
    else {  return 0; }
}


sub transform {
    my $self = shift;
    my $schema = shift;
    my $list = shift;

    my @transform = ();

    my @missing = ();

    if (ref($list) eq "ARRAY" ) {
        foreach my $l (@$list) {
            my $rs = $schema->resultset("Stock::Stock")->search( { stock_id => $l });

            if ($rs->count() == 0) {
                push @missing, $l;
            } else {
                #$logger->error($rs->first()->uniquename() . "");
                push @transform, $rs->first()->uniquename();
            }
        }
    }
    return {
        transform => \@transform,
        missing => \@missing,
    };
}

1;
