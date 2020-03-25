package CXGN::BrAPI::v2::Trials;

use Moose;
use Data::Dumper;
use SGN::Model::Cvterm;
use CXGN::Trial::Folder;
use CXGN::BrAPI::Pagination;
use CXGN::BrAPI::JSONResponse;

extends 'CXGN::BrAPI::v2::Common';

sub search {
	my $self = shift;
	my $search_params = shift;
	my $schema = $self->bcs_schema;
    my $page_size = $self->page_size;
    my $page = $self->page;
    my $data;
    my $status = $self->status();
    my $continue = 0;

    my $crop = $search_params->{crop};

    my $active = $search_params->{active} ? $search_params->{active}[0] : 'true';
    my @commoncrop_names = $search_params->{commonCropNames} ? @{$search_params->{commonCropNames}} : ();
    my @contact_dbids = $search_params->{contactDbIds} ? @{$search_params->{contactDbIds}} : ();
    my @daterange_start = $search_params->{searchDateRangeStart} ? @{$search_params->{searchDateRangeStart}} : ();
    my @daterange_end = $search_params->{searchDateRangeEnd} ? @{$search_params->{searchDateRangeEnd}} : ();
    my @externalreference_ids = $search_params->{externalReferenceIDs} ? @{$search_params->{externalReferenceIDs}} : ();
    my @externalreference_sources = $search_params->{externalReferenceSources} ? @{$search_params->{externalReferenceSources}} : ();
    my @location_dbids = $search_params->{locationDbIds} ? @{$search_params->{locationDbIds}} : ();
    my @location_names = $search_params->{locationNames} ? @{$search_params->{locationNames}} : ();
    my @program_dbids = $search_params->{programDbIds} ? @{$search_params->{programDbIds}} : ();
    my @program_names = $search_params->{programNames} ? @{$search_params->{programNames}} : ();
    my @study_dbids = $search_params->{studyDbIds} ? @{$search_params->{studyDbIds}} : ();
    my @study_names = $search_params->{studyNames} ? @{$search_params->{studyNames}} : ();
    my @trial_dbids = $search_params->{trialDbIds} ? @{$search_params->{trialDbIds}} : ();
    my @trial_names = $search_params->{trialNames} ? @{$search_params->{trialNames}} : ();
    my @trial_PUIs = $search_params->{trialPUIs} ? @{$search_params->{trialPUIs}} : ();

    if (scalar(@contact_dbids)>0 || scalar(@daterange_start)>0 || scalar(@daterange_end)>0 || scalar(@trial_PUIs)>0 || scalar(@externalreference_sources)>0 || scalar(@externalreference_ids)>0){
        push @$status, { 'error' => 'The following parameters are not implemented: contactDbId, searchDateRangeStart, searchDateRangeEnd, trialPUI, externalReferenceID, externalReferenceSource' };
    }

    my %location_id_list;
    if (scalar(@location_dbids)>0){
        %location_id_list = map { $_ => 1} @location_dbids;
    }

    my %location_names_list;
    if (scalar(@location_names)>0){
        %location_names_list = map { $_ => 1} @location_names;
    }

    my %study_id_list;
    if (scalar(@study_dbids)>0){
        %study_id_list = map { $_ => 1} @study_dbids;
    }

    my %study_name_list;
    if (scalar(@study_names)>0){
        %study_name_list = map { $_ => 1} @study_names;
    }

    my %program_id_list;
    if (scalar(@program_dbids)>0){
        %program_id_list = map { $_ => 1} @program_dbids;
    }

    my %program_name_list;
    if (scalar(@program_names)>0){
        %program_name_list = map { $_ => 1} @program_names;
    }

    my %trial_id_list;
    if (scalar(@trial_dbids)>0){
        %trial_id_list = map { $_ => 1} @trial_dbids;
    }

    my %trial_name_list;
    if (scalar(@trial_names)>0){
        %trial_name_list = map { $_ => 1} @trial_names;
    }

    if (scalar(@commoncrop_names)>0) {
        if ( !grep( /^$crop$/, @commoncrop_names ) ) {
            $continue = $continue + 1;
        }
    }
    if (lc $active ne 'true') { $continue = $continue + 1 }

    if($continue < 1) {
        my $p = CXGN::BreedersToolbox::Projects->new( { schema => $schema  } );
        my $programs = $p->get_breeding_programs();

        foreach my $program (@$programs) {
            unless (%program_id_list && !exists($program_id_list{$program->[0]}) || %program_name_list && !exists($program_name_list{$program->[1]})) { # for each program not excluded, retrieve folders and studies
                $program = { "id" => $program->[0], "name" => $program->[1], "program_id" => $program->[0], "program_name" => $program->[1],  "program_description" => $program->[2] };
                $data = _get_folders($program, $schema, $data, 'breeding_program', $crop, \%location_id_list, \%location_names_list, \%study_id_list, \%study_name_list, \%trial_id_list, \%trial_name_list);
            }
        }
    }

    my $total_count = $data ? scalar @{$data} : 0;
    my %result = (data => $data);
    my @data_files;
    my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$self->page_size,$self->page);
    return CXGN::BrAPI::JSONResponse->return_success(\%result, $pagination, \@data_files, $self->status, 'Trials result constructed');
}

