package CXGN::Phenotypes::ParseUpload::Plugin::MetabolomicsSpreadsheetCSV;

# Validate Returns %validate_result = (
#   error => 'error message'
#)

# Parse Returns %parsed_result = (
#   data => {
#       tissue_samples1 => {
#           metabolomics => {
#              metabolites => [{
#                 "M1" => "0.939101707",
#                 "M2" => "0.93868202",
#              }],
#          }
#       }
#   },
#   units => [tissue_samples1],
#   variables => [varname1, varname2],
#   variables_desc => {
#       "M1" => {
#           "inchi_key" => "AAJHVVLGKCKBSH-UHFFFAOYNA-N",
#           "compound_name" => "Avenacoside A",
#       },
#       "M2" => {
#           "inchi_key" => "UHISGSDYAIIBMO-HZJYTTRNNA-N",
#           "compound_name" => "Gingerglycolipid B",
#       }
#   }
#)

use Moose;
use JSON;
use Data::Dumper;
use Text::CSV;
use CXGN::List::Validate;

sub name {
    return "highdimensionalphenotypes spreadsheet metabolomics";
}

sub validate {
    my $self = shift;
    my $filename = shift;
    my $timestamp_included = shift;
    my $data_level = shift;
    my $schema = shift;
    my $zipfile = shift; #not relevant for this plugin
    my $nd_protocol_id = shift;
    my $nd_protocol_filename = shift;
    my $delimiter = ',';
    my %parse_result;

    my $csv = Text::CSV->new({ sep_char => ',' });

    open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";

    if (!$fh) {
        $parse_result{'error'} = "Could not read file.";
        print STDERR "Could not read file.\n";
        return \%parse_result;
    }

    my $header_row = <$fh>;
    my @columns;
    # print STDERR Dumper $csv->fields();
    if ($csv->parse($header_row)) {
        @columns = $csv->fields();
    } else {
        $parse_result{'error'} = "Could not parse header row.";
        print STDERR "Could not parse header.\n";
        return \%parse_result;
    }
    
    my $header_col_1 = shift @columns;
    if ( $header_col_1 ne "sample_name" ) {
      $parse_result{'error'} = "First cell must be 'sample_name'. Please, check your file.";
      print STDERR "First cell must be 'sample_name'\n";
      return \%parse_result;
    }

    my @metabolite = @columns;

    my @samples;
    while (my $line = <$fh>) {
        my @fields;
        if ($csv->parse($line)) {
            @fields = $csv->fields();
        }
        my $sample_name = shift @fields;
        push @samples, $sample_name;

        foreach (@fields) {
            if (not $_=~/^[-+]?\d+\.?\d*$/ && $_ ne 'NA'){
                $parse_result{'error'}= "It is not a real value for metabolite. Must be numeric: '$_'";
                return \%parse_result;
            }
        }
    }
    close $fh;

    open($fh, '<', $nd_protocol_filename)
        or die "Could not open file '$nd_protocol_filename' $!";

    if (!$fh) {
        $parse_result{'error'} = "Could not read file.";
        print STDERR "Could not read file.\n";
        return \%parse_result;
    }

    $header_row = <$fh>;
    # print STDERR Dumper $csv->fields();
    if ($csv->parse($header_row)) {
        @columns = $csv->fields();
    } else {
        $parse_result{'error'} = "Could not parse header row.";
        print STDERR "Could not parse header.\n";
        return \%parse_result;
    }
    
    if ( $columns[0] ne "metabolite_name" ||
        $columns[1] ne "inchi_key" ||
        $columns[2] ne "compound_name") {
      $parse_result{'error'} = "Header row must be 'metabolite_name', 'inchi_key', 'compound_name'. Please, check your file.";
      return \%parse_result;
    }
    while (my $line = <$fh>) {
        my @fields;
        if ($csv->parse($line)) {
            @fields = $csv->fields();
        }
        my $metabolite_name = $fields[0];
        my $inchi_key = $fields[1];
        my $compound_name = $fields[2];

        if (!$metabolite_name){
            $parse_result{'error'}= "Metabolite name is required!";
            return \%parse_result;
        }
    }
    close $fh;

    my $samples_validator = CXGN::List::Validate->new();
    my @samples_missing = @{$samples_validator->validate($schema, $data_level, \@samples)->{'missing'}};
    if (scalar(@samples_missing) > 0) {
        my $samples_string = join ', ', @samples_missing;
        $parse_result{'error'}= "The following samples in your file are not valid in the database (".$samples_string."). Please add them in a sampling trial first!";
        return \%parse_result;
    }

    if ($nd_protocol_id) {
        my $metabolomics_protocol_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'high_dimensional_phenotype_metabolomics_protocol', 'protocol_type')->cvterm_id();
        my $protocol = CXGN::Phenotypes::HighDimensionalPhenotypeProtocol->new({
            bcs_schema => $schema,
            nd_protocol_id => $nd_protocol_id,
            nd_protocol_type_id => $metabolomics_protocol_cvterm_id
        });
        my $metabolite_in_protocol = $protocol->header_column_names;
        my %metabolites_in_protocol_hash;
        foreach (@$metabolite_in_protocol) {
            $metabolites_in_protocol_hash{$_}++;
        }

        my @metabolites_not_in_protocol;
        foreach (@metabolite) {
            if (!exists($metabolites_in_protocol_hash{$_})) {
                push @metabolites_not_in_protocol, $_;
            }
        }

        #If there are markers in the uploaded file that are not saved in the protocol, they will be returned along in the error message
        if (scalar(@metabolites_not_in_protocol)>0){
            $parse_result{'error'} = "The following metabolites are not in the database for the selected protocol: ".join(',',@metabolites_not_in_protocol);
            return \%parse_result;
        }
    }

    return 1;
}


