package Dakkar::PlatformInfo;
use Dakkar::PerlFlavour;
use POSIX qw(strftime);

sub num_cpus($class) {
    my $num_cpus = `nproc` || `sysctl -n hw.ncpu`;
    chomp($num_cpus);
    return $num_cpus;
}

sub today($class) {
    return strftime('%y%m%d',localtime());
}

1;
