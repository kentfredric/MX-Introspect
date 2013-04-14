#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use lib '/home/kent/perl/Introspect/lib';
use Introspect;

use Data::Dump qw( pp );

my (@classes) = (
    'Introspect',
    'Introspect::ConstructorArgs',
    'Introspect::Attr',
    'Introspect::Attr::Accessor',
    'Introspect::Attr::ConstructorArg',
    'Introspect::Common',
    'Introspect::Accessors',
    'Introspect::Attr',
    'Introspect::Attrs',
);

my $classx = {};

for my $class (@classes) {
  if ( not exists $classx->{$class} ) {
    $classx->{$class} = 0;
  }
}

sub _has_todo {
  grep { exists $classx->{$_} and $classx->{$_} == 0 } keys $classx;
}

sub _add_todo {
  local $_ = $_[0];
  return if exists $classx->{$_};
  return if $_ eq 'Moo::Object';
  $classx->{$_} = 0;
}

while ( my @todo = _has_todo ) {
  for my $class (@todo) {
    for my $inherit ( @{ Introspect->for_class($class)->inherits } ) {
      _add_todo($inherit);
    }
    for my $compose ( @{ Introspect->for_class($class)->composes } ) {
      _add_todo($compose);
    }

    #    print pp( Introspect->for_class($class)->as_hash );
    $classx->{$class} = Introspect->for_class($class)->as_hash;
  }
}

print pp($classx);
__END__

my $instance = Introspect->for_class('Dist::Zilla::Plugin::Git::Remote::Update');

pp( $instance->accessors->as_hash );

