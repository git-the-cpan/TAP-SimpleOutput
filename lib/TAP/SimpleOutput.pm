#
# This file is part of TAP-SimpleOutput
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package TAP::SimpleOutput;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.002-10-gd6df9d1
$TAP::SimpleOutput::VERSION = '0.003';

# ABSTRACT: Simple closure-driven TAP generator

use strict;
use warnings;

use Sub::Exporter::Progressive -setup => {
    exports => [
        qw{ counters counters_and_levelset },
    ],
};



sub counters {
    my @counters = _build_counters(@_);
    pop @counters;
    return @counters;
}


sub counters_and_levelset { goto \&_build_counters }

sub _build_counters {
    my $level = shift @_ || 0;
    $level *= 4;
    my $i = 0;

    my $indent = !$level ? q{} : (' ' x $level);

    return (
        sub { $indent .     'ok ' . ++$i . " - $_[0]"      }, # ok
        sub { $indent . 'not ok ' . ++$i . " - $_[0]"      }, # nok
        sub { $indent .     'ok ' . ++$i . " # skip $_[0]" }, # skip
        sub { $indent . "1..$i"                            }, # plan
        sub { "$_[0] # TODO $_[1]"                         }, # todo
        sub { $indent . "$_[0]"                            }, # freeform
        sub {
            # if we're called with a new level, set $level and $indent
            # appropriately
            do { $level = $_[0] * 4; $indent = !$level ? q{} : (' ' x $level) }
                if defined $_[0];

            # return our new/set level regardless, in the form we passed it in
            return $level / 4;
        },
    );
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl SUBTESTS subtests Subtests subtest Subtest

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

TAP::SimpleOutput - Simple closure-driven TAP generator

=head1 VERSION

This document describes version 0.003 of TAP::SimpleOutput - released May 05, 2015 as part of TAP-SimpleOutput.

=head1 SYNOPSIS

    use TAP::SimpleOutput 'counter';

    my ($_ok, $_nok, $_skip, $_plan) = counters();
    say $_ok->('TestClass has a metaclass');
    say $_ok->('TestClass is a Moose class');
    say $_ok->('TestClass has an attribute named bar');
    say $_ok->('TestClass has an attribute named baz');
    do {
        my ($_ok, $_nok, $_skip, $_plan) = counters(1);
        say $_ok->(q{TestClass's attribute baz does TestRole::Two});
        say $_ok->(q{TestClass's attribute baz has a reader});
        say $_ok->(q{TestClass's attribute baz option reader correct});
        say $_plan->();
    };
    say $_ok->(q{[subtest] checking TestClass's attribute baz});
    say $_ok->('TestClass has an attribute named foo');

    # STDOUT looks like:
    ok 1 - TestClass has a metaclass
    ok 2 - TestClass is a Moose class
    ok 3 - TestClass has an attribute named bar
    ok 4 - TestClass has an attribute named baz
        ok 1 - TestClass's attribute baz does TestRole::Two
        ok 2 - TestClass's attribute baz has a reader
        ok 3 - TestClass's attribute baz option reader correct
        1..3
    ok 5 - [subtest] checking TestClass's attribute baz
    ok 6 - TestClass has an attribute named foo

=head1 DESCRIPTION

We provide one function, C<counters()>, that returns a number of simple
closures designed to help output TAP easily and correctly, with a minimum of
fuss.

=head1 FUNCTIONS

=head2 counters($level)

This function returns four closures that each generate a different type of TAP
output.  It takes an optional C<$level> that determines the indentation level
(e.g. for subtests).  These coderefs are all closed over the same counter
variable that keeps track of how many test have been run so far; this allows
them to always output the correct test number.

    my ($_ok, $_nok, $_skip, $_plan, $_todo, $_freeform) = counters();

    $_ok->('whee')            returns "ok 1 - whee"
    $_nok->('boo')            returns "not ok 2 - boo"
    $_skip->('baz')           returns "ok 3 # skip baz"
    $_plan->()                returns "1..3"
    $_todo->('bip', 'daleks') returns "bip # TODO daleks"
    $_freeform->('yay')       returns "yay"

Note that calling the C<$_plan> coderef only returns an intelligible response
when called after all the output has been generated; this is analogous to
using L<Test::More> without a declared plan and C<done_testing()> at the end.
If you need or want to specify the plan prior to running tests, you'll need to
do that manually.

=head3 subtests

When C<counter()> is passed an integer, the generated closures all indent
themselves appropriately to indicate to the test harness / TAP parser that a
subtest is being run.  (Namely, each statement returned is prefaced with
C<$level * 4> spaces.)  It's recommended that you use distinct lexical scopes
for subtests to allow the usage of the same variable names (why make things
difficult?) without clobbering any existing ones and to ensure that the
subtest closures are not inadvertently used at an upper level.

    my ($_ok, $_nok) = counters();
    $_ok->('yay!');
    $_nok->('boo :(');
    do {
        my ($_ok, $_nok, $_skip, $_plan) = counters(1);
        $_ok->('thing 1 good');
        $_ok->('thing 2 good');
        $_ok->('thing 3 good');
        $_skip->('over there');
        $_plan->();
    };
    $_ok->('subtest passed');

    # returns
    ok 1 - yay!
    not ok 2 - boo :(
        ok 1 - thing 1 good
        ok 2 - thing 2 good
        ok 3 - thing 3 good
        ok 4 # skip over there
        1..4
    ok 3 - subtest passed

=head2 counters_and_levelset($level)

Acts as counters(), except returns an additional coderef that can be used to
adjust the level of the counters.

This is not something you're likely to need.

=head1 USAGE WITH Test::Builder::Tester

This package was created from code I was using to make it easier to test my
test packages with L<Test::Builder::Tester>:

    test_out $_ok->('TestClass has a metaclass');
    test_out $_ok->('TestClass is a Moose class');
    test_out $_ok->('TestClass has an attribute named bar');
    test_out $_ok->('TestClass has an attribute named baz');

Once I realized I was using the exact same code (perhaps at different points
in time) in multiple packages, the decision to break it out became pretty
easy to make.

=head1 SUBTESTS

Subtest formatting can be done by passing a an integer "level" parameter to
C<counter()>; see the function's documentation for details.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Test::Builder::Tester>

=item *

L<TAP::Harness>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/tap-simpleoutput/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Ftap-simpleoutput&title=RsrchBoy's%20CPAN%20TAP-SimpleOutput&tags=%22RsrchBoy's%20TAP-SimpleOutput%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Ftap-simpleoutput&title=RsrchBoy's%20CPAN%20TAP-SimpleOutput&tags=%22RsrchBoy's%20TAP-SimpleOutput%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
