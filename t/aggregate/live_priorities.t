#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
# This kludge is necessary to avoid failing due to circular dependencies
# with Catalyst-Runtime. Not ideal, but until we remove CDR from
# Catalyst-Runtime prereqs, this is necessary to avoid Catalyst-Runtime build
# failing.
BEGIN {
    eval qq{use Catalyst::Runtime 5.90030;};
    if( $@ ){
        use Test::More skip_all => 'Test require Catalyst::Runtime 5.90030';
        exit;
    }
    plan tests => 12;
}

use Catalyst::Test 'TestApp';

local $^W = 0;

my $uri_base = 'http://localhost/priorities';
my @tests = (

    #   Simple
    'Regex vs. Local',      { path => '/re_vs_loc',      expect => 'local' },
    # 'Regex vs. LocalRegex', { path => '/re_vs_locre',    expect => 'regex' },
    # After refactoring, priorities depend on the order the DispatchType
    # (Regex/Regexp/LocalRegex/LocalRegexp) is found in the controllers.
    'Regex vs. Path',       { path => '/re_vs_path',     expect => 'path' },
    'Local vs. LocalRegex', { path => '/loc_vs_locre',   expect => 'local' },
    'Path  vs. LocalRegex', { path => '/path_vs_locre',  expect => 'path' },

    #   index
    'index vs. Regex',      { path => '/re_vs_index',    expect => 'index' },
    'index vs. LocalRegex', { path => '/locre_vs_index', expect => 'index' },
);

while ( @tests ) {

    my $name = shift @tests;
    my $data = shift @tests;

    #   Run tests for path with trailing slash and without
  SKIP: for my $req_uri 
    ( 
        join( '' => $uri_base, $data->{ path } ),      # Without trailing path
        join( '' => $uri_base, $data->{ path }, '/' ), # With trailing path
    ) {
        my $end_slash = ( $req_uri =~ qr(/$) ? 1 : 0 );

        #   use slash_expect argument if URI ends with slash 
        #   and the slash_expect argument is defined
        my $expect = $data->{ expect } || '';
        if ( $end_slash and exists $data->{ slash_expect } ) {
            $expect = $data->{ slash_expect };
        }

        #   Call the URI on the TestApp
        my $response = request( $req_uri );

        #   Leave expect out to see the result
        unless ( $expect ) {
            skip 'Nothing expected, winner is ' . $response->content, 1;
        }

        #   Show error if response was no success
        if ( not $response->is_success ) {
            diag 'Error: ' . $response->headers->{ 'x-catalyst-error' };
        }

        #   Test if content matches expectations.
        #   TODO This might flood the screen with the catalyst please-come-later
        #        page. So I don't know it is a good idea.
        is( $response->content, $expect,
            "$name: @{[ $data->{ expect } ]} wins"
            . ( $end_slash ? ' (trailing slash)' : '' )
        );
    }
}

