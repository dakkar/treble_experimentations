package Dakkar::Init;
use Dakkar::PerlFlavour;
use parent 'Dakkar::Shell';

sub init($self) {
    $self->_shell(
        { release => $self->{release } },
        'mkdir -p release/"$release"',
    );
}

1;
