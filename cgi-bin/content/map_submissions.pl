
use CGI ();
use CatalystX::GlobalContext qw( $c );
print CGI->new->redirect( -uri => $c->uri_for_action( '/cview/map_submission' )->relative(), -status => 301 );


