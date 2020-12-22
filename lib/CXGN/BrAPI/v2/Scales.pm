package CXGN::BrAPI::v2::Scales;

use Moose;
use Data::Dumper;
use Try::Tiny;
use List::Util 'max';

has 'bcs_schema' => (
    isa => 'Bio::Chado::Schema',
    is => 'rw',
    required => 1,
);

has 'scale' => (
    is => 'ro',
    isa => 'HashRef[Any]',
);

has 'cvterm_id' => (
    isa => 'Int',
    is => 'rw',
    required => 1,
);

has 'cv_id' => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $cv_id = $self->bcs_schema->resultset("Cv::Cv")->find(
            {
                name => 'trait_property'
            },
            { key => 'cv_c1' }
        )->get_column('cv_id');
        return $cv_id;
    }
);

has 'scale_categories_id' => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $scale_categories_id = $self->bcs_schema->resultset("Cv::Cvterm")->find(
            {
                name        => 'trait_categories',
                cv_id       => $self->cv_id,
                is_obsolete => 0
            },
            { key => 'cvterm_c1' }
        )->get_column('cvterm_id');
        return $scale_categories_id;
    }
);

has 'scale_categories_label_id' => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $scale_categories_label_id = $self->bcs_schema->resultset("Cv::Cvterm")->find(
            {
                name        => 'trait_categories_label',
                cv_id       => $self->cv_id,
                is_obsolete => 0
            },
            { key => 'cvterm_c1' }
        )->get_column('cvterm_id');
        return $scale_categories_label_id;
    }
);

has 'scale_categories_value_id' => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $scale_categories_value_id = $self->bcs_schema->resultset("Cv::Cvterm")->find(
            {
                name        => 'trait_categories_value',
                cv_id       => $self->cv_id,
                is_obsolete => 0
            },
            { key => 'cvterm_c1' }
        )->get_column('cvterm_id');
        return $scale_categories_value_id;
    }
);



has 'scale_format_id' => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $scale_format_id = $self->bcs_schema->resultset("Cv::Cvterm")->find(
            {
                name        => 'trait_format',
                cv_id       => $self->cv_id,
                is_obsolete => 0
            },
            { key => 'cvterm_c1' }
        )->get_column('cvterm_id');
        return $scale_format_id;
    }
);

has 'scale_maximum_id' => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $scale_maximum_id = $self->bcs_schema->resultset("Cv::Cvterm")->find(
            {
                name        => 'trait_maximum',
                cv_id       => $self->cv_id,
                is_obsolete => 0
            },
            { key => 'cvterm_c1' }
        )->get_column('cvterm_id');
        return $scale_maximum_id;
    }
);

has 'scale_minimum_id' => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $scale_minimum_id = $self->bcs_schema->resultset("Cv::Cvterm")->find(
            {
                name        => 'trait_minimum',
                cv_id       => $self->cv_id,
                is_obsolete => 0
            },
            { key => 'cvterm_c1' }
        )->get_column('cvterm_id');
        return $scale_minimum_id;
    }
);

has 'scale_decimal_places_id' => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $scale_decimal_places_id = $self->bcs_schema->resultset("Cv::Cvterm")->find(
            {
                name        => 'trait_decimal_places',
                cv_id       => $self->cv_id,
                is_obsolete => 0
            },
            { key => 'cvterm_c1' }
        )->get_column('cvterm_id');
        return $scale_decimal_places_id;
    }
);

has 'scale_db' => (
    isa => 'HashRef[Any]',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        my %scale;
        my %categories;

        my $props = $self->bcs_schema()->resultset("Cv::Cvtermprop")->search(
            {
                cvterm_id => $self->cvterm_id()
            },
            {order_by => { -asc => 'rank' }}
        );

        my $scale_ref = \%scale;

        while (my $prop = $props->next()){
            my $category = $categories{$prop->get_column('rank')};

            if ($prop->get_column('type_id') == $self->scale_categories_label_id) {
                $category->{'label'} = $prop->get_column('value');
                $categories{$prop->get_column('rank')}=$category;
            }

            if ($prop->get_column('type_id') == $self->scale_categories_value_id) {
                $category->{'value'} = $prop->get_column('value');
                $categories{$prop->get_column('rank')}=$category;
            }

            if ($prop->get_column('type_id') == $self->scale_format_id) {
                $scale_ref->{'dataType'} = $prop->get_column('value');
            }
            if ($prop->get_column('type_id') == $self->scale_decimal_places_id) {
                $scale_ref->{'decimalPlaces'} = $prop->get_column('value')+0;
            }

            if ($prop->get_column('type_id') == $self->scale_maximum_id) {
                $scale_ref->{'validValues'}{'max'} = $prop->get_column('value')+0;
            }
            if ($prop->get_column('type_id') == $self->scale_minimum_id) {
                $scale_ref->{'validValues'}{'min'} = $prop->get_column('value')+0;
            }
        }

        if (%categories) {
            my $ref = \%categories;
            my $maxkey = max keys %$ref;
            my @array = @{$ref}{0 .. $maxkey};
            $scale_ref->{'validValues'}{'categories'} = \@array;
        }

        return $scale_ref;
    }
);

