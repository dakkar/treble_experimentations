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
(
set -e

patches="$(readlink -f -- patches)"

for project in $(cd "$patches"/patches; echo *);do
	p="$(tr _ / <<<$project |sed -e 's;platform/;;g')"
	[ "$p" == build ] && p=build/make
	repo sync -l --force-sync $p
	pushd $p
	git clean -fdx; git reset --hard
	for patch in $patches/patches/$project/*.patch;do
		#Check if patch is already applied
		if patch -f -p1 --dry-run -R < $patch > /dev/null;then
			continue
		fi

		if git apply --check $patch;then
			git am $patch
		elif patch -f -p1 --dry-run < $patch > /dev/null;then
			#This will fail
			git am $patch || true
			patch -f -p1 < $patch
			git add -u
			git am --continue
		else
			echo "Failed applying $patch"
		fi
	done
	popd
done
)
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
