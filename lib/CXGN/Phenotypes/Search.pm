package CXGN::Phenotypes::Search;

=head1 NAME

CXGN::Phenotypes::Download - an object to handle searching phenotypes for trials or stocks

=head1 USAGE

my $phenotypes_search = CXGN::Phenotypes::Search->new({
    bcs_schema=>$schema,
    data_level=>$data_level,
    trait_list=>$trait_list,
    trial_list=>$trial_list,
    accession_list=>$accession_list,
    plot_list=>$plot_list,
    plant_list=>$plant_list,
    include_timestamp=>$include_timestamp,
    trait_contains=>$trait_contains,
    phenotype_min_value=>$phenotype_min_value,
    phenotype_max_value=>$phenotype_max_value
});
my @data = $phenotypes_search->get_extended_phenotype_info_matrix();

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

has 'bcs_schema' => ( isa => 'Bio::Chado::Schema',
    is => 'rw',
    required => 1,
);

#(plot, plant, or all)
has 'data_level' => (
    isa => 'Str|Undef',
    is => 'ro',
);

has 'trial_list' => (
    isa => 'ArrayRef|Undef',
    is => 'rw',
);

has 'trait_list' => (
    isa => 'ArrayRef|Undef',
    is => 'rw',
);

has 'accession_list' => (
    isa => 'ArrayRef|Undef',
    is => 'rw',
);

has 'plot_list' => (
    isa => 'ArrayRef|Undef',
    is => 'rw',
);

has 'plant_list' => (
    isa => 'ArrayRef|Undef',
    is => 'rw',
);

has 'location_list' => (
    isa => 'ArrayRef|Undef',
    is => 'rw',
);

has 'year_list' => (
    isa => 'ArrayRef|Undef',
    is => 'rw',
);

has 'include_timestamp' => (
    isa => 'Bool|Undef',
    is => 'ro',
    default => 0
);

has 'trait_contains' => (
    isa => 'ArrayRef|Undef',
    is => 'rw'
);

has 'phenotype_min_value' => (
    isa => 'Str|Undef',
    is => 'rw'
);

has 'phenotype_max_value' => (
    isa => 'Str|Undef',
    is => 'rw'
);