sub parse {
    my $self = shift;
    my $filename = shift;
    my $timestamp_included = shift;
    my $data_level = shift;
    my $schema = shift;
    my $zipfile = shift; #not relevant for this plugin
    my $user_id = shift; #not relevant for this plugin
    my $c = shift; #not relevant for this plugin
    my $nd_protocol_id = shift;
    my $nd_protocol_filename = shift;
    my $delimiter = ',';
    my %parse_result;

    my $csv = Text::CSV->new({ sep_char => ',' });
    my @header;
    my @fields;
    my @wave;
    my @header_row;
    my $header_column_number = 0;
    my %header_column_info; #column numbers of key info indexed from 0;
    my %observation_units_seen;
    my %traits_seen;
    my @observation_units;
    my @traits;
    my %data;
    my %metadata_hash;
    my $row_number = 0;
    my $col_number=0;
    my $number=0;
    my $size;
    my $count;
    my $num_cols;
    my %header_column_details;

    open(my $fh, '<', $filename)
        or die "Could not open file '$filename' $!";

    if (!$fh) {
        $parse_result{'error'} = "Could not read file.";
        print STDERR "Could not read file.\n";
        return \%parse_result;
    }

    while (my $row = $csv->getline ($fh)) {
        # print STDERR "Row is ".Dumper($row)."\n";
        if ( $row_number == 0 ) {
            @header = @{$row};
            $num_cols = scalar(@header);
        } elsif ( $row_number > 0 ) {# get data
            my @columns = @{$row};
            my $observationunit_name = $columns[0];
            $observation_units_seen{$observationunit_name} = 1;
            # print "The plots are $observationunit_name\n";
            my %spectra;
            foreach my $col (1..$num_cols-1){
                my $column_name = $header[$col];
                if ($column_name ne ''){
                    my $metabolite_name = $column_name;
                    $traits_seen{$metabolite_name}++;
                    my $metabolite_value = $columns[$col];
                    $spectra{$metabolite_name} = $metabolite_value;
                }
            }
            push @{$data{$observationunit_name}->{'metabolomics'}->{'metabolites'}}, \%spectra;
        }
        $row_number++;
    }
    close($fh);

    open($fh, '<', $nd_protocol_filename)
        or die "Could not open file '$nd_protocol_filename' $!";

    if (!$fh) {
        $parse_result{'error'} = "Could not read file.";
        print STDERR "Could not read file.\n";
        return \%parse_result;
    }

    my $header_row = <$fh>;
    my @columns;
    # print STDERR Dumper $csv->fields();
    if ($csv->parse($header_row)) {
        @columns = $csv->fields();
    } else {
        $parse_result{'error'} = "Could not parse header row.";
        print STDERR "Could not parse header.\n";
        return \%parse_result;
    }

    while (my $line = <$fh>) {
        my @fields;
        if ($csv->parse($line)) {
            @fields = $csv->fields();
        }
        my $metabolite_name = $fields[0];
        my $inchi_key = $fields[1];
        my $compound_name = $fields[2];

        $header_column_details{$metabolite_name} = {
            inchi_key => $inchi_key,
            compound_name => $compound_name,
        };
    }
    close $fh;

    foreach my $obs (sort keys %observation_units_seen) {
        push @observation_units, $obs;
    }
    foreach my $trait (sort keys %traits_seen) {
        push @traits, $trait;
    }

    $parse_result{'data'} = \%data;
    $parse_result{'units'} = \@observation_units;
    $parse_result{'variables'} = \@traits;
    $parse_result{'variables_desc'} = \%header_column_details;
    return \%parse_result;
    # print STDERR Dumper \%parse_result;
}

1;
