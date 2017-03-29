package CXGN::Genotype::Search;

=head1 NAME

CXGN::Genotype::Search - an object to handle searching genotypes for stocks

=head1 USAGE

my $genotypes_search = CXGN::Genotype::Search->new({
    bcs_schema=>$schema,
    accession_list=>$accession_list,
    trial_list=>$trial_list,
    protocol_id=>$protocol_id
});
my $resultset = $genotypes_search->get_genotype_info();
my $genotypes = $resultset->{genotypes};

=head1 DESCRIPTION


=head1 AUTHORS

 Nicolas Morales <nm529@cornell.edu>
 With code moved from CXGN::BreederSearch
 Lukas Mueller <lam87@cornell.edu>
 Aimin Yan <ay247@cornell.edu>

=cut

use strict;
use warnings;
use Moose;
use Try::Tiny;
use Data::Dumper;
use SGN::Model::Cvterm;
use CXGN::Trial;

has 'bcs_schema' => ( isa => 'Bio::Chado::Schema',
    is => 'rw',
    required => 1,
);

has 'accession_list' => (
    isa => 'ArrayRef[Int]|Undef',
    is => 'ro',
);

has 'trial_list' => (
    isa => 'ArrayRef[Int]|Undef',
    is => 'ro',
);

has 'protocol_id' => (
    isa => 'Int',
    is => 'rw',
    required => 1,
);

has 'limit' => (
    isa => 'Int',
    is => 'rw',
);

has 'offset' => (
    isa => 'Int',
    is => 'rw',
);

=head2 get_genotype_info

returns: an array with genotype information

=cut

sub get_genotype_info {
    my $self = shift;
    my $schema = $self->bcs_schema;
    my $trial_list = $self->trial_list;
    my $protocol_id = $self->protocol_id;
    my $accession_list = $self->accession_list;
    my $limit = $self->limit;
    my $offset = $self->offset;
    my @data;
    my %search_params;

    my $snp_genotyping_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($self->bcs_schema, 'snp genotyping', 'genotype_property')->cvterm_id();

    my @trials_accessions;
    foreach (@$trial_list){
        my $trial = CXGN::Trial->new({bcs_schema=>$schema, trial_id=>$_});
        my $accessions = $trial->get_accessions();
        foreach (@$accessions){
            push @trials_accessions, $_->{stock_id};
        }
    }

    #If accessions are explicitly given, then accessions found from trials will not be added to the search.
    if (!$accession_list || scalar(@$accession_list)==0) {
        push @$accession_list, @trials_accessions;
    }

    #For projects inserted into database during the addition of genotypes and genotypeprops
    if (scalar(@trials_accessions)==0){
        if ($trial_list && scalar(@$trial_list)>0) {
            $search_params{'nd_experiment_projects.project_id'} = { -in => $trial_list };
        }
    }

    $search_params{'genotypeprops.type_id'} = $snp_genotyping_cvterm_id;
    $search_params{'nd_protocol.nd_protocol_id'} = $protocol_id;
    if ($accession_list && scalar(@$accession_list)>0) {
        $search_params{'stock.stock_id'} = { -in => $accession_list };
    }

    my @select_list = ('genotypeprops.genotypeprop_id', 'genotypeprops.value', 'nd_protocol.name', 'stock.stock_id', 'stock.uniquename', 'genotype.uniquename');
    my @select_as_list = ('genotypeprop_id', 'value', 'protocol_name', 'stock_id', 'uniquename', 'genotype_uniquename');
    #$self->bcs_schema->storage->debug(1);
    my $rs = $self->bcs_schema->resultset('NaturalDiversity::NdExperiment')->search(
        \%search_params,
        {join=> [{'nd_experiment_genotypes' => {'genotype' => 'genotypeprops'} }, {'nd_experiment_protocols' => 'nd_protocol' }, 'nd_experiment_projects', {'nd_experiment_stocks' => 'stock'} ],
        select=> \@select_list,
        as=> \@select_as_list,
        order_by=>{ -asc=>'genotypeprops.genotypeprop_id' }
        }
    );

    if ($rs) {
        if ($limit && defined($offset)){
            my $rs_slice = $rs->slice($offset, $limit);
            $rs = $rs_slice;
        }
        while (my $row = $rs->next()) {
            my $genotype_json = $row->get_column('value');
            my $genotype = JSON::Any->decode($genotype_json);

            push @data, {
                markerProfileDbId => $row->get_column('genotypeprop_id'),
                germplasmDbId => $row->get_column('stock_id'),
                germplasmName => $row->get_column('uniquename'),
                genotypeUniquename => $row->get_column('genotype_uniquename'),
                analysisMethod => $row->get_column('protocol_name'),
                genotype_hash => $genotype,
                resultCount => scalar(keys(%$genotype))
            };
        }
    }
    #print STDERR Dumper \@data;

    my $total_count = $rs->count();

    return ($total_count, \@data);
}



1;