sub search {
    my $self = shift;
    my $schema = $self->bcs_schema();
    print STDERR "Search Start:".localtime."\n";
    my $rep_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'replicate', 'stock_property')->cvterm_id();
    my $block_number_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'block', 'stock_property')->cvterm_id();
    my $plot_number_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plot number', 'stock_property')->cvterm_id();
    my $year_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'project year', 'project_property')->cvterm_id();
    my $design_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'design', 'project_property')->cvterm_id();
    my $plot_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plot', 'stock_type')->cvterm_id();
    my $plant_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plant', 'stock_type')->cvterm_id();
    my $accession_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'accession', 'stock_type')->cvterm_id();
    my $include_timestamp = $self->include_timestamp;

    my %synonym_hash_lookup = %{$self->get_synonym_hash_lookup()};

    my @where_clause;
    my $numeric_regex = '^[0-9]+([,.][0-9]+)?$';
    if ($self->accession_list && scalar(@{$self->accession_list})>0) {
        my $accession_sql = _sql_from_arrayref($self->accession_list);
        push @where_clause, "accession.stock_id in ($accession_sql)";
    }
    if ($self->plot_list && scalar(@{$self->plot_list})>0) {
        my $plot_sql = _sql_from_arrayref($self->plot_list);
        push @where_clause, "plot.stock_id in ($plot_sql)";
    }
    if ($self->plant_list && scalar(@{$self->plant_list})>0) {
        my $plant_sql = _sql_from_arrayref($self->plant_list);
        push @where_clause, "plot.stock_id in ($plant_sql)";
    }
    if ($self->trial_list && scalar(@{$self->trial_list})>0) {
        my $trial_sql = _sql_from_arrayref($self->trial_list);
        push @where_clause, "project.project_id in ($trial_sql)";
    }
    if ($self->trait_list && scalar(@{$self->trait_list})>0) {
        my $trait_sql = _sql_from_arrayref($self->trait_list);
        push @where_clause, "cvterm.cvterm_id in ($trait_sql)";
    }
    if ($self->location_list && scalar(@{$self->location_list})>0) {
        my $location_sql = _sql_from_arrayref($self->location_list);
        push @where_clause, "nd_geolocation.nd_geolocation_id in ($location_sql)";
    }
    if ($self->year_list && scalar(@{$self->year_list})>0) {
        my $year_sql = _sql_from_arrayref($self->year_list);
        push @where_clause, "year.value::int in ($year_sql)";
        push @where_clause, "year.value~\'$numeric_regex\'";
    }
    if ($self->trait_contains && scalar(@{$self->trait_contains})>0) {
        foreach (@{$self->trait_contains}) {
            push @where_clause, "cvterm.name like '%".lc($_)."%'";
        }
    }
    if ($self->phenotype_min_value && !$self->phenotype_max_value) {
        push @where_clause, "phenotype.value::real >= ".$self->phenotype_min_value;
        push @where_clause, "phenotype.value~\'$numeric_regex\'";
    }
    if ($self->phenotype_max_value && !$self->phenotype_min_value) {
        push @where_clause, "phenotype.value::real <= ".$self->phenotype_max_value;
        push @where_clause, "phenotype.value~\'$numeric_regex\'";
    }
    if ($self->phenotype_max_value && $self->phenotype_min_value) {
        push @where_clause, "phenotype.value::real BETWEEN ".$self->phenotype_min_value." AND ".$self->phenotype_max_value;
        push @where_clause, "phenotype.value~\'$numeric_regex\'";
    }
    if ($self->data_level ne 'all') {
        my $stock_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, $self->data_level, 'stock_type')->cvterm_id();
        push @where_clause, "plot.type_id = $stock_type_id";
    } else {
        push @where_clause, "(plot.type_id = $plot_type_id OR plot.type_id = $plant_type_id)";
    }

    my $where_clause = "WHERE accession.type_id = $accession_type_id";
    $where_clause .= " AND (rep.type_id = $rep_type_id OR rep.type_id IS NULL)";
    $where_clause .= " AND (block_number.type_id = $block_number_type_id OR block_number.type_id IS NULL)";
    $where_clause .= " AND (plot_number.type_id = $plot_number_type_id OR plot_number.type_id IS NULL)";
    $where_clause .= " AND (year.type_id = $year_type_id OR year.type_id IS NULL)";
    $where_clause .= " AND (design.type_id = $design_type_id OR design.type_id IS NULL)";

    if (@where_clause>0) {
        $where_clause .= " AND " . (join (" AND " , @where_clause));
    }
    #print STDERR $where_clause."\n";

    my $order_clause = " ORDER BY project.name, plot.uniquename";
    my $q = "SELECT year.value, project.name, accession.uniquename, nd_geolocation.description, cvterm.name, phenotype.value, plot.uniquename, db.name ||  ':' || dbxref.accession, rep.value, block_number.value, plot_number.value, cvterm.cvterm_id, project.project_id, nd_geolocation.nd_geolocation_id, accession.stock_id, plot.stock_id, phenotype.uniquename, design.value, plot_type.name, phenotype.phenotype_id
             FROM stock as plot JOIN stock_relationship ON (plot.stock_id=subject_id)
             JOIN cvterm as plot_type ON (plot_type.cvterm_id = plot.type_id)
             JOIN stock as accession ON (object_id=accession.stock_id)
             JOIN stockprop AS rep ON (plot.stock_id=rep.stock_id)
             JOIN stockprop AS block_number ON (plot.stock_id=block_number.stock_id)
             JOIN stockprop AS plot_number ON (plot.stock_id=plot_number.stock_id)
             JOIN nd_experiment_stock ON(nd_experiment_stock.stock_id=plot.stock_id)
             JOIN nd_experiment ON (nd_experiment_stock.nd_experiment_id=nd_experiment.nd_experiment_id)
             JOIN nd_geolocation USING(nd_geolocation_id)
             JOIN nd_experiment_phenotype ON (nd_experiment_phenotype.nd_experiment_id=nd_experiment.nd_experiment_id)
             JOIN phenotype USING(phenotype_id)
             JOIN cvterm ON (phenotype.cvalue_id=cvterm.cvterm_id)
             JOIN dbxref ON (cvterm.dbxref_id = dbxref.dbxref_id)
             JOIN db USING(db_id)
             JOIN nd_experiment_project ON (nd_experiment_project.nd_experiment_id=nd_experiment.nd_experiment_id)
             JOIN project USING(project_id)
             JOIN projectprop as year USING(project_id)
             JOIN projectprop as design USING(project_id)
             $where_clause
             $order_clause;";

    #print STDERR "QUERY: $q\n\n";
    my $h = $schema->storage->dbh()->prepare($q);
    $h->execute();
    my $result = [];
    while (my ($year, $project_name, $stock_name, $location, $trait, $value, $plot_name, $cvterm_accession, $rep, $block_number, $plot_number, $trait_id, $project_id, $location_id, $stock_id, $plot_id, $phenotype_uniquename, $design, $stock_type_name, $phenotype_id) = $h->fetchrow_array()) {

        my $timestamp_value;
        if ($include_timestamp) {
            my ($p1, $p2) = split /date: /, $phenotype_uniquename;
            my ($timestamp, $p3) = split /  operator/, $p2;
            if( $timestamp =~ m/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})(\S)(\d{4})/) {
                $timestamp_value = $timestamp;
            }
        }
        my $synonyms = $synonym_hash_lookup{$stock_name};
        push @$result, [ $year, $project_name, $stock_name, $location, $trait, $value, $plot_name, $cvterm_accession, $rep, $block_number, $plot_number, $trait_id, $project_id, $location_id, $stock_id, $plot_id, $timestamp_value, $synonyms, $design, $stock_type_name, $phenotype_id ];
    }
    #print STDERR Dumper $result;
    print STDERR "Search End:".localtime."\n";
    return $result;
}

