
package CXGN::List::Transform::Plugin::ProjectIds2Projects;

use Moose;
use Data::Dumper;

my $logger = Log::Log4perl->get_logger();

sub name { 
    return "project_ids_2_projects";
}

sub display_name { 
    return "Projects IDs to project";
}

sub can_transform { 
    my $self = shift;
    my $type1 = shift;
    my $type2= shift;

    if ((($type1 eq "project_ids") and ($type2 eq "projects")) or (($type1 eq "trial_ids")  and ($type2 eq "trials"))) { 
        $logger->debug("ProjectIds2Projects: can transform $type1 to $type2");
        return 1;
    }
    return 0;
}

sub transform { 
    my $self = shift;
    my $schema = shift;
    my $list = shift;

    my @transform = ();
    my @missing = ();

    foreach my $l (@$list) { 
        $logger->debug("project_name = $l ");
        my $rs = $schema->resultset("Project::Project")->search({
            project_id => $l,
        });
        if ($rs->count() == 0) { 
            push @missing, $l;
        }
        else { 
            push @transform, $rs->first()->name();
        }
    }
    $logger->error(" transform array = " . Dumper(@transform));
    $logger->error(" missing array = " . Dumper(@missing));
    return {
        transform => \@transform,
        missing   => \@missing,
    };
}

1;
