package Nagara::Schema;
use strict;
use warnings;
use utf8;
use 5.010_001;
use DBIx::Inspector;
use Nagara::Table;

use Moo;

has tables => (
    is => 'ro',
    required => 1,
);

no Moo;

sub new_from_dbh {
    my ($class, $dbh) = @_;
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my @tables;
    for my $it ($inspector->tables) {
        my $table = Nagara::Table->new(
            name => $it->name,
        );
        $table->set_primary_key(map { $_->name } $it->primary_key);
        $table->add_columns(map { $_->name } $it->columns);
        push @tables, $table;
    }
    return $class->new(tables => \@tables);
}

sub get_table {
    my ($self, $name) = @_;
    my ($table) = grep { $name eq $_->name } @{$self->tables};
    return $table;
}

1;

