package Introspect::ConstructorArgs;
use Moose;
use Scalar::Util qw( blessed );

extends 'Introspect::Attrs';
with 'Introspect::Common';

sub _jobname { $_[0]->classname . '&Constructors' }

my $registry;

sub for_class {
  my ( $self, $class ) = @_;
  return $self->_cache_or_construct(
    $registry => [$class] => sub {
      $self->new( classname => $class );
    }
  );
}

has constructor_arg_stash => ( is => ro =>, lazy => 1, builder => '_build_constructor_arg_stash' );

require Introspect::Attr::ConstructorArg;

sub _build_constructor_arg_stash {
  my $stash = {};
  for my $attr ( $_[0]->all_attributes ) {
    if ( defined $attr->metaattribute->init_arg ) {
      $stash->{ $attr->metaattribute->init_arg } =
        Introspect::Attr::ConstructorArg->for_constructorarg( $_[0]->classname, $attr->attrname,
        $attr->metaattribute->init_arg, );
    }
  }
  return $stash;
}

sub all                { values %{ $_[0]->constructor_arg_stash } }
sub all_accessors      { values %{ $_[0]->constructor_arg_stash } }
sub all_accessor_names { keys %{ $_[0]->constructor_arg_stash } }

sub _to_hash {
  shift;
  return { map { ( $_->constructorarg, $_->explanation ) } @_ };
}

1;
