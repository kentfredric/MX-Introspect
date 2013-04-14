use strict;
use warnings;

package Introspect;

use Moose;
with 'Introspect::Common';
use Path::Tiny qw( path );

my $registry;

has classname => ( is => ro =>, required => 1 );
has metaclass => ( is => ro =>, lazy     => 1, builder => '_get_metaclass' );
has inherits  => ( is => ro =>, lazy     => 1, builder => '_scrape_inherits' );
has composes  => ( is => ro =>, lazy     => 1, builder => '_scrape_composes' );

has attributes      => ( is => ro =>, lazy => 1, builder => '_build_attributes' );
has accessors       => ( is => ro =>, lazy => 1, builder => '_build_accessors' );
has constructorargs => ( is => ro =>, lazy => 1, builder => '_build_constructorargs' );

has all_methods  => ( is => ro =>, lazy => 1, builder => '_scrape_all_methods' );
has all_requires => ( is => ro =>, lazy => 1, builder => '_scrape_all_requires' );

has 'methods_public'   => ( is => ro =>, lazy => 1, builder => '_scrape_methods_public' );
has 'methods_private'  => ( is => ro =>, lazy => 1, builder => '_scrape_methods_private' );
has 'requires_public'  => ( is => ro =>, lazy => 1, builder => '_scrape_requires_public' );
has 'requires_private' => ( is => ro =>, lazy => 1, builder => '_scrape_requires_private' );

sub for_class {
  my ( $self, $class ) = @_;
  return $self->_cache_or_construct(
    $registry => [$class] => sub {
      $self->new( classname => $class );
    }
  );
}

sub _jobname {
  $_[0]->classname;
}

sub _build_attributes {
  require Introspect::Attrs;
  return Introspect::Attrs->for_class( $_[0]->classname );
}

sub _build_accessors {
  require Introspect::Accessors;
  return Introspect::Accessors->for_class( $_[0]->classname );
}

sub _build_constructorargs {
  require Introspect::ConstructorArgs;
  return Introspect::ConstructorArgs->for_class( $_[0]->classname );
}

sub _get_metaclass { return $_[0]->_cc_get_metaclass( $_[0]->classname ) }

sub _scrape_inherits {
  if ( $_[0]->metaclass->can('superclasses') ) {
    return [ $_[0]->metaclass->superclasses() ];
  }
  return [];
}

sub _scrape_composes {
  my $classes = {};
  if ( $_[0]->metaclass->can('calculate_all_roles_with_inheritance') ) {
    $classes->{ $_->name } = 1 for $_[0]->metaclass->calculate_all_roles_with_inheritance();

  }
  if ( $_[0]->metaclass->can('get_roles') ) {
    $classes->{ $_->name } = 1 for @{ $_[0]->metaclass->get_roles() };
  }
  return [ sort keys %{$classes} ];
}

sub _scrape_all_methods {
  if ( $_[0]->metaclass->can('get_all_methods') ) {
    return [ map { $_->name } $_[0]->metaclass->get_all_methods() ];
  }
  if ( $_[0]->metaclass->can('get_attribute_list') ) {
    return [ $_[0]->metaclass->get_attribute_list() ];
  }
}

sub _scrape_all_requires {
  if ( $_[0]->metaclass->can('get_required_method_list') ) {
    return [ map { $_->name } $_[0]->metaclass->get_required_method_list() ];
  }
  return [];
}

sub _scrape_methods_public {
  return [ sort grep { $_ !~ /^_/ } @{ $_[0]->all_methods } ];
}

sub _scrape_methods_private {
  return [ sort grep { $_ =~ /^_/ } @{ $_[0]->all_methods } ];
}

sub _scrape_requires_public {
  return [ grep { $_ !~ /^_/ } @{ $_[0]->all_requires } ];
}

sub _scrape_requires_private {
  return [ grep { $_ =~ /^_/ } @{ $_[0]->all_requires } ];
}

sub requires_as_hash {
  my $self = $_[0];
  my $hash = {};
  my $req;
  if ( @{ $req = $self->requires_public } ) {
    $hash->{own}->{public} = $req;
  }
  if ( @{ $req = $self->requires_private } ) {
    $hash->{own}->{private} = $req;
  }

  $hash;
}

sub methods_as_hash {
  my $self = $_[0];
  my $hash = {};
  my $meth;
  if ( @{ $meth = $self->methods_public } ) {
    $hash->{own}->{public} = $meth;
  }
  if ( @{ $meth = $self->methods_private } ) {
    $hash->{own}->{private} = $meth;
  }

  $hash;
}

sub attributes_as_hash {
  my $self = $_[0];
  return $self->attributes->as_hash;
}

sub accessors_as_hash {
  my $self = $_[0];
  return $self->accessors->as_hash;
}

sub constructorargs_as_hash {
  my $self = $_[0];
  return $self->constructorargs->as_hash;
}

sub as_hash {
  my $self = $_[0];
  my $stash;
  for my $key (
    qw( constructorargs_as_hash inherits classname composes attributes_as_hash methods_as_hash accessors_as_hash requires_as_hash )
    )
  {
    $stash->{$key} = $self->$key();
    if ( ref $stash->{$key} eq 'ARRAY' and not @{ $stash->{$key} } ) {
      delete $stash->{$key};
    }
    if ( ref $stash->{$key} eq 'HASH' and not keys %{ $stash->{$key} } ) {
      delete $stash->{$key};
    }
  }
  return $stash;
}

1;