sub details {
	my $self = shift;
	my $folder_id = shift;
    my $crop = shift;

	my $page_size = $self->page_size;
	my $page = $self->page;
	my $status = $self->status;
	my $schema = $self->bcs_schema;
	my $trial_check = $schema->resultset('Project::Project')->find({project_id=>$folder_id});
	if ($trial_check){
		my $folder = CXGN::Trial::Folder->new(bcs_schema=>$self->bcs_schema(), folder_id=>$folder_id);
		if ($folder->is_folder) {
			my $total_count = 1;
			my @folder_studies;
			my %additional_info;
            my $folder_id = $folder->folder_id;
            my $folder_description = $folder->name;
            my $breeding_program_id = $folder->breeding_program->project_id();

			my %result = (
                active=>JSON::true,
				additionalInfo=>\%additional_info,
                commonCropName=>$crop,
                contacts=>undef,
                datasetAuthorships=>undef,
                documentationURL=>undef,
                endDate=>undef,
                externalReferences=>undef,
                programDbId=>qq|$breeding_program_id|,
                programName=>$folder->breeding_program->name(),
                publications=>undef,
                startDate=>undef,
                trialDbId=>qq|$folder_id|,
                trialName=>$folder->name,
                trialDescription=>$folder_description,
                trialPUI=>undef
			);
			my @data_files;
			my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
			return CXGN::BrAPI::JSONResponse->return_success(\%result, $pagination, \@data_files, $status, 'Trial detail result constructed');
		} else {
			return CXGN::BrAPI::JSONResponse->return_error($status, 'The given trialDbId does not match an actual trial.');
		}
	} else {
		return CXGN::BrAPI::JSONResponse->return_error($status, 'The given trialDbId not found.');
	}
}

