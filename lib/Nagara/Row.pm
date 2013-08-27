package Nagara::Row;
use strict;
use warnings;
use utf8;
use 5.010_001;
use Carp ();

use Moo;

has table => (
    is => 'ro',
    required => 1,
    isa => sub {
      Carp::confess("$_[0] is not a table object!") unless UNIVERSAL::isa($_[0], 'Nagara::Table');
    }
);

has db => (
    is => 'ro',
    required => 1,
);

has selected_sql => (
    is => 'ro',
);

has selected_binds => (
    is => 'ro',
);

has columns => (
    is => 'ro',
    default => sub { +{ } },
);

has dirty_columns => (
    is => 'ro',
    default => sub { +{ } },
);

no Moo;


our $AUTOLOAD;
sub DESTROY { }

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*:://;
    my $pkg = ref $self || $self;
    my $column = "$AUTOLOAD";
    no strict 'refs';
    *{"${pkg}::${column}"} = sub {
        if (@_==1) {
            shift->get_column($column);
        } else {
            shift->set_column($column, @_);
        }
    };
    $self->$column(@_);
}

sub get_column {
    my ($self, $key) = @_;
    $self->columns->{$key};
}
sub set_column {
    my ($self, $key, $value) = @_;
    $self->columns->{$key} = $value;
}

sub where {
    my $self = shift;
    my $pk = $self->table->primary_columns;
    @$pk > 0 or die "Missing pk in " . $self->table->name;
    my %cond;
    for my $k (@$pk) {
        if (exists $self->columns->{$k}) {
            $cond{$k} = $self->columns->{$k};
        } else {
            Carp::croak("You don't selected column: $k");
        }
    }
    return \%cond;
}

sub delete {
    my $self = shift;
    my ($sql, @binds) = $self->db->sql_maker->delete($self->table->name, $self->where);
    $self->db->dbh->do($sql, {}, @binds);
}

sub refetch {
    my $self = shift;
    my ($sql, @binds) = $self->db->sql_maker->select($self->table->name, ['*'], $self->where);
    my $sth = $self->db->dbh->prepare($sql);
    $sth->execute(@binds);
    my $columns = $sth->fetchrow_hashref();
    ( ref $self )->new(
        columns        => $columns,
        db             => $self->db,
        table          => $self->table,
        selected_sql   => $sql,
        selected_binds => \@binds,
    );
}

sub update {
    my ($self, $values) = @_;
    my ($sql, @binds) = $self->db->sql_maker->update($self->table->name, $values, $self->where);
    $self->db->dbh->do($sql, {}, @binds);
}

sub insert {
    my $self = shift;
    unless (%{$self->columns}) {
        Carp::croak("No data was set on this row: " . $self->table->name);
    }
    my ($sql, @binds) = $self->db->sql_maker->insert($self->table->name, $self->columns);
    $self->db->dbh->do($sql, {}, @binds);
}
sub create { shift->insert(@_) }

1;

