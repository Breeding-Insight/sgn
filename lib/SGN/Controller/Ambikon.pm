package SGN::Controller::Ambikon;
use Moose;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

SGN::Controller::Ambikon - support for running the SGN app as an
Ambikon subsite.

=head1 PUBLIC ACTIONS

=head2 theme_template

Public path: /ambikon/theme_template

Serves a bare page with no content, suitable for use by Ambikon
theming postprocessors that consume the
L<Ambikon::IntegrationServer::Role::TemplateTheme> role.

=cut

sub theme_template : Path('/ambikon/theme_template') {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/ambikon/theme_template.mas';
}

=head2 search_xrefs

service to provide Ambikon xrefs for all the defined SiteFeatures

=cut

sub search_xrefs :Path('/ambikon/xrefs/search') Args(0) {
    my ( $self, $c ) = @_;

    $c->go('/sitefeatures/feature_xrefs');
}


1;
