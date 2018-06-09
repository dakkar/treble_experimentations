package Dakkar::Build;
use Dakkar::PerlFlavour;
use parent 'Dakkar::Shell','Dakkar::MkName';

sub build_variant($self,$variant) {
    $self->_shell(
        {
            $self->%{qw(jobs release extra_make_options)},
            name => $self->mk_name($variant),
        },
        <<'SH',
. build/envsetup.sh
lunch "${name}-userdebug"
make $extra_make_options BUILD_NUMBER="$release" installclean
make $extra_make_options BUILD_NUMBER="$release" -j "$jobs" systemimage
make $extra_make_options BUILD_NUMBER="$release" vndk-test-sepolicy
cp "$OUT"/system.img release/"$release"/system-"$name".img
SH
    );
}

sub build($self) {
    $self->_shell({ release => $self->{release} },<<'SH');
. build/envsetup.sh
repo manifest -r > release/"$release"/manifest.xml
SH

    for my $variant ($self->{variants}->@*) {
        $self->build_variant($variant);
    }
}

1;
