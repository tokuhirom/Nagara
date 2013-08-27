package Nagara::Table;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Moo;

has name => ( is => 'ro' );

has columns => (
    is => 'ro',
    default => sub { +[ ] },
);

has primary_columns => (
    is => 'ro',
    default => sub { +[ ] },
);

no Moo;

sub add_columns {
    my $self = shift;
    push $self->{columns}, @_;
}

sub has_column {
    my ($self, $name) = @_;
    (grep { $_ eq $name } @{$self->columns}) > 0;
}

sub set_primary_key {
    my $self = shift;
    push $self->{primary_columns}, @_;
}

1;

