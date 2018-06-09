package Dakkar::Sync;
use Dakkar::PerlFlavour;
use parent 'Dakkar::Shell';

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

1;
