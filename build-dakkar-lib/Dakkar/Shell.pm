package Dakkar::Shell;
use Dakkar::PerlFlavour;

# this is a stupid constructor
sub new($class,$args) {
    return bless $args, $class;
}

sub _shell($self,$env,$cmd) {
    if ($self->{pretend}) {
        for my $k (keys $env->%*) {
            my $v = $env->{$k} || '';
            $cmd =~ s{\$\Q$k}{$v}g;
        }
        $cmd =~ s{^}{  }gm;
        say "\n$cmd";
        return;
    }

    local %ENV = (
        %ENV,
        $env->%*,
    );
    my $exit_status = system('bash','-c',$cmd);
    return if $exit_status == 0; # unix for "all right"
    warn "Error runnning <$cmd>: $?";
    exit 1;
}

1;
