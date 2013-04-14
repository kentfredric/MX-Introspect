use strict;
use warnings;

package Introspect;

# ABSTRACT:

use Moose;

__PACKAGE__->meta->make_immutable;
no Moose;

1;
