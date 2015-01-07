
package SGN::Controller::Search::Trial;

use Moose;

BEGIN { extends 'Catalyst::Controller'; }

sub trial_search_page : Path('/search/trials/') Args(0) { 
    my $self = shift;
    my $c = shift;
    
    $c->stash->{template} = '/search/trials.mas';

}

1;
