package Types::DBIx::Class;
BEGIN {
  $Types::DBIx::Class::VERSION = '0.01';
}
#ABSTRACT-Type::Library for DBIx::Class objects, from MooseX::DBIx::Class::Types

use strict;
use warnings;
use Carp;

use Type::Library -base,
  -declare => qw(
    BaseResultSet
    BaseResultSource
    BaseRow
    BaseSchema
);
use Type::Utils -all;
use Type::Params;
use Types::Standard qw(Maybe Str RegexpRef ArrayRef Ref InstanceOf);
use Sub::Quote ();

class_type BaseResultSet, { class => 'DBIx::Class::ResultSet' };

class_type BaseResultSource, { class => 'DBIx::Class::ResultSource' };

class_type BaseRow, { class => 'DBIx::Class::Row' };

class_type BaseSchema, { class => 'DBIx::Class::Schema' };

# Grep shorthand
sub _eq_array {
  my($value, $other) = @_;
  for (@$other) { return 1 if $value eq $_ }
  return 0;
}


my $check_param = Type::Params::compile(ArrayRef|Str|InstanceOf['Type::Tiny']);
my $check_param_reg = Type::Params::compile(RegexpRef|Str);

my %param_types=(ResultSet => BaseResultSet,
		 Row => BaseRow);

while (my ($type, $parent) = each %param_types) {
  declare $type,
  parent => $parent,
  deep_explanation => sub
  {
    my ($maintype, $r, $varname) = @_;
    $r = $_[0] // '';
    my $source_name = $maintype->type_parameter;
    [sprintf('variable %s type %s is not a '.$type.'%s', $varname,
	     ( $maintype->check($r) ? $type.'[' . $r->result_source->source_name . ']' : qq('$r') ),
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
      "\$_->result_source->source_name eq '$source'" :
   $source =~ /^[\w|]+$/ ?
      "\$_->result_source->source_name =~ /^(?:$source)\$/" :
      "_eq_array(\$_->result_source->source_name, \$source)";

    return Sub::Quote::quote_sub("is_Base$type(\$_) && $check",
				 {'$source' => \$source});
  };
}

declare 'ResultSource',
  parent => BaseResultSource,
  deep_explanation => sub
  {
    my ($maintype, $r, $varname) = @_;
    $r = $_[0] // '';
    my $source_name = $maintype->type_parameter;
    [sprintf('variable %s type %s is not a ResultSource%s', $varname,
            ( is_BaseResultSource($r) ? 'ResultSource[' . $r->source_name . ']' : qq('$r') ),
            ( defined $source_name ? "[$source_name]" : '' ))
    ]
  },
  constraint_generator => sub
  {
    return BaseResultSource unless @_;
    my ($source) = eval {$check_param->(@_)};
    if ($@) {
      local $Carp::CarpInternal{'Type::Tiny'}=1;
      croak "$@ in ResultSource parameter check called from";
    }
    my $check = $source =~ /^\w+$/ ?
      "\$_->source_name eq '$source'" :
   $source =~ /^[\w|]+$/ ?
      "\$_->source_name =~ /^(?:$source)\$/" :
      "_eq_array(\$_->source_name, \$source)";

    return Sub::Quote::quote_sub
      "is_BaseResultSource(\$_[0]) && $check"
  };


declare 'Schema',
  parent => BaseSchema,
  deep_explanation => sub
  {
    my ($maintype, $s, $varname) = @_;
    $s = $_[0] // '';
    my $pattern = $maintype->type_parameter;
    [sprintf('variable %s type %s is not a Schema%s', $varname,
	     qq('$s'), $pattern ? qq([$pattern]) : '')
    ]
  },
  constraint_generator => sub
  {
    return BaseSchema unless @_;
    my ($pattern) = eval {$check_param_reg->(@_)};
    if ($@) {
      local $Carp::CarpInternal{'Type::Tiny'}=1;
      croak "$@ in Schema parameter check called from";
    }
    return Sub::Quote::quote_sub
      "is_BaseSchema(\$_[0]) &&(!\$pattern || ref(\$_[0]) =~ \$pattern)",
      { '$pattern' => \$pattern }
  };

__PACKAGE__->meta->make_immutable;
1;


__END__
