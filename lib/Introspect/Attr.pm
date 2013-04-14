
package Introspect::Attr;

use Moo;
with 'Introspect::Common';
use Path::Tiny qw( path );

has classname => ( is => ro =>, required => 1 );
has attrname  => ( is => ro =>, required => 1 );

has metaclass          => ( is => ro =>, lazy => 1, builder => '_get_metaclass' );
has metaattribute      => ( is => ro =>, lazy => 1, builder => '_get_metaattribute' );
has definition_context => ( is => ro =>, lazy => 1, builder => '_get_definition_context' );

has 'is_public' => ( is => ro =>, lazy => 1, builder => '_build_is_public' );
has 'is_own'    => ( is => ro =>, lazy => 1, builder => '_build_is_own' );

my $registry;

sub _jobname {
  $_[0]->classname . '/' . $_[0]->attrname;
}

sub for_attribute {
  my ( $self, $class, $attr ) = @_;
  return $self->_cache_or_construct(
    $registry,
    [ $class, $attr ],
    sub {
      $self->new( classname => $class, attrname => $attr );
    }
  );
}
sub _get_metaclass { return $_[0]->_cc_get_metaclass( $_[0]->classname ) }

sub _get_metaattribute {
  return $_[0]->_cc_get_metaattribute( $_[0]->metaclass, $_[0]->attrname );
}

sub _unknown_definition_context {
  warn "\e[31m classmap\e[0mCan't get a definition context for " . $_[0]->_jobname . " " . $_[0]->metaattribute;
  return { package => 'unknown', 'line' => 'unknown', file => 'unknown' };
}

sub _get_definition_context {
  if ( $_[0]->metaattribute->can('definition_context') ) {
    my $dc = $_[0]->metaattribute->definition_context;
    if ( not ref $dc ) {
      return $_[0]->_unknown_definition_context;
    }
    return $dc;
  }
  return $_[0]->_unknown_definition_context;
}

sub _build_is_public { return $_[0]->attrname !~ /^_/; }
sub is_private       { !$_[0]->is_public }

sub _build_is_own { $_[0]->definition_context->{package} eq $_[0]->classname; }
sub is_inherited  { !$_[0]->is_own }

sub long_explanation {
  my $dc = $_[0]->definition_context;
  return $dc->{package} . '/' . $_[0]->attrname . ' => ' . $_[0]->short_explanation;
}

sub short_explanation {
  my $d = $_[0]->definition_context;
  return path( $d->{file} )->basename . ' line ' . $d->{line};
}

sub explanation {
  if ( $_[0]->is_own ) {
    return $_[0]->short_explanation;
  }
  return $_[0]->long_explanation;
}

sub inflate_accessor {
  require Introspect::Attr::Accessor;
  return Introspect::Attr::Accessor->for_accessor( $_[0]->classname, $_[0]->attrname, $_[1] );
}

sub accessors {
  return map { $_[0]->inflate_accessor( $_->name ) } $_[0]->_cc_get_attribute_methods( $_[0]->metaattribute );
  return ();
}

1;
