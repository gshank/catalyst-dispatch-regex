package TestApp::View::Dump::Action;

use strict;
use base qw[TestApp::View::Dump];

sub process {
    my ( $self, $c ) = @_;
    return $self->SUPER::process( $c, $c->action, 0 );
}

1;
