package Nagara::ResultSet;
use strict;
use warnings;
use utf8;
use 5.010_001;
use Nagara::Iterator;

use Moo;

has table => (
    is => 'ro',
    required => 1,
);

has db => (
    is => 'ro',
);

has condition => (
    is => 'lazy',
);

no Moo;

sub _build_condition {
    my $self = shift;
    $self->db->sql_maker->new_condition();
}

sub where {
    my ($self, $cond) = @_;
    while (my ($k, $v) = each %$cond) {
        $self->condition->add($k, $v);
    }
    wantarray ? $self->all : $self;
}

sub select:method {
    my ($self, $option) = @_;
    my $cols = delete($option->{cols}) || ['*'];

    my ($sql, @binds) = $self->db->sql_maker->select(
        $self->table,
        $cols,
        $self->condition,
        $option,
    );
    my $sth = $self->db->dbh->prepare($sql);
    $sth->execute(@binds);
    my $iter = Nagara::Iterator->new(
        db             => $self->db,
        sth            => $sth,
        table          => $self->table,
        selected_sql   => $sql,
        selected_binds => \@binds,
    );
    wantarray ? $iter->all : $iter;
}

sub insert {
    my ($self, $values) = @_;
    unless (%$values) {
        Carp::croak("No values: " . $self->table);
    }
    my $row = $self->db->new_row(
        table => $self->table,
        columns => $values,
    );
    $row->insert();
    $row;
}
sub create { shift->insert(@_) }

sub delete {
    my $self = shift;

    my $iter = $self->select;
    while (my $row = $iter->next) {
        $row->delete();
    }
}

sub update {
    my ($self, $set) = @_;

    my $iter = $self->select;
    while (my $row = $iter->next) {
        $row->update($set);
    }
}

sub count {
    my $self = shift;
    my ($sql, @binds) = $self->db->sql_maker->select($self->table, [\'COUNT(*)'], $self->condition);
    my $sth = $self->db->dbh->prepare($sql);
    $sth->execute(@binds);
    my $cnt = $sth->fetchrow_array();
    return $cnt;
}

1;