sub store {
    my $self = shift;
    my $schema = $self->bcs_schema();
    my $cvterm_id = $self->cvterm_id();
    my $scale = $self->scale();
    my @scale_categories;

    if ($self->scale->{'validValues'}{'categories'}) {
        @scale_categories = @{$self->scale->{'validValues'}{'categories'}};
    }

    my $scale_format_id = $self->scale_format_id;
    my $scale_decimal_places_id = $self->scale_decimal_places_id;
    my $scale_categories_id = $self->scale_categories_id;
    my $scale_categories_label_id = $self->scale_categories_label_id;
    my $scale_categories_value_id = $self->scale_categories_value_id;
    my $scale_maximum_id = $self->scale_maximum_id;
    my $scale_minimum_id = $self->scale_minimum_id;

    my $scale_format = $scale->{'dataType'};
    my $scale_decimal_places = $scale->{'decimalPlaces'};
    my $scale_categories = $scale->{'validValues'}{'categories'};
    my $scale_maximum = $scale->{'validValues'}{'max'};
    my $scale_minimum = $scale->{'validValues'}{'min'};

    my $rank = 0;
    my $categories_v1 = "";

    my $coderef = sub {

        # write category values for v2
        foreach my $category (@scale_categories) {
            my $label = $category->{'label'};
            my $value = $category->{'value'};

            # write external reference info to dbxrefprop
            my $prop_id = $schema->resultset("Cv::Cvtermprop")->create(
                {
                    cvterm_id => $cvterm_id,
                    type_id   => $scale_categories_label_id,
                    value     => $label,
                    rank      => $rank
                }
            );

            my $prop_source = $schema->resultset("Cv::Cvtermprop")->create(
                {
                    cvterm_id => $cvterm_id,
                    type_id   => $scale_categories_value_id,
                    value     => $value,
                    rank      => $rank
                }
            );

            $rank++;

            # form categories string for v1 call
            $categories_v1=$categories_v1.$label."=".$value."/";
        }

        my $format = $schema->resultset("Cv::Cvtermprop")->create(
            {
                cvterm_id => $cvterm_id,
                type_id   => $scale_format_id,
                value     => $scale_format,
                rank      => 0
            }
        );

        if (defined($scale_decimal_places) && length($scale_decimal_places)) {
            my $decimal_places = $schema->resultset("Cv::Cvtermprop")->create(
                {
                    cvterm_id => $cvterm_id,
                    type_id   => $scale_decimal_places_id,
                    value     => $scale_decimal_places,
                    rank      => 0
                }
            );
        }

        # write in format used by v1 calls
        if ($scale_categories) {
            my $categories = $schema->resultset("Cv::Cvtermprop")->create(
                {
                    cvterm_id => $cvterm_id,
                    type_id   => $scale_categories_id,
                    value     => $categories_v1,
                    rank      => 0
                }
            );
        }

        if (defined($scale_maximum) && length($scale_maximum)) {
            my $maximum = $schema->resultset("Cv::Cvtermprop")->create(
                {
                    cvterm_id => $cvterm_id,
                    type_id   => $scale_maximum_id,
                    value     => $scale_maximum,
                    rank      => 0
                }
            );
        }

        if (defined($scale_minimum) && length($scale_minimum)) {
            my $minimum = $schema->resultset("Cv::Cvtermprop")->create(
                {
                    cvterm_id => $cvterm_id,
                    type_id   => $scale_minimum_id,
                    value     => $scale_minimum,
                    rank      => 0
                }
            );
        }

    };

    my $transaction_error;

    try {
        $schema->txn_do($coderef);
    } catch {
        $transaction_error =  $_;
    };

    if ($transaction_error) {
        return {error => "Scale transaction error trying to write to db"}
    }

    return { success => "Scale added successfully" };

}

1;