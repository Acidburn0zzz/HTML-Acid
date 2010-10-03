use strict;
use warnings;
use Carp;
use Test::More;
use Test::NoWarnings;
use Test::Differences;
use HTML::Acid;
use Readonly;
use File::Basename;
use Perl6::Slurp;
use Benchmark qw(timethis);

Readonly my @INPUT_FILES => glob 't/in/??-*';
Readonly my $MINIMUM_TIME => 10;
Readonly my $MINIMUM_ITERS => 190*$MINIMUM_TIME;
plan tests => 6+@INPUT_FILES;

Readonly my %ARGS => (
    url_regex=>qr{
        \A                  # start of string
        (?:
            (?:
                http://\w[\w\.]{1,20}\w
            )                  # optional external ref
            |
            (?:
                /                   # 
                \w                  # at least one normal character
                [\w\-/]*            # 
            )
        )
        (?:\#[\w\-]+)?      # optional anchor
        \z                  # end of string
    }xms,
    tag_hierarchy => {
        h3 => '',
        p => '',
        a => 'p',
        div => 'p',
        img => 'div',
        em => 'p',
        strong => 'p',
    },
);
my $acid = HTML::Acid->new(%ARGS);

isa_ok($acid, 'HTML::Acid', 'is a HTML::Acid');
isa_ok($acid, 'HTML::Parser', 'is a HTML::Parser');
ok($acid->can('burn'), 'Acid can burn.');
is($acid->burn(''), '', 'really trivial stuff');
is($acid->burn('blah'), "<p>blah</p>\n", 'really trivial blah');

foreach my $input_file (@INPUT_FILES) {
    subtest $input_file => sub {
        plan tests => 3;
        my $input = slurp $input_file;
        my $basename = basename $input_file;
        my $expected = slurp "t/variant/$basename";
        my $actual = $acid->burn($input);
        eq_or_diff($actual, $expected, "expected - $basename");
        $actual = $acid->burn($actual);
        eq_or_diff($actual, $expected, "idempotency - $basename");

        if ($ENV{TEST_AUTHOR}) {
            my $benchmark = timethis(-$MINIMUM_TIME, sub {
                my $t_acid = HTML::Acid->new(%ARGS);
                my $t_actual = $t_acid->burn($input);
                croak "failed" if $t_actual ne $expected;
            });
            ok($benchmark->iters > $MINIMUM_ITERS,
                "minimal iterations - $basename");
        }
        else {
            pass('set TEST_AUTHOR=1 for timings');
        }
    }
}