sub _sql_from_arrayref {
    my $arrayref = shift;
    my $sql = join ("," , @$arrayref);
    return $sql;
}


sub get_extended_phenotype_info_matrix {
    my $self = shift;
    my $data = $self->search();
    my %plot_data;
    my %traits;
    my $include_timestamp = $self->include_timestamp;

    print STDERR "No of lines retrieved: ".scalar(@$data)."\n";
    print STDERR "Construct Pheno Matrix Start:".localtime."\n";
    my @unique_plot_list = ();
    my %seen_plots;
    foreach my $d (@$data) {

        my ($year, $project_name, $stock_name, $location, $trait, $value, $plot_name, $cvterm_accession, $rep, $block_number, $plot_number, $trait_id, $project_id, $location_id, $stock_id, $plot_id, $timestamp_value, $synonyms, $design, $stock_type_name, $phenotype_id) = @$d;

        if (!exists($seen_plots{$plot_id})) {
            push @unique_plot_list, $plot_id;
            $seen_plots{$plot_id} = 1;
        }

        my $cvterm = $trait."|".$cvterm_accession;
        if ($include_timestamp && $timestamp_value) {
            $plot_data{$plot_id}->{$cvterm} = "$value,$timestamp_value";
        } else {
            $plot_data{$plot_id}->{$cvterm} = $value;
        }
        my $synonym_string = $synonyms ? join ("," , @$synonyms) : '';
        $plot_data{$plot_id}->{metadata} = {
            replicate => $rep,
            studyName => $project_name,
            germplasmName => $stock_name,
            locationName => $location,
            blockNumber => $block_number,
            plotNumber => $plot_number,
            observationUnitName => $plot_name,
            year => $year,
            studyDbId => $project_id,
            locationDbId => $location_id,
            germplasmDbId => $stock_id,
            observationUnitDbId => $plot_id,
            germplasmSynonyms => $synonym_string,
            studyDesign => $design,
            observationLevel => $stock_type_name
        };
        $traits{$cvterm}++;
    }
    #print STDERR Dumper \%plot_data;

    my @info = ();
    my $line = join "\t", qw | studyYear studyDbId studyName studyDesign locationDbId locationName germplasmDbId germplasmName germplasmSynonyms observationLevel observationUnitDbId observationUnitName replicate blockNumber plotNumber|;

    # generate header line
    #
    my @sorted_traits = sort keys(%traits);
    foreach my $trait (@sorted_traits) {
        $line .= "\t".$trait;
    }
    push @info, $line;

    #print STDERR Dumper \@unique_plot_list;

    foreach my $p (@unique_plot_list) {
        $line = join "\t", map { $plot_data{$p}->{metadata}->{$_} } ( "year", "studyDbId", "studyName", "studyDesign", "locationDbId", "locationName", "germplasmDbId", "germplasmName", "germplasmSynonyms", "observationLevel", "observationUnitDbId", "observationUnitName", "replicate", "blockNumber", "plotNumber" );

        foreach my $trait (@sorted_traits) {
            my $tab = $plot_data{$p}->{$trait};
            $line .= defined($tab) ? "\t".$tab : "\t";
        }
        push @info, $line;
    }
    print STDERR "Construct Pheno Matrix End:".localtime."\n";
    return @info;
}


sub get_synonym_hash_lookup {
    my $self = shift;
    print STDERR "Synonym Start:".localtime."\n";
    my $schema = $self->bcs_schema();
    my $synonym_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'stock_synonym', 'stock_property')->cvterm_id();
    my $accession_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'accession', 'stock_type')->cvterm_id();
    my $q = "SELECT stock.uniquename, stockprop.value FROM stock JOIN stockprop USING(stock_id) WHERE stock.type_id=$accession_type_id AND stockprop.type_id=$synonym_type_id;";
    my $h = $schema->storage->dbh()->prepare($q);
    $h->execute();
    my %result;
    while (my ($uniquename, $synonym) = $h->fetchrow_array()) {
        if(exists($result{$uniquename})) {
            my $synonyms = $result{$uniquename};
            push @$synonyms, $synonym;
            $result{$uniquename} = $synonyms;
        } else {
            $result{$uniquename} = [$synonym];
        }
    }
    print STDERR "Synonym End:".localtime."\n";
    return \%result;
}
1;