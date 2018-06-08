package Dakkar::Getopt;
use Dakkar::PerlFlavour;
use File::Basename ();
use Getopt::Long ();

# this is a stupid constructor
sub new($class,$args) {
    return bless $args, $class;
}

sub program_name($self) {
    return $self->{program_name} || scalar File::Basename::fileparse($0);
}

sub options_help_text($self) {
    my $options_text = "Options:\n\n";
    for my $opt_name (sort keys $self->{options}->%*) {
        my $opt = $self->{options}->{$opt_name};
        $options_text .= sprintf '   -%s  --%s  %s',
            $opt->{short}, $opt->{long}, $opt->{desc};
        if (my $default = $opt->{default}) {
            $options_text .= " (defaults to $default)";
        }
        $options_text .= "\n";
    }

    return $options_text;
}

sub rom_types_help_text($self) {
    my $rom_text = "ROM types:\n\n";
    for my $rom_name (sort keys $self->{rom_types}->%*) {
        $rom_text .= "  $rom_name\n";
    }
    return $rom_text;
}

sub variants_help_text($self) {
    my $variants_text = "Variants are dash-joined combinations of (in order):\n\n";

    my @examples;
    for my $part ($self->{variant_parts}->@*) {
        $variants_text .= sprintf " * %s\n",$part->{name};
        my @value_names = sort keys $part->{values}->%*;
        for my $value_name (@value_names) {
            my $value = $part->{values}{$value_name};
            $variants_text .= sprintf "  * '%s' %s\n",
                $value_name, $value->{desc};
        }

        push $examples[0]->@*, $value_names[0];
        push $examples[1]->@*, $value_names[-1];
    }

    $variants_text .= "\nfor example:\n\n";
    for my $example (@examples) {
        $variants_text .= sprintf "* %s\n", join '-', $example->@*;
    }

    return $variants_text;
}

sub help_text($self) {
    return join "\n", (
        (sprintf "Syntax\n\n  %s [options] <rom type> <variant>...\n\n", $self->program_name),
        $self->options_help_text,
        $self->rom_types_help_text,
        $self->variants_help_text,
    );
}

sub getopt_spec($self) {
    my %spec;my %output;
    for my $opt_name (keys $self->{options}->%*) {
        my $opt = $self->{options}->{$opt_name};
        my $spec_name = sprintf '%s|%s%s',
            $opt->{long},$opt->{short},$opt->{type}||'';
        $output{$opt_name} = $opt->{default};
        $spec{$spec_name} = \$output{$opt_name};
    }

    return (\%spec,\%output);
}

sub parse_variant($self,$raw) {
    my @parts = split /-/,$raw;

    my $ret;
    for my $part_spec ($self->{variant_parts}->@*) {
        my $input_part = shift @parts or return;
        my $value = $part_spec->{values}{$input_part} or return;
        $ret .= $value->{map};
    }

    return $ret;
}

sub error($self,$message) {
    warn "$message\n\n" if $message;
    warn $self->help_text;
    return undef;
}

sub parse_opts($self,@args) {
    my ($spec,$output) = $self->getopt_spec;

    my $parser = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case)],
    );

    $parser->getoptionsfromarray(\@args,$spec->%*) or return $self->error;

    my ($rom_type,@raw_variants) = @args;

    $rom_type or return $self->error('Missing rom type');

    $self->{rom_types}{$rom_type}
        or return $self->error("Unrecognized rom type <$rom_type>");

    @raw_variants or return $self->error('Missing variants');

    my @variants;
    for my $raw (@raw_variants) {
        push @variants, $self->parse_variant($raw)
            or return $self->error("Unrecognized variant <$raw>");
    }

    $output->{rom_type} = $rom_type;
    $output->{variants} = \@variants;

    return $output;
}

1;
