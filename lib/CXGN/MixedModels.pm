

package CXGN::MixedModels;

use Moose;
use Data::Dumper;
use File::Slurp qw| slurp |;
use CXGN::Tools::Run;
use CXGN::Phenotypes::File;

has 'dependent_variable' => (is => 'rw', isa => 'Str|Undef');

has 'fixed_factors' => (is => 'rw', isa => 'Ref', default => sub {[]});

has 'fixed_factors_interaction' => (is => 'rw', isa => 'Ref', default => sub{[]});

has 'random_factors' => (is => 'rw', isa => 'Ref', default => sub {[]});

has 'random_factors_random_slope' => (is => 'rw', isa => 'Bool');

has 'traits' => (is => 'rw', isa => 'Ref');

has 'levels' => (is => 'rw', isa => 'HashRef' );

has 'phenotype_file' => (is => 'rw', isa => 'CXGN::Phenotypes::File|Undef');

has 'tempfile' => (is => 'rw', isa => 'Str|Undef');

sub BUILD {
    my $self = shift;

    my $phenotype_file;
    
    if ($self->tempfile()) { 
	$phenotype_file = CXGN::Phenotypes::File->new( { file => $self->tempfile() } );
    }
    $self->phenotype_file($phenotype_file);
   
}

sub generate_model {
    my $self = shift;

    my $tempfile = $self->tempfile();
    my $dependent_variable = $self->dependent_variable();
    my $fixed_factors = $self->fixed_factors();
    my $fixed_factors_interaction = $self->fixed_factors_interaction();
    my $random_factors = $self->random_factors();
    my $random_factors_random_slope = $self->random_factors_random_slope();

    my $error;

    my @addends = ();
    
    print STDERR join("\n", ("DV", $dependent_variable, "FF", Dumper($fixed_factors), "RF", Dumper($random_factors), "TF", $tempfile, "FFI", Dumper($fixed_factors_interaction)));

    print STDERR Dumper($fixed_factors);
    my $model = "";

    if (! $dependent_variable) {
	die "Need a dependent variable set in CXGN::MixedModels... Ciao!";
    }

    my $formatted_fixed_factors = "";
    if (@$fixed_factors) { 
	$formatted_fixed_factors = join(" + ", @$fixed_factors);
	push @addends, $formatted_fixed_factors;
    }

    my $formatted_fixed_factors_interaction = "";
    foreach my $interaction (@$fixed_factors_interaction) {
	if (exists($interaction->[0]) && exists($interaction->[1])) { 
	    my $term = " (1+$interaction->[0] \| $interaction->[1]) ";
	    $formatted_fixed_factors_interaction .= $term;
	    push @addends, $formatted_fixed_factors_interaction;
	}
	else {
	    $error = "Interaction terms are not correctly defined.";
	}
    }
    
    my $formatted_random_factors = "";
#    if ($random_factors_random_slope) { 
#	$formatted_random_factors = " (1 + $random_factors->[0] | $random_factors->[1]) ";
#
#    }
 #   else {
	if (@$random_factors) { 
	    $formatted_random_factors = join(" + ",  map { "(1|$_)" } @$random_factors);
	    push @addends, $formatted_random_factors;
	}

    #}
    $model .= join(" + ", @addends);
    
    return $model;
}

sub run_model {
    my $self = shift;

    my $tempfile = $self->tempfile();
    # generate params_file
    #
    my $param_file = $tempfile.".params";
    open(my $F, ">", $param_file) || die "Can't open $param_file for writing.";
    my $model = $self->generate_model();
    print $F $model;
    close($F);
    # run r script to create model
    #
    my $cmd = "R CMD BATCH  '--args datafile=\"".$tempfile."\" paramfile=\"".$tempfile.".params\"' /R/mixed_models.R $tempfile.out";
    
    print STDERR "running R command $cmd...\n";
    system($cmd);
    print STDERR "Done.\n";

    my $resultfile = $tempfile.".results";

}


1;
