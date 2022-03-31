
package CXGN::List::Validate::Plugin::Traits;

use Moose;
use Data::Dumper;

my $logger = Log::Log4perl->get_logger();

sub name {
    return "traits";
}

sub validate {
    my $self = shift;
    my $schema = shift;
    my $list = shift;
    my @missing;

#    $logger->error("LIST: ".Data::Dumper::Dumper($list));

# Expects $terms to be full trait names e.g. root weight|CO_334:0000012
# For postcomposed terms expects full trait names e.g. tissue metabolite unit time|COMP:0000015

    foreach my $term (@$list) {
        #$logger->error($term."");

        my @parts = split (/\|/ , $term);
        my ($db_name, $accession) = split ":", pop @parts;

        $accession =~ s/\s+$//;
        $accession =~ s/^\s+//;
        $db_name =~ s/\s+$//;
        $db_name =~ s/^\s+//;

        my $db_rs = $schema->resultset("General::Db")->search( { 'me.name' => $db_name });
        if ($db_rs->count() == 0) {
            #$logger->error("Problem found with term $term at db $db_name");
            push @missing, $term;
        } else {
            my $db = $db_rs->first();
            my $rs = $schema->resultset("Cv::Cvterm")->search( {
            'dbxref.db_id' => $db->db_id(),
            'dbxref.accession'=>$accession }, {
                'join' => 'dbxref' }
            );

            if ($rs->count == 0) {
                #$logger->error("Problem found with term $term at cvterm rs from accession $accession point 2");
                push @missing, $term;
            } else {
                my $rs_var = $rs->search_related('cvterm_relationship_subjects', {'type.name' => 'VARIABLE_OF'}, { 'join' => 'type'});
                if ($rs_var->count == 0) {
                    $logger->debug("Problem found with term $term at variable check point 3");
                    push @missing, $term;
                }
            }
        }

    }
    # $logger->error(Dumper(\@missing));
    return { missing => \@missing };
}

1;
