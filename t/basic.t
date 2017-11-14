use strict;
use warnings;
use utf8;

use Test::More;
use TAP::SimpleOutput 'counters';

sub _check_level {
    my ($title, $counters, $level) = @_;

    my ($_ok, $_nok, $_skip, $_plan, $_todo) = @$counters;

    my @output;
    push @output, $_ok->('TestClass has a metaclass');
    push @output, $_skip->('TestClass is a Moose class');
    push @output, $_nok->('TestClass has an attribute named bar');
    push @output, $_ok->('TestClass has an attribute named baz');
    push @output, $_todo->($_ok->('TestClass has an attribute named foo'), 'next');
    push @output, $_plan->();

    my $indent = !$level ? q{} : (' ' x (4*$level));

    my @expected = map { "$indent$_" } (
        qq{ok 1 - TestClass has a metaclass},
        qq{ok 2 # skip TestClass is a Moose class},
        qq{not ok 3 - TestClass has an attribute named bar},
        qq{ok 4 - TestClass has an attribute named baz},
        qq{ok 5 - TestClass has an attribute named foo # TODO next},
        qq{1..5},
    );

    is_deeply
        [ @output   ],
        [ @expected ],
        "TAP output as expected: $title",
    ;
}

_check_level 'basic'   => [counters];
_check_level 'level 1' => [counters(1)], 1;

# levels and levels...
{
    my ($_ok, $_nok, $_skip, $_plan, $_todo) = counters();
    my @output;
    push @output, $_ok->('TestClass has a metaclass');
    push @output, $_skip->('TestClass is a Moose class');
    push @output, $_nok->('TestClass has an attribute named bar');
    push @output, $_ok->('TestClass has an attribute named baz');
    do {
        my ($_ok, $_nok, $_skip, $_plan) = counters(1);
        push @output, $_ok->(q{TestClass's attribute baz does TestRole::Two});
        push @output, $_ok->(q{TestClass's attribute baz has a reader});
        push @output, $_ok->(q{TestClass's attribute baz option reader correct});
        push @output, $_plan->();
    };
    push @output, $_ok->(q{[subtest] checking TestClass's attribute baz});
    push @output, $_todo->($_ok->('TestClass has an attribute named foo'), 'next');

    my @expected = (
        q{ok 1 - TestClass has a metaclass},
        q{ok 2 # skip TestClass is a Moose class},
        q{not ok 3 - TestClass has an attribute named bar},
        q{ok 4 - TestClass has an attribute named baz},
        q{    ok 1 - TestClass's attribute baz does TestRole::Two},
        q{    ok 2 - TestClass's attribute baz has a reader},
        q{    ok 3 - TestClass's attribute baz option reader correct},
        q{    1..3},
        q{ok 5 - [subtest] checking TestClass's attribute baz},
        q{ok 6 - TestClass has an attribute named foo # TODO next},
    );

    is_deeply
        [ @output   ],
        [ @expected ],
        'TAP output as expected',
        ;

}

done_testing;
