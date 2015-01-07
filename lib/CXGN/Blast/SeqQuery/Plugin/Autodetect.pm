
package CXGN::Blast::SeqQuery::Plugin::Autodetect;

use Moose;


sub name { 
    return 'autodetect';
}

sub type { 
    return 'autodetect';
}

sub example { 
    return "  1 aattcggcac cagtaaattt tcccaaaggt ttcaaaaatg aaaattttga ttttcctaat
       61 aatgtttctt gctatgttgc tagtaacaag tgggaataat aatctagtag agacaacatg
      121 caagaacaca ccaaattata atttgtgtgt gaaaactttg tctttagaca";
}

sub validate { 
	return "OK";
}

sub process { 
    my $self = shift;
    my $c = shift;
    my $sequence = shift;
	
    $sequence =~ s/^[\s\n]+//;
    my $final_seq;
	
	if ($sequence =~ />/) {
	    my @final_sequence;
		my @lines = split("\n",$sequence);
		
		foreach my $line (@lines) {
			if ($line !~ />/) {
				$line=~ s/[\s\d\.\-\_\:\;\(\)\[\]\=\#\,\*]+//g;
				push(@final_sequence, $line);
			} else {
				push(@final_sequence, $line);
			}
		}
		$final_seq = join("\n",@final_sequence);
	} elsif ($sequence =~ m/Solyc\d+g\d+/i) {
	    my @ids = split /\s+/, $sequence; 

	    my $schema = $c->dbic_schema("Bio::Chado::Schema");
	    my $rna_id = $schema->resultset("Cv::Cvterm")->find( { name=>'mRNA' })->cvterm_id();

	    my @seqs = ();
	    foreach my $id (@ids) {
		$id =~ s/\.\d+$//;
		$id =~ s/\.\d+$//;

		my $rs = $schema->resultset("Sequence::Feature")->search( { type_id=>$rna_id, name => { ilike => "$id".'.%.1' } } );
		if (my $row = $rs->next()) { 
		    push @seqs, ">".$row->name."\n".$row->residues();
		}
	    }
	    $final_seq =  join "\n", @seqs;
	} elsif ($sequence =~ m/SGN-U\d+/i) {
	    my @ids = split /\s+/, $sequence; 
	    my $dbh = $c->dbc->dbh();
	    my $query = "SELECT unigene_id, unigene_consensi.seq FROM sgn.unigene JOIN sgn.unigene_consensi using(consensi_id) WHERE unigene_id=?";
	    my $h = $dbh->prepare($query);
    
	    my @seqs = ();
	    foreach my $id (@ids) { 
		my $numeric_id = $id;
		$numeric_id=~s/\D//g;
		$h->execute($numeric_id);
		if (my ($unigene_id, $seq) = $h->fetchrow_array()) { 
		    push @seqs, ">".$id."\n".$seq;
		}
	    }
	    $final_seq = join "\n", @seqs;
	}  else {
		$sequence=~ s/[\s\d\.\-\_\:\;\(\)\[\]\=\#\,\*]+//g;
		$final_seq = ">Untitled_sequence\n$sequence\n";
	}
	
	# print STDERR "accessing the autodetect process function\n";
    print STDERR "FINAL SEQ: $final_seq\n";
    return $final_seq;
}

sub autodetect_seq_type {
    my $self = shift;
    my $c = shift;
    my $sequence = shift;
	
	my $seq_type = 'nucleotide';
	my $valid_nt = 0;
	my $seq_header = '';
	
	if ($sequence =~ />/) {
		my @lines = split("\n",$sequence);
		if ($lines[0] =~ />/) {
			$seq_header = shift(@lines);
			$sequence = join "\n", @lines;
		}
		
		foreach my $line (@lines) {
			if ($line !~ />/) {
				$valid_nt += $sequence=~ tr/acgtACGTNn /acgtACGTNn /;
			}
		}
	} else {
		$valid_nt += $sequence=~ tr/acgtACGTNn /acgtACGTNn /;
	}
	
	if ($valid_nt >= length($sequence)*0.9) {
		$seq_type = 'nucleotide';
	} else {
		$seq_type = 'protein';
	}
	
	print STDERR "accessing the autodetect_seq_type function. header: $seq_header, seq_type: $seq_type, valid:  $valid_nt, length: ".length($sequence)."\n";
	
	return $seq_type;
}

1;
