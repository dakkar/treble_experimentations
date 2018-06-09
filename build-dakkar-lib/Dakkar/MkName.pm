package Dakkar::MkName;
use Dakkar::PerlFlavour;

sub mk_name($self,$variant) {
    return sprintf 'treble_%s_%s%s%s',
        $variant->@{qw(cpu partition apps su)};
}

1;
