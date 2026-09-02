package Perl::Critic::Policy::RequireFatalWarnings;

# ABSTRACT: A warning nobody reads is a bug you ship.

use strict;
use warnings;

use 5.014;

use re '/aa';

use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use parent              qw{Perl::Critic::Policy};

=head1 Perl::Critic::Policy::RequireFatalWarnings

C<use warnings;> puts a line on STDERR and carries on with whatever wrong value
provoked it.  In a long-running program with a busy log, nobody sees it; in a
script whose output is piped somewhere, nobody sees it either.  The undefined
value still got interpolated, and the file it named still got written to the
wrong place.

    use warnings;               # not ok, the run continues regardless

    use warnings FATAL => 'all';   # ok, the run stops where the bug is

This does not make C<warn> calls fatal -- an explicit C<warn> is a message you
chose to emit, and it still just prints.  What becomes fatal is the categories
perl raises itself: uninitialized values, numeric conversions, redefinitions,
and the rest.

=head2 PROHIBITED

    use warnings;
    use warnings 'all';
    use warnings qw{uninitialized};
    # ...or no `use warnings` in the file at all

=head2 ALLOWED

    use warnings FATAL => 'all';

A file that also switches categories back off for a stretch is fine; this looks
for the enabling statement, not for what happens afterwards.

=head2 CONFIGURATION

=over 4

=item C<equivalent_modules>

Space separated list of modules that turn fatal warnings on for you, so a file
using one of them is not asked for the pragma as well.  Defaults to
C<Moose Moo Mouse strictures Test2::V0>.

    [RequireFatalWarnings]
    equivalent_modules = strictures My::Company::Policy

=back

=head2 CAVEATS

Fatal warnings in a module other people C<use> can turn a caller's survivable
warning into a death they did not ask for.  That is a real argument, and it is
why this policy is not on by default anywhere but in the distributions that opt
into it.

=cut

Readonly::Scalar my $DESC => q{Warnings are enabled but not fatal};
Readonly::Scalar my $EXPL => q{Use 'use warnings FATAL => "all";' so a warning stops the run where the bug is};

=head2 METHODS

=head3 supported_parameters

C<equivalent_modules>, modules that enable fatal warnings on your behalf.

=head3 default_severity

SEVERITY_MEDIUM

=head3 default_themes

bugs, maintenance

=head3 applies_to

PPI::Document

=cut

sub supported_parameters {
    return ({
        name           => 'equivalent_modules',
        description    => 'Modules that switch fatal warnings on for you.',
        default_string => 'Moose Moo Mouse strictures Test2::V0',
        behavior       => 'string list',
    });
}

sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw(bugs maintenance) }
sub applies_to       { return 'PPI::Document' }

=head3 violates

Standard L<Perl::Critic::Policy> interface.  Reports once per document, on the
C<use warnings> that should have been fatal, or on the first statement in the
file when there is no C<use warnings> to point at.

=cut

sub violates {
    my ( $self, $elem, $document ) = @_;

    my $includes = $document->find('PPI::Statement::Include') || [];

    my $enabling;
    foreach my $include (@$includes) {
        next if $include->type() ne 'use';

        my $module = $include->module();
        next if !defined $module;

        return if $self->{_equivalent_modules}{$module};
        next   if $module ne 'warnings';

        return if _is_fatal($include);    # somebody already said so
        $enabling //= $include;
    }

    # Point at the `use warnings` that should have been fatal, or at the top of
    # the file when there is nothing to point at.
    my $anchor = $enabling // $document->schild(0) // $document;
    return $self->violation( $DESC, $EXPL, $anchor );
}

# `use warnings FATAL => 'all'`, in any of its spellings.
sub _is_fatal {
    my ($include) = @_;

    my @words;
    foreach my $token ( $include->schildren() ) {
        if ( $token->isa('PPI::Token::QuoteLike::Words') ) {
            push @words, $token->literal();
        }
        elsif ( $token->isa('PPI::Token::Quote') ) {
            push @words, $token->string();
        }
        elsif ( $token->isa('PPI::Token::Word') ) {
            push @words, $token->content();
        }
    }

    my $fatal;
    foreach my $word (@words) {
        next if !defined $word;
        $fatal = 1  if $word eq 'FATAL';
        return 1    if $fatal && $word eq 'all';
    }

    return 0;
}

1;
