package Introspect::Attr::Accessor;

use Moo;
with 'Introspect::Common';

use Path::Tiny qw( path );
use List::Util qw( first );

has classname    => ( is => ro =>, required => 1 );
has attrname     => ( is => ro =>, required => 1 );
has accessorname => ( is => ro =>, required => 1 );

has metaclass => ( is => ro =>, lazy => 1, builder => '_get_metaclass' );
has metaattribute =>
  ( is => ro =>, lazy => 1, builder => '_get_metaattribute' );
has metaaccessor => ( is => ro =>, lazy => 1, builder => '_get_metaaccessor' );
has definition_context =>
  ( is => ro =>, lazy => 1, builder => '_get_definition_context' );

has 'is_public' => ( is => ro =>, lazy => 1, builder => '_build_is_public' );
has 'is_own'    => ( is => ro =>, lazy => 1, builder => '_build_is_own' );

my $registry;

sub _jobname {
    $_[0]->classname . '/' . $_[0]->attrname . '/' . $_[0]->accessorname;
}

sub for_accessor {
    my ( $self, $class, $attr, $accessor ) = @_;
    return $self->_cache_or_construct(
        $registry,
        [ $class, $attr, $accessor ],
        sub {
            $self->new(
                classname    => $class,
                attrname     => $attr,
                accessorname => $accessor
            );
        }
    );
}

sub _get_metaclass { return $_[0]->_cc_get_metaclass( $_[0]->classname ) }

sub _get_metaattribute {
    return $_[0]->_cc_get_metaattribute( $_[0]->metaclass, $_[0]->attrname );
}

sub _get_attribute_methods {
    return $_[0]->_cc_get_attribute_methods( $_[0]->metaattribute );
}

sub _get_definition_context {
    return $_[0]->_cc_get_definition_context( $_[0]->metaattribute );
}

sub _get_metaaccessor {
    my (@methods);
    if ( my $method = first { $_->name eq $_[0]->accessorname } ) {
        return $method;
    }
}

sub _build_is_public { return $_[0]->accessorname !~ /^_/; }
sub is_private       { !$_[0]->is_public }

sub _build_is_own { $_[0]->definition_context->{package} eq $_[0]->classname; }
sub is_inherited  { !$_[0]->is_own }

sub long_explanation {
    my $dc = $_[0]->definition_context;
    return
        $dc->{package}
      . '/attribute = '
      . $_[0]->attrname . ' => '
      . $_[0]->terse_explanation;
}

sub short_explanation {
    my $d = $_[0]->definition_context;
    return 'attribute = ' . $_[0]->attrname . ' => ' . $_[0]->terse_explanation;
}

sub terse_explanation {
    my $d = $_[0]->definition_context;
    return path( $d->{file} )->basename . ' line ' . $d->{line};
}

sub explanation {
    if ( $_[0]->is_own ) {
        return $_[0]->short_explanation;
    }
    return $_[0]->long_explanation;
}

1;
