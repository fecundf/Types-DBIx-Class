package Types::DBIx::Class;
BEGIN {
  $Types::DBIx::Class::VERSION = '0.01';
}
#ABSTRACT-Type::Library for DBIx::Class objects, from MooseX::DBIx::Class::Types

use strict;
use warnings;
use Carp;

use Type::Library -base;
use Type::Utils -all;
use Type::Params;
use Types::Standard qw(Maybe Str RegexpRef ArrayRef Ref InstanceOf);
use Sub::Quote;

# Create anonymous base types, checks
my %base =
  map { ($_ => InstanceOf["DBIx::Class::$_"]) }
  qw[ResultSet ResultSource Row Schema];

# Grep shorthand
sub _eq_array {
  my($value, $other) = @_;
  for (@$other) { return 1 if $value eq $_ }
  return 0;
}


my $check_param = Type::Params::compile(ArrayRef|Str|InstanceOf['Type::Tiny']);
my $check_param_reg = Type::Params::compile(RegexpRef|Str);

my $get_rs_s_name = sub {$_[0].'->result_source->source_name'};

my %param_types=
  (ResultSource => [$base{ResultSource},sub {$_[0].'->source_name'}],
   ResultSet => [$base{ResultSet},$get_rs_s_name],
   Row => [$base{Row},$get_rs_s_name]);

while (my ($type, $specifics) = each %param_types) {
  my ($parent, $get_name) = @$specifics;
  my $pcheck = Type::Params::compile($parent);
  declare $type,
  parent => $parent,
  deep_explanation => sub
  {
    my ($maintype, $r, $varname) = @_;
    $r //= '';
    my $source_name = $maintype->type_parameter;
    [sprintf('variable %s type %s is not a '.$type.'%s', $varname,
	     ( defined $source_name ? "[$source_name]" : '' ))
    ]
  },
  constraint_generator => sub
  {
    return $parent unless @_;
    my ($source) = eval {$check_param->(@_)};
    if ($@) {
      local $Carp::CarpInternal{'Type::Tiny'}=1;
      croak "$@ in $type parameter check called from";
    }
    my $check = $source =~ /^\w+$/ ?
      $get_name->('$_')." eq '$source'" :
   $source =~ /^[\w|]+$/ ?
      $get_name->('$_')."=~ /^(?:$source)\$/" :
      "_eq_array(".$get_name->('$_').", \$source)";

    return Sub::Quote::quote_sub
      "\$pcheck->(\$_) && $check",
      { '$pcheck' => \$pcheck, '$source' => \$source } };
}


# This one was different enough to pull out of the loop
my $pcheck = Type::Params::compile($base{Schema});
declare 'Schema',
  parent => $base{Schema},
  deep_explanation => sub
  {
    my ($maintype, $s, $varname) = @_;
    $s //= '';
    my $pattern = $maintype->type_parameter;
    [sprintf('variable %s type %s is not a Schema%s', $varname,
	     qq('$s'), $pattern ? qq([$pattern]) : '')
    ]
  },
  constraint_generator => sub
  {
    return $base{Schema} unless @_;
    my ($pattern) = eval {$check_param_reg->(@_)};
    if ($@) {
      local $Carp::CarpInternal{'Type::Tiny'}=1;
      croak "$@ in Schema parameter check called from";
    }
    return Sub::Quote::quote_sub
      "\$pcheck->(\$_) &&(!\$pattern || ref(\$_) =~ \$pattern)",
      { '$pattern' => \$pattern, '$pcheck' => \$pcheck }
  };

__PACKAGE__->meta->make_immutable;
1;


__END__
