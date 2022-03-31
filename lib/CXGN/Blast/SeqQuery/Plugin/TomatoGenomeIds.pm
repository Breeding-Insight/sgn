
package CXGN::Blast::SeqQuery::Plugin::TomatoGenomeIds;

use Moose;

my $logger = Log::Log4perl->get_logger();

sub name { 
    return "tomato genome identifiers";
}

sub type { 
    return 'nucleotide';
}

sub example { 
    return "Solyc01g005370
Solyc01g005590
Solyc01g016780
Solyc01g058740
Solyc01g080500";
}

sub validate { 
    my $self = shift;
    my $c = shift;
    my $input = shift;

    my @ids = split /\s+/, $input; 
    
    my $schema = $c->dbic_schema("Bio::Chado::Schema");
    my $rna_id = $schema->resultset("Cv::Cvterm")->find( { name=>'mRNA' })->cvterm_id();
    
    my @missing = ();
    foreach my $id (@ids) { 
	$logger->error("Validating $id... ");
	my $rs = $schema->resultset("Sequence::Feature")->search( { type_id=>$rna_id, name => { ilike => "$id".'.%.1' } } );
	if ($rs->count() ==0) { 
	    $logger->debug(" not found.");
	    push @missing, $id;
	}
	else { $logger->debug("OK"); }

    }
    if (@missing) { 
	return "The folloing ids entered do not exist: ".(join ",", @missing);
    }
    else { 
	return "OK";
    }
}

sub process { 
    my $self = shift;
    my $c = shift;
    my $input = shift;
    
    my @ids = split /\s+/, $input; 

    my $schema = $c->dbic_schema("Bio::Chado::Schema");
    my $rna_id = $schema->resultset("Cv::Cvterm")->find( { name=>'mRNA' })->cvterm_id();
    $logger->debug("RNA: $rna_id");
    my @seqs = ();
    foreach my $id (@ids) { 
	my $rs = $schema->resultset("Sequence::Feature")->search( { type_id=>$rna_id, name => { ilike => "$id".'.%.1' } } );
	if (my $row = $rs->next()) { 
	    
	    push @seqs, ">".$row->name."\n".$row->residues();
	}
	else { 
	    	    die "ID $id does not exist!";
	}
    }
    my $sequence =  join "\n", @seqs;
    $logger->debug("SEQUENCE = $sequence");

    return $sequence;
    
    
}

1;
    
