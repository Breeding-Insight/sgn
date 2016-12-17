
package CXGN::Seedlot::Transaction;

use Moose;
use JSON::Any;

has 'schema' => ( isa => 'Bio::Chado::Schema',
		  is => 'rw',
		  required => 1,
    );

has 'transaction_id' => ( isa => 'Int',
			  is => 'rw',
			  predicate => 'has_transaction_id',
    );

has 'seedlot_id' =>  ( isa => 'Int',
		       is => 'rw',
    );

has 'source_id' => (isa => 'Int',
				is => 'rw',
    );

has 'amount' => (isa => 'Num',
			     is => 'rw',

    );

has 'operator' => ( isa => 'Maybe[Str]',
				is => 'rw',
    );

has 'date' => ( isa => 'Maybe[Str]',
		is => 'rw',
    );

has 'factor' => ( isa => 'Int',
		  is => 'rw',
		  default => 1,
    );


sub BUILD { 
    my $self = shift;
    
    if ($self->transaction_id()) { 
	my $row = $self->schema()->resultset("Stock::StockRelationship")
	    ->find( { stock_relationship_id => $self->transaction_id() } );

	$self->seedlot_id($row->subject_id());
	$self->source_id($row->object_id());
	my $data = JSON::Any->decode($row->value());
	$self->amount($data->{amount});
	$self->date($data->{date});
	$self->operator($data->{operator});
    }
}

# class method
sub get_transactions_by_seedlot_id { 
    my $class = shift;
    my $schema = shift;
    my $seedlot_id = shift;

    my $rs = $schema->resultset("Stock::StockRelationship")->search({ subject_id => $seedlot_id });

    my @transactions;
    while (my $row = $rs->next()) { 
	my $t_obj = CXGN::Seedlot::Transaction->new( schema => $schema, transaction_id => $row->stock_relationship_id() );
	
	push @transactions, $t_obj;
    }

    $rs = $schema->resultset("Stock::StockRelationship")->search({ object_id => $seedlot_id });

    while (my $row = $rs->next()) { 
	my $t_obj = CXGN::Seedlot::Transaction->new( schema => $schema, transaction_id => $row->stock_relationship_id() );
	$t_obj->factor(-1);
	push @transactions, $t_obj;
    }

    return \@transactions;
}

sub store { 
    my $self = shift;
    
    my $transaction_type_id = $self->schema()->resultset("Cv::Cvterm")->find({ name=> 'seed transaction' })->cvterm_id();

    if (!$self->has_transaction_id()) { 
	
	my $value = JSON::Any->encode( 
		    { 
			amount => $self->amount(),
			date => $self->date(),
			operator => $self->operator(),
		    });
	
	my $row = $self->schema()->resultset("Stock::StockRelationship")
	    ->find( 
	    {
		object_id => $self->source_id(),
		subject_id => $self->seedlot_id(),
		type_id => $transaction_type_id,
	    });

	my $new_rank = 0;
	if ($row) { 
	    my $old_rank = $row->rank();
	    $new_rank = $row->rank()+1;
	}
	
	$row = $self->schema()->resultset("Stock::StockRelationship")
	    ->create( 
	    { 
		object_id => $self->source_id() ,
		subject_id => $self->seedlot_id(),
		type_id => $transaction_type_id,
		rank => $new_rank,
		value => JSON::Any->encode( 
		    { 
			amount => $self->amount(),
			date => $self->date(),
			operator => $self->operator(),
		    }),
		      }) 
    }
    
    else { 
    }	
}

sub delete {
    

}

1;



