use strict;
use warnings;
use Test::More;
# Use "+ResultSet" to get both ResultSet type and is_ResultSet predicate
# or simply spell out exactly what you need. Both methods below.
use Types::DBIx::Class qw(
    +ResultSet
    +ResultSource
    Row is_Row
    Schema is_Schema
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

ok(is_Schema($schema),'is_Schema');
ok(is_ResultSet(my $rset = $schema->resultset('Fluffles')),'is_ResultSet');
ok(is_ResultSource(my $rsource = $schema->resultset('Fluffles')->result_source),'is_ResultSource');
ok(is_Row(my $row = $schema->resultset('Fluffles')->first),'is_Row');

ok(!is_Schema($rset),'!is_Schema');
ok(!is_ResultSet($schema),'!is_ResultSet');
ok(!is_ResultSource($row),'!is_ResultSource');
ok(!is_Row($rsource),'!is_Row');

ok((Row['Fluffles'])->check($row),'Row Fluffles');
ok((ResultSet['Fluffles'])->check($rset),'ResultSet Fluffles');
ok((ResultSource['Fluffles'])->check($rsource),'ResultSource Fluffles');
ok((Schema[qr/Test/])->check($schema),'Schema Test');

ok(!(Schema['other'])->check($schema),'!Schema other');
ok(!(Row['other'])->check($row),'!Row other');
ok(!(ResultSet['other'])->check($rset),'!ResultSet other');
ok(!(ResultSource['other'])->check($rsource),'!ResultSource other');

done_testing;
