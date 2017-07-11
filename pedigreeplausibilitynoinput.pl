use strict;
use warnings;

use Data::Dumper;
use Getopt::Std;
use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use CXGN::Chado::Stock;
use CXGN::Genotype;
use CXGN::Genotype::Search;

our ($opt_H, $opt_D, $opt_p, $opt_o); # host, database, genotyping protocol_id, out
getopts('H:D:p:o:');
print STDERR "output file is $opt_o\n";
if (!$opt_p) {
    print STDERR "Need -p with genotyping protocol id.\n";
    exit();
}

my $protocol_id = $opt_p;

my $dbh = CXGN::DB::InsertDBH->new( {
    dbhost => $opt_H,
    dbname => $opt_D,
    dbuser => "postgres",
				    }
    );

my $OUT;
my $is_stdin =0;


my $schema = Bio::Chado::Schema->connect(sub { $dbh });

my $accession_cvterm_id = $schema->resultset("Cv::Cvterm")->find({ name=> "accession" })->cvterm_id();

my $stock_rs = $schema->resultset("Stock::Stock")->search( { type_id => $accession_cvterm_id });

my @scores;

while (my $row = $stock_rs->next()) {
    print STDERR "working on accession ".$row->uniquename()."\n";
    my $stock = CXGN::Chado::Stock->new($schema, $row->stock_id());
    my @parents = $stock->get_direct_parents();

    if (@parents == 2) {

	  my $gts = CXGN::Genotype::Search->new( {
	    bcs_schema => $schema,
	    accession_list => [ $row->stock_id ],
	    protocol_id => $protocol_id,
							    });

  my @self_gts = $gts->get_genotype_info_as_genotype_objects();
	$gts = CXGN::Genotype::Search->new( {
	    bcs_schema => $schema,
	    accession_list => [ $parents[0]->[0]],
	    protocol_id => $protocol_id,
							    });
  my @mom_gts;
	@mom_gts = $gts->get_genotype_info_as_genotype_objects();
  #if (@mom_gts) { print $OUT  Dumper @mom_gts;}

	$gts = CXGN::Genotype::Search->new( {
	    bcs_schema => $schema,
	    accession_list => [ $parents[1]->[0]],
	    protocol_id => $protocol_id,
							    });
	my (@dad_gts) = $gts->get_genotype_info_as_genotype_objects();

	if (! (@self_gts)) {
	    print STDERR "Genotype of accession ".$row->uniquename()." not available. Skipping...\n";
	    next;
	}
	if (!@mom_gts) {
	    print STDERR "Genotype of female parent missing. Skipping.\n";
	    next;
	}
	if (! @dad_gts) {
	    print STDERR "Genotype of male parent missing. Skipping.\n";
	    next;
	}
  if ($opt_o) {
      open($OUT, '>>', $opt_o);
      print $OUT "file opened\n";
}
  my $s;
  my $m;
  my $d;
  $s = shift @self_gts;
  $m = shift @mom_gts;
  $d = shift @dad_gts;
  my ($concordant, $discordant, $non_informative) = $s->compare_parental_genotypes($m, $d);
  my $score = $concordant / ($concordant + $discordant);
  $score = (1 - $score);
  print STDERR "scores are". $score. "\n";
  print $OUT join "\t", map { ($_->name(), $_->id()) } ($s, $m, $d);
  print $OUT "\t$score\n";
}
}

$dbh->disconnect();

print STDERR "Done.\n";