package CXGN::BrAPI::Authenticate;

use Moose;
use Moose::Role;
use Data::Dumper;
use CXGN::Login;

my $logger = Log::Log4perl->get_logger();

requires qw( bcs_schema );

sub authenticate_user {
    my $status = shift;
    my $session_token = shift;
    my $authenticate_level = shift;

    my ($person_id, $user_type, $user_pref, $expired) = CXGN::Login->new($self->bcs_schema->storage->dbh)->query_from_cookie($session_token);
    #$logger->error($person_id." : ".$user_type." : ".$expired);

    if (!$person_id || $expired || $user_type ne $authenticate_level) {
        return 0;
    }

    return 1;
}

1;
