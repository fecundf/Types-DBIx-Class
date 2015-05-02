use strict;
use warnings;

use Types::DBIx::Class ':all';

# deep_explanation's API is subject to change, as of writing this,
# test it explicitly so cpantesters can warn me if it does.

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

my $rset = $schema->resultset('Fluffles');
my $rsource = $rset->result_source;
my $row = $rset->first;

BEGIN {
  # For each type in Types::DBIx::Class, check parameterized explanations

  my %types = (Row => Row['other'],
	       Schema => Schema['other'],
	       ResultSet => ResultSet['other'],
	       ResultSource => ResultSource['other']
	      );

  sub foreach_type (&){
    my $to_run = shift;

    my @results;
    while (($_,my $type) = each %types) {
      push @results,$to_run->($type);
    }
    return @results;
  }
}

# Make sure Type::Tiny can tell our objects are paremterized, explainable
my $bad_types = join ',', foreach_type {
  my $type = shift;
  ok($type->is_parameterized, "is_parameterized $_") &&
    ok($type->parent->has_deep_explanation, "parent has_deep_explanation $_") ?
    () : $_;
};
$bad_types && BAIL_OUT "Type::Tiny won't call deep expanation for $bad_types";

sub explain_like {
  my ($obj,$msg,@expected_reasons)=@_;
  foreach_type {
    my $type = shift;
    my $explanations = $type->validate_explain($obj,'$obj');

    for my $explanation (@$explanations) {
      diag $explanation;
      #    like shift @expected_reasons, "$explanation-$type_name", $msg;
    }
  }
}

explain_like undef,'undef';

