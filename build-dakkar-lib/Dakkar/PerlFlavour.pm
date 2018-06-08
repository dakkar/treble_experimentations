package Dakkar::PerlFlavour;
use strict;
use warnings;
use 5.022;

sub import {
    my $caller = caller;

    # this hack is copied from Import::Into
    my $sub = eval <<"EOF" or die "wtf? $@";
package $caller;
sub {
  strict->import;
  warnings->import;
  require feature;
  feature->import(qw(say state postderef signatures));
  warnings->unimport(qw(experimental::postderef experimental::signatures));
}
EOF
    $sub->();
}

1;
