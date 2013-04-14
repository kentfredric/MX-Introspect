package Introspect::Attrs;
use Moose;

with 'Introspect::Common';
my $registry;

has classname => ( is => ro =>, required => 1 );
has metaclass => ( is => ro =>, lazy => 1, builder => '_get_metaclass' );

sub _jobname {
  $_[0]->classname . '&Attrs';
}

sub for_class {
  my ( $self, $class ) = @_;
  return $self->_cache_or_construct(
    $registry,
    [$class],
    sub {
      $self->new( classname => $class );
    }
  );
}

sub _get_metaclass { return $_[0]->_cc_get_metaclass( $_[0]->classname ) }

sub inflate_attr {
  require Introspect::Attr;
  return Introspect::Attr->for_attribute( $_[0]->classname, $_[1] );
}

has stash => ( is => ro =>, lazy => 1, builder => '_build_stash' );

sub all                 { values %{ $_[0]->stash } }
sub all_attributes      { values %{ $_[0]->stash } }
sub all_attribute_names { keys %{ $_[0]->stash } }

sub _get_all_attribute_names {
  return map { $_->name } $_[0]->metaclass->get_all_attributes()
    if $_[0]->metaclass->can('get_all_attributes');
  return $_[0]->metaclass->get_attribute_list()
    if $_[0]->metaclass->can('get_attribute_list');
}

sub _build_stash {
  return { map { ( $_, $_[0]->inflate_attr($_) ) } $_[0]->_get_all_attribute_names };
}

sub own_public {
  grep { $_->is_public and $_->is_own } $_[0]->all;
}

sub own_private {
  grep { $_->is_private and $_->is_own } $_[0]->all;
}

sub inherited_public {
  grep { $_->is_public and $_->is_inherited } $_[0]->all;
}

sub inherited_private {
  grep { $_->is_private and $_->is_inherited } $_[0]->all;
}

sub _to_hash {
  shift;
  return { map { ( $_->attrname, $_->explanation ) } @_ };
}

sub own_public_hash        { $_[0]->_to_hash( $_[0]->own_public ) }
sub own_private_hash       { $_[0]->_to_hash( $_[0]->own_private ) }
sub inherited_public_hash  { $_[0]->_to_hash( $_[0]->inherited_public ) }
sub inherited_private_hash { $_[0]->_to_hash( $_[0]->inherited_private ) }

sub as_hash {
  my $self = shift;
  my $hash = {};
  for my $key (qw( own_public own_private inherited_public inherited_private )) {
    my $method = "${key}_hash";
    my $result = $self->$method();
    my ( $tier_1, $tier_2 ) = split /_/, $key;
    if ( keys %{$result} ) {
      $hash->{$tier_1}->{$tier_2} = $result;
    }
  }
  return $hash;
}

1;
