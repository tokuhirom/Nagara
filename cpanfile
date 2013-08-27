requires 'perl', '5.008001';
requires 'DBI';
requires 'DBIx::Inspector';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
    suggests 'DBD::SQLite';
};

