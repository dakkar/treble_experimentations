package Dakkar::Patch;
use Dakkar::PerlFlavour;
use parent 'Dakkar::Shell';

sub patch($self) {
    my %env_for_shell = (
        basedir => $self->{basedir},
        release => $self->{release},
    );
    if (my $generate = $self->{treble_generate}) {
        $self->_shell(\%env_for_shell, <<'SH');
rm -f device/*/sepolicy/common/private/genfs_contexts
( cd vendor/foss; git clean -fdx; bash update.sh )
bash "$basedir"/apply-patches.sh patches
SH
    }
    else {
        $self->_shell(\%env_for_shell, <<'SH');
bash "$basedir"/list-patches.sh
cp patches.zip release/"$release"/patches.zip
SH
    }
}

1;
