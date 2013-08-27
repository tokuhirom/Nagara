package Nagara;
use 5.010000;
use strict;
use warnings;

our $VERSION = "0.01";

use DBIx::Handler;
use SQL::Maker;
use String::CamelCase qw(camelize);
use Class::Load qw(try_load_class);

use Nagara::Row;
use Nagara::Schema;
use Nagara::ResultSet;

use Moo;

has connect_info => (
    is => 'rw',
    required => 1,
);

has handler => (
    is => 'lazy',
    handles => [qw(dbh txn_scope)],
);

has sql_maker => (
    is => 'lazy',
);

has schema => (
    is => 'lazy',
);

no Moo;

# You can override this attribute
sub resultset_class { 'Nagara::ResultSet' }
sub namespace { ref $_[0] || $_[0] }

sub _build_handler {
    my $self = shift;
    my @info = @{$self->connect_info};
    $info[3]->{RaiseError}++;
    DBIx::Handler->new(@info);
}

sub _build_schema {
    my $self = shift;
    Nagara::Schema->new_from_dbh($self->dbh);
}

sub _build_sql_maker {
    my $self = shift;
    SQL::Maker->new(driver => $self->dbh->{Driver});
}

sub resultset {
    my ($self, $table) = @_;
    $self->resultset_class->new(table => $table, db => $self);
}

# You can override this method for customizing resolution method.
sub get_row_class_name {
    my ($self, $table) = @_;
    state %cache;
    my $ns = $self->namespace;
    my $key = "$ns.$table";
    unless (exists $cache{$key}) {
        my $pkg = $ns . '::' . camelize($table);
        unless (try_load_class($pkg)) {
            no strict 'refs';
            unshift @{"${pkg}::ISA"}, 'Nagara::Row';
        }
        $cache{$key} = $pkg;
    }
    return $cache{$key};
}

sub new_row {
    my ($self, %args) = @_;
    my $table_name = delete($args{table}) // Carp::croak "Missing mandatory paramter: table";
    my $row_class = $self->get_row_class_name($table_name);
    my $table = $self->schema->get_table($table_name);
    $row_class->new(
        %args,
        table => $table,
        db    => $self,
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Nagara - Yet another yurufuwa O/R Mapper

=head1 SYNOPSIS

    use Nagara;

=head1 DESCRIPTION

Nagara is yurufuwa O/R Mapper.

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

