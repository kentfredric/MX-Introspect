package Introspect::Accessors;
use Moose;
use Scalar::Util qw( blessed );

extends 'Introspect::Attrs';
with 'Introspect::Common';

sub _jobname { $_[0]->classname . '&Accessors' }

my $registry;

sub for_class {
  my ( $self, $class ) = @_;
  return $self->_cache_or_construct(
    $registry => [$class] => sub {
      $self->new( classname => $class );
    }
  );
}

has accessor_stash => ( is => ro =>, lazy => 1, builder => '_build_accessor_stash' );

sub _build_accessor_stash {
  my $stash = {};
  for my $attr ( $_[0]->all_attributes ) {
    for my $accessor ( $attr->accessors ) {
      if ( not blessed($accessor) ) {
        warn "$accessor";
      }
      $stash->{ $accessor->accessorname } = $accessor;
    }
  }
  return $stash;
}

sub all                { values %{ $_[0]->accessor_stash } }
sub all_accessors      { values %{ $_[0]->accessor_stash } }
sub all_accessor_names { keys %{ $_[0]->accessor_stash } }

sub _to_hash {
  shift;
  return { map { ( $_->accessorname, $_->explanation ) } @_ };
}

1;