sub _get_folders {
	my $self = shift;
    my $schema = shift;
    my $data = shift;
    my $parent_type = shift;
    my $crop = shift;
    my $location_id_list = shift;
    my $location_names_list = shift;
    my $study_id_list = shift;
    my $study_name_list = shift;
    my $trial_id_list = shift;
    my $trial_name_list = shift;
    my %location_id_list = %{$location_id_list};
    my %location_names_list = %{$location_names_list};
    my %study_id_list = %{$study_id_list};
    my %study_name_list = %{$study_name_list};
    my %trial_id_list = %{$trial_id_list};
    my %trial_name_list = %{$trial_name_list};
    my %additional_info;
    my @folder_studies;

	my $studies = _get_studies($self, $schema, $parent_type);
    my %studies = %{$studies};
	if (%studies) {
        foreach my $study (sort keys %studies) {

			if ($studies{$study}->{'folder_for_trials'}) { # it's a folder, recurse a layer deeper
                $data = _get_folders($studies{$study}, $schema, $data, 'folder', $crop, \%location_id_list, \%location_names_list, \%study_id_list, \%study_name_list, \%trial_id_list, \%trial_name_list);
            }
            elsif (!$studies{$study}->{'folder_for_crosses'} && !$studies{$study}->{'folder_for_trials'} && $studies{$study}->{'trial_folder'}) { # it's a folder, recurse a layer deeper
                $data = _get_folders($studies{$study}, $schema, $data, 'folder', $crop, \%location_id_list, \%location_names_list, \%study_id_list, \%study_name_list, \%trial_id_list, \%trial_name_list);
            }
            elsif ($studies{$study}->{'design'}) { # it's a study, add it to studies array
                my $passes_search = 1;
                if (%location_id_list) {
                    if (!exists($location_id_list{ $studies{$study}->{'project location'}}) ) {
                        $passes_search = 0;
                    }
                }
                if (%location_names_list) {
                    my $location = $schema->resultset("NaturalDiversity::NdGeolocation")->find({nd_geolocation_id=>$studies{$study}->{'project location'}});
                    if ($location){
                        if (!exists($location_names_list{$location->description}) ) {
                            $passes_search = 0;
                        }
                    }
                }
                if ( %study_id_list ) {
                    if (!exists($study_id_list{ $studies{$study}->{'id'} } ) ) {
                        $passes_search = 0;
                    }
                }
                if ( %study_name_list ) {
                    if (!exists($study_name_list{ $studies{$study}->{'name'} } ) ) {
                        $passes_search = 0;
                    }
                }

                if ($passes_search){
                    my $location_name = '';
                    my $location = $schema->resultset("NaturalDiversity::NdGeolocation")->find({nd_geolocation_id=>$studies{$study}->{'project location'}});
                    if ($location){
                        $location_name = $location->description;
                    }
                    push @folder_studies, {
                        studyDbId=>qq|$studies{$study}->{'id'}|,
                        studyName=>$studies{$study}->{'name'},
                        locationDbId=>$studies{$study}->{'project location'},
                        locationName=>$location_name
                    };
                }
    		}
    	}
    }

    my $trial_filter = 0;

    if (scalar(keys %trial_id_list) > 0 && !exists($trial_id_list{ $self->{'id'} } )){
        $trial_filter = 1;
    } elsif (scalar(keys %trial_name_list) > 0 && !exists($trial_name_list{ $self->{'name'} } )){
        $trial_filter = 1;
    } 

    unless ( scalar @folder_studies < 1 && (%location_id_list || %study_id_list || %study_name_list || %location_names_list || %trial_id_list )) { #skip empty folders if call was issued with search paramaters
        if ($trial_filter < 1 ){
            push @{$data}, {
                            active=>JSON::true,
                            additionalInfo=>\%additional_info,
                            commonCropName=>$crop,
                            contacts=>undef,
                            datasetAuthorships=>undef,
                            documentationURL=>undef,
                            endDate=>undef,
                            externalReferences=>undef,
                            programDbId=>qq|$self->{'program_id'}|,
                            programName=>$self->{'program_name'},
                            publications=>undef,
                            startDate=>undef,
                            trialDbId=>qq|$self->{'id'}|,
                            trialName=>$self->{'name'},
                            trialDescription=>$self->{'program_description'},
                            trialPUI=>undef
            }				
        }; 
    }

	return $data;

}

sub _get_studies {

    my $self = shift;
    my $schema = shift;
    my $parent_type = shift;
    my (@folder_contents, %studies);

    if ($parent_type eq 'breeding_program') {
        my $rs = $schema->resultset("Project::Project")->search_related(
            'project_relationship_subject_projects',
            {   'type.name' => 'trial_folder'
            },
            {   join => 'type'
            });
        @folder_contents = map { $_->subject_project_id() } $rs->all();
    }

    my $rs = $schema->resultset("Project::Project")->search_related(
        'project_relationship_subject_projects',
        {   object_project_id => $self->{'id'},
            subject_project_id => { 'not in' => \@folder_contents }
        },
        {   join      => { subject_project => { projectprops => 'type' } },
            '+select' => ['subject_project.name', 'projectprops.value', 'type.name'],
            '+as'     => ['project_name', 'project_value', 'project_type']
        }
     );

    while (my $row = $rs->next) {
        my $name = $row->get_column('project_name');
        $studies{$name}{'name'} = $name;
        $studies{$name}{'id'} = $row->subject_project_id();
        $studies{$name}{'program_name'} = $self->{'program_name'};
        $studies{$name}{'program_id'} = $self->{'program_id'};
        $studies{$name}{$row->get_column('project_type')} = $row->get_column('project_value');
    }

    return \%studies
}

1;
