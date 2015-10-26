
use strict;

use lib 't/lib';

use Test::More;
use SGN::Test::WWW::WebDriver;

my $d = SGN::Test::WWW::WebDriver->new();

$d->login_as("submitter");

$d->get_ok("/", "get root url test");

my $out = $d->find_element_ok("lists_link", "name", "find lists_link")->click();

# delete the list should it already exist
#
if ($d->driver->get_page_source() =~ /new_test_list/) { 
    print "DELETE LIST new_test_list... ";
    $d->find_element_ok("delete_list_new_test_list", "id", "find delete_list_new_test_list test")->click();
    $d->driver->accept_alert();
    sleep(1);

    print "Done.\n";
}
 
sleep(1);

print "Adding new list...\n";

$d->find_element_ok("add_list_input", "id", "find add list input");

my $add_list_input = $d->find_element_ok("add_list_input", "id", "find add list input test");
   
$add_list_input->send_keys("new_test_list");

$d->find_element_ok("add_list_button", "id", "find add list button test")->click();

$d->find_element_ok("view_list_new_test_list", "id", "view list test")->click();

sleep(1);

$d->find_element_ok("dialog_add_list_item", "id", "add test list")->send_keys("test_accession1\ntest_accession2\ntest_accession3_synonym1\n");

sleep(1);

$d->find_element_ok("dialog_add_list_item_button", "id", "find dialog_add_list_item_button test")->click();

print "Close list content dialog...\n";

#$d->accept_alert_ok();
#sleep(1);

#$d->accept_alert_ok();
#sleep(1);

my $list_id_div = $d->find_element_ok('list_id_div', 'id', "find list_id div");

my $list_id = $list_id_div->get_text();

print STDERR "LIST ID $list_id\n";


sleep(2);

my $button = $d->find_element_ok("close_list_item_dialog", "id", "find close_list_item_dialog button test");

$button->click() if ($button);

print "Delete test list...\n";

my $delete_link = $d->find_element_ok("delete_list_new_test_list", "id", "find delete test list button");

$delete_link->click() if $delete_link;

sleep(1);

my $text = $d->driver->get_alert_text();

$d->accept_alert_ok();

sleep(1);

$d->accept_alert_ok();

print "Deleted the list\n";

$d->find_element_ok("close_list_dialog_button", "id", "find close dialog button")->click();

$d->get_ok("/list/transform/$list_id/accession_synonyms2accession_names");

$d->logout_ok();

done_testing();

$d->driver->close();

