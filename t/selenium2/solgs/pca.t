
use strict;

use lib 't/lib';

use Test::More;
use SGN::Test::WWW::WebDriver;

my $d = SGN::Test::WWW::WebDriver->new();

`rm -r /tmp/localhost/`;

$d->while_logged_in_as("submitter", sub {

    $d->get_ok('/pca/analysis', 'pca home page');     
    sleep(10);
    $d->find_element_ok('//select[@id="pca_pops_list_select"]/option[text()="34 clones"]', 'xpath', 'select clones list')->click();
    sleep(10);
    $d->find_element_ok('//input[@value="Go"]', 'xpath', 'go btn')->click();
    sleep(5);   
    $d->find_element_ok('pca_data_type_select', 'id', 'select data type')->send_keys('Genotype');
    sleep(2);
    $d->find_element_ok('Run PCA', 'partial_link_text', 'run pca')->click();
    sleep(20);
    $d->find_element_ok('//*[contains(text(), "PC1")]', 'xpath', 'check geno  pca plot')->click();
    sleep(5);

    $d->get_ok('/pca/analysis', 'pca home page');     
    sleep(10);
    $d->find_element_ok('//select[@id="pca_pops_list_select"]/option[text()="60 plot naccri"]', 'xpath', 'plots list')->click();
    sleep(10);
    $d->find_element_ok('//input[@value="Go"]', 'xpath', 'go btn')->click();
    sleep(5);   
    $d->find_element_ok('pca_data_type_select', 'id', 'select data type')->send_keys('Phenotype');
    sleep(2);
    $d->find_element_ok('Run PCA', 'partial_link_text', 'run pca')->click();
    sleep(20);
    $d->find_element_ok('//*[contains(text(), "PC1")]', 'xpath', 'check pheno pca plot')->click();
    sleep(5);

    $d->get_ok('/pca/analysis', 'pca home page');     
    sleep(20);
    $d->find_element_ok('//select[@id="pca_pops_list_select"]/option[text()="Trials list"]', 'xpath', 'select clones list')->click();
    sleep(10);
    $d->find_element_ok('//input[@value="Go"]', 'xpath', 'go btn')->click();
    sleep(5);   
    $d->find_element_ok('pca_data_type_select', 'id', 'select data type')->send_keys('Genotype');
    sleep(2);
    $d->find_element_ok('Run PCA', 'partial_link_text', 'run pca')->click();
    sleep(60);
    $d->find_element_ok('//*[contains(text(), "PC1")]', 'xpath', 'check geno  pca plot')->click();
    sleep(5);

    $d->get_ok('/pca/analysis', 'pca home page');     
    sleep(20);
    $d->find_element_ok('//select[@id="pca_pops_list_select"]/option[text()="Trials list"]', 'xpath', 'plots list')->click();
    sleep(10);
    $d->find_element_ok('//input[@value="Go"]', 'xpath', 'go btn')->click();
    sleep(5);   
    $d->find_element_ok('pca_data_type_select', 'id', 'select data type')->send_keys('Phenotype');
    sleep(2);
    $d->find_element_ok('Run PCA', 'partial_link_text', 'run pca')->click();
    sleep(60);
    $d->find_element_ok('//*[contains(text(), "PC1")]', 'xpath', 'check pheno pca plot')->click();
    sleep(5);


    $d->get_ok('/pca/analysis', 'pca home page');     
    sleep(5);
    $d->find_element_ok('//select[@id="pca_pops_list_select"]/option[text()="two trials dataset"]', 'xpath', 'trials dataset')->click();
    sleep(5);
    $d->find_element_ok('//input[@value="Go"]', 'xpath', 'go btn')->click();
    sleep(20);   
    $d->find_element_ok('pca_data_type_select', 'id', 'select data type')->send_keys('Genotype');
    sleep(3);
    $d->find_element_ok('Run PCA', 'partial_link_text', 'run pca')->click();
    sleep(60);
    $d->find_element_ok('//*[contains(text(), "PC1")]', 'xpath', 'check pheno pca plot')->click();
    sleep(5);


    $d->get_ok('/pca/analysis', 'pca home page');     
    sleep(5);
    $d->find_element_ok('//select[@id="pca_pops_list_select"]/option[text()="two trials dataset"]', 'xpath', 'trials dataset')->click();
    sleep(5);
    $d->find_element_ok('//input[@value="Go"]', 'xpath', 'go btn')->click();
    sleep(20);   
    $d->find_element_ok('pca_data_type_select', 'id', 'select data type')->send_keys('Phenotype');
    sleep(3);
    $d->find_element_ok('Run PCA', 'partial_link_text', 'run pca')->click();
    sleep(60);
    $d->find_element_ok('//*[contains(text(), "PC1")]', 'xpath', 'check pheno pca plot')->click();
    sleep(5);


    $d->get_ok('/breeders/trial/139', 'trial detail home page');     
    sleep(10);
    my $analysis_tools = $d->find_element('Analysis Tools', 'partial_link_text', 'toogle analysis tools');
    my $elem = $d->driver->execute_script( "arguments[0].scrollIntoView(true);window.scrollBy(0,-100);", $analysis_tools);
    sleep(5);    
    $d->find_element_ok('Analysis Tools', 'partial_link_text', 'toogle analysis tools')->click();
    sleep(5);
    $d->find_element_ok('pca_data_type_select', 'id', 'select data type')->send_keys('Phenotype');
    sleep(2);
    $d->find_element_ok('run_pca', 'id', 'run PCA')->click();
    sleep(60);
    $d->find_element_ok('//*[contains(text(), "PC1")]', 'xpath', 'check pheno pca plot')->click();
    sleep(5);

    my $analysis_tools = $d->find_element('Analysis Tools', 'partial_link_text', 'toogle analysis tools');
    my $elem = $d->driver->execute_script( "arguments[0].scrollIntoView(true);window.scrollBy(0,-100);", $analysis_tools);
    sleep(5);    
    $d->find_element_ok('Analysis Tools', 'partial_link_text', 'toogle analysis tools')->click();
    sleep(5);
    $d->find_element_ok('pca_data_type_select', 'id', 'select data type')->send_keys('Genotype');
    sleep(2);
    $d->find_element_ok('run_pca', 'id', 'run PCA')->click();
    sleep(60);
    $d->find_element_ok('//*[contains(text(), "PC1")]', 'xpath', 'check pheno pca plot')->click();
    sleep(5);
   

});


done_testing();
