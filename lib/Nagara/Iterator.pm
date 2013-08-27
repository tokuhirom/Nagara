package Nagara::Iterator;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Moo;

has table => (
    is => 'ro',
    required => 1,
);

has selected_sql => (
    is => 'ro',
    required => 1,
);

has selected_binds => (
    is => 'ro',
    required => 1,
);

has sth => (
    is => 'ro',
    required => 1,
);

has db => (
    is => 'ro',
    required => 1,
);

no Moo;

sub next {
    my $self = shift;
    my $row = $self->sth->fetchrow_hashref;
    if ($row) {
        return $self->db->new_row(
            table           => $self->table,
            columns         => $row,
            selected_sql    => $self->selected_sql,
            selected_binds  => $self->selected_binds,
        );
    } else {
        undef;
    }
}

sub all {
    my $self = shift;
    my @rows;
    while (my $row = $self->next) {
        push @rows, $row;
    }
    return @rows;
}

1;

