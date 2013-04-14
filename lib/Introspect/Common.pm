
use strict;
use warnings;

package Introspect::Common;
use Moo::Role;

requires '_jobname';

## _require_module( $self, $module )
sub _require_module {
    my ( $class, $module ) = @_;
    require Module::Runtime;
    local $SIG{__WARN__} = sub { };
    return scalar Module::Runtime::use_module( $_[1] );
}
my $prefix = "\e[31mIntrospect: \e[0m";
sub _cc_warn {
    warn $prefix . $_[1] . ' for ' . $_[0]->_jobname;
}
sub _cc_die {
    if ( 1 ) {
        return $_[0]->_cc_warn($_[1]);
    } else {
        die $prefix . $_[1] . ' for ' . $_[0]->_jobname;
    }
}
## _cc_get_metaclass( $self, $classname )
sub _cc_get_metaclass {
    return $_[0]->_require_module( $_[1] )->meta;
}
## _cc_get_metaattribute( $self, $metaclass, $attributename )
sub _cc_get_metaattribute {
    if ( $_[1]->can('find_attribute_by_name') ) {
        return $_[1]->find_attribute_by_name( $_[2] );
    }
    if ( $_[1]->can('get_attribute') ) {
        return $_[1]->get_attribute( $_[2] );
    }
    $_[0]->_cc_die("Can't get a metaattribute from " . $_[1] );
}
## _cc_get_attribute_methods( $self, $metaattribute )
sub _cc_get_attribute_methods {
    if ( $_[1]->can('associated_methods') ) {
        return @{ $_[1]->associated_methods };
    }
    $_[0]->_cc_die("Can't get associated methods from " . $_[1] );
    return ();
}

sub _cc_unknown_definition_context {
    $_[0]->_cc_warn("Can't get a definition context from " . $_[1] );
    return { package => 'unknown', 'line' => 'unknown', file => 'unknown' };
}

sub _cc_get_definition_context {
    if ( $_[1]->can('definition_context') ) {
        my $dc = $_[1]->definition_context;
        if ( not ref $dc ) {
            return $_[0]->_cc_unknown_definition_context( $_[1] );
        }
        return $dc;
    }
    return $_[0]->_cc_unknown_definition_context( $_[1] );
}

## _cache_or_construct( $self, \$cache, [ @path ], sub { constructor } )
sub _cache_or_construct {
    my ( $self, $r_cache, $path, $defer ) = @_;
    my $cache = $r_cache;
    while ( @{$path} ) {
        if ( $path->[1] ) {
            $cache->{ $path->[0] } ||= {};
            $cache = $cache->{ $path->[0] };
            shift @{$path};
            next;
        }
        return $cache->{ $path->[0] } if exists $cache->{ $path->[0] };
        return ( $cache->{ $path->[0] } = $defer->() );
    }
}

1;
