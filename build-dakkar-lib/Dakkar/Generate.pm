package Dakkar::Generate;
use Dakkar::PerlFlavour;
use parent 'Dakkar::Shell','Dakkar::MkName';

my %apps_script = (
    gapps => 'device/phh/treble/gapps.mk',
    go => 'device/phh/treble/gapps-go.mk',
    floss => 'vendor/foss/foss.mk',
    custom => 'custom-apps.mk',
);
sub generate_variant($self,$variant) {
    my $product_name = $self->mk_name($variant);
    open my $fh,'>',"device/phh/treble/$product_name.mk";

    print $fh "\$(call inherit-product, device/phh/treble/base-pre.mk)\n";
    print $fh "include build/make/target/product/treble_common.mk\n";

    my $vndk = $variant->{cpu} eq 'arm' ? 'vndk-binder32.mk' : 'vndk.mk';
    print $fh "\$(call inherit-product, vendor/vndk/$vndk)\n";

    print $fh "\$(call inherit-product, device/phh/treble/base.mk)\n";

    if (my $apps_script = $apps_script{$variant->{apps}}) {
        print $fh "\$(call inherit-product, $apps_script)\n";
    }

    if (my $rom = $self->{treble_generate}) {
        print $fh "\$(call inherit-product, device/phh/treble/${rom}.mk)\n";
    }

    print $fh "PRODUCT_NAME := $product_name\n";
    my $part_suffix = $variant->{partition} eq 'aonly' ? 'a' : 'ab';
    print $fh "PRODUCT_DEVICE := phhgsi_$variant->{cpu}_${part_suffix}\n";
    print $fh "PRODUCT_BRAND := Android\n";
    print $fh "PRODUCT_MODEL := Phh-Treble $variant->{apps}\n";

    if ($variant->{su} eq 'su') {
        print $fh "PRODUCT_PACKAGES += phh-su\n";
    }
}

sub generate($self) {
    $self->_shell({},<<'SH');
cd device/phh/treble
git clean -fdx
SH

    open my $fh, '>','device/phh/treble/AndroidProducts.mk';
    print $fh "PRODUCT_MAKEFILES := \\\n";

    for my $variant ($self->{variants}->@*) {
        $self->generate_variant($variant);
        my $product_name = $self->mk_name($variant);
        print $fh "\t\$(LOCAL_DIR)/$product_name.mk \\\n";
    }

    print $fh "\n";
}

1;
