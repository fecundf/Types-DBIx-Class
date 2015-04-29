use strict;
use warnings;
use Test::More;
# Use "+ResultSet" to get both ResultSet type and is_ResultSet predicate
# or simply spell out exactly what you need. Both methods below.
use Types::DBIx::Class qw(
    +ResultSet
    +ResultSource
    is_Row
    is_Schema
);

# Sample DBIx::Class schema to test against
{
    package Test::Schema::Fluffles;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('fluffles');
    __PACKAGE__->add_columns(qw( fluff_factor ));
}

{
    package Test::Schema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->load_classes(qw(
        Fluffles
    ));
}

my $schema = Test::Schema->connect('dbi:SQLite::memory:');
$schema->deploy;
$schema->resultset('Fluffles')->create({ fluff_factor => 9001 });

ok(is_Schema($schema));
ok(is_ResultSet($schema->resultset('Fluffles')));
ok(is_ResultSource($schema->resultset('Fluffles')->result_source));
ok(is_Row($schema->resultset('Fluffles')->first));

done_testing;
