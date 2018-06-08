package Dakkar::BuildTools;
use Dakkar::PerlFlavour;
use File::Path ();
use File::Copy ();
use Data::Dumper;
use Cwd ();

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

sub init($self) {
    $self->_shell(
        { release => $self->{release } },
        'mkdir -p release/"$release"',
    );
}

sub clone_or_checkout($self,$dir,$repo) {
    my %env_for_shell = (
        repo => $repo,
        dir => $dir,
        branch => $self->{localManifestBranch},
    );
    if (-d $dir) {
        $self->_shell(\%env_for_shell,<<'SH');
cd "$dir"
git fetch
git reset --hard
git checkout "origin/$branch"
SH
    }
    else {
        $self->_shell(\%env_for_shell,<<'SH');
git clone "https://github.com/phhusson/$repo" "$dir" -b "$branch"
SH
    }
}

sub sync($self) {
    $self->_shell(
        { repo => $self->{mainrepo}, branch => $self->{mainbranch} },
        'repo init -u "$repo" -b "$branch"',
    );

    $self->clone_or_checkout('.repo/local_manifests','treble_manifest');

    if ($self->{treble_generate}) {
        $self->clone_or_checkout('patches','treble_patches');
        # We don't want to replace from AOSP since we'll be applying
        # patches by hand
        unlink('.repo/local_manifests/replace.xml');
    }

    $self->_shell(
        { jobs => $self->{jobs} },
        'repo sync -c -j "$jobs" --force-sync',
    );
}

sub patch($self) {
    my %env_for_shell = (
        generate => $self->{treble_generate},
        basedir => $self->{basedir},
        release => $self->{release},
    );
    if (my $generate = $self->{treble_generate}) {
        $self->_shell(\%env_for_shell, <<'SH');
rm -f device/*/sepolicy/common/private/genfs_contexts
(
  cd device/phh/treble
  git clean -fdx
  bash generate.sh "$generate"
)
bash "$basedir"/apply-patches.sh patches
SH
    }
    else {
        $self->_shell(\%env_for_shell, <<'SH');
(
  cd device/phh/treble
  git clean -fdx
  bash generate.sh
)
repo manifest -r > release/"$release"/manifest.xml
bash "$basedir"/list-patches.sh
cp patches.zip release/"$release"/patches.zip
SH
    }
}

sub build_variant($self,$variant_code,$variant_name) {
    $self->_shell(
        {
            $self->%{qw(jobs release extra_make_options)},
            name => $variant_name,
            code => $variant_code,
        },
        <<'SH',
. build/envsetup.sh
lunch "$code"
make $extra_make_options BUILD_NUMBER="$release" installclean
make $extra_make_options BUILD_NUMBER="$release" -j "$jobs" systemimage
make $extra_make_options BUILD_NUMBER="$release" vndk-test-sepolicy
cp "$OUT"/system.img release/"$release"/system-"$name".img
SH
    );
}

sub build($self) {
    for my $variant ($self->{variants}->@*) {
        $self->build_variant($variant->@*)
    }
}

1;
