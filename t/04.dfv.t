use strict;
use warnings;
use Carp;
use Test::More;
use Test::Differences;
use Readonly;
use File::Basename;
use Perl6::Slurp;

eval "require Data::FormValidator";
if ($@) {
    plan skip_all => 'This test requires Data::FormValidator';
}
use Data::FormValidator::Filters::HTML::Acid;

Readonly my @INPUT_FILES => glob 't/in/??-*';
plan tests => scalar @INPUT_FILES;

Readonly my $PROFILE => {
    required=>['html'],
    field_filters=>{
        html=>filter_html(),
    },
};

foreach my $input_file (@INPUT_FILES) {
    my $input = slurp $input_file;
    my $basename = basename $input_file;
    my $expected = slurp "t/out/$basename";
    my $results = Data::FormValidator->check({html=>$input}, $PROFILE);
    if ($results) {
         eq_or_diff($results->valid->{html}, $expected, $basename);
    }
    else {
         fail($basename);
    }
}

