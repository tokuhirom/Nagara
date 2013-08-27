use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'DBD::SQLite';
use Nagara;

subtest 'simple' => sub {
    my $db = new_db();
    $db->resultset('user')->create({
        name => 'nekokak'
    });
    is($db->resultset('user')->count(), 1);

    {
        my @rows = $db->resultset('user')->select();
        is 0+@rows, 1;
        is($rows[0]->name, 'nekokak');
    }
};

subtest 'update' => sub {
    my $db = new_db();
    $db->resultset('user')->create({
        name => 'nekokak'
    });
    my @rows = $db->resultset('user')->select();
    is 0+@rows, 1;
    my $row = $rows[0];
    $row->update({ name => 'inukak' });
    is $row->refetch()->name, 'inukak';
};

subtest 'resultset->update' => sub {
    my $db = new_db();
    require DBIx::QueryLog; my $guard = DBIx::QueryLog->guard();
    $db->resultset('user')->create({
        id => 1,
        name => 'nekokak'
    });
    $db->resultset('user')->create({
        id => 2,
        name => 'mikihoshi'
    });
    $db->resultset('user')->where({id => 2})->update({ name => 'kan' });
    my @rows = $db->resultset('user')->select({order_by => 'id'});
    is 0+@rows, 2;
    is $rows[0]->name, 'nekokak';
    is $rows[1]->name, 'kan';
};

done_testing;

sub new_db {
    my $db = Nagara->new(
        connect_info => [
            'dbi:SQLite:dbname=:memory:',
            '',
            '',
            {RaiseError => 1},
        ],
    );
    $db->dbh->do(q{
        CREATE TABLE user (
            id     INTEGER NOT NULL PRIMARY KEY,
            name   VARCHAR(256) NOT NULL
        )
    });
    $db;
}
