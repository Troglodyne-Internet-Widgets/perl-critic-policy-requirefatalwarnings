# NAME

Perl::Critic::Policy::RequireFatalWarnings - A warning nobody reads is a bug you ship.

# VERSION

version 1.000

# Perl::Critic::Policy::RequireFatalWarnings

`use warnings;` puts a line on STDERR and carries on with whatever wrong value
provoked it.  In a long-running program with a busy log, nobody sees it; in a
script whose output is piped somewhere, nobody sees it either.  The undefined
value still got interpolated, and the file it named still got written to the
wrong place.

```perl
use warnings;               # not ok, the run continues regardless

use warnings FATAL => 'all';   # ok, the run stops where the bug is
```

This does not make `warn` calls fatal -- an explicit `warn` is a message you
chose to emit, and it still just prints.  What becomes fatal is the categories
perl raises itself: uninitialized values, numeric conversions, redefinitions,
and the rest.

## PROHIBITED

```perl
use warnings;
use warnings 'all';
use warnings qw{uninitialized};
# ...or no `use warnings` in the file at all
```

## ALLOWED

```perl
use warnings FATAL => 'all';
```

A file that also switches categories back off for a stretch is fine; this looks
for the enabling statement, not for what happens afterwards.

## CONFIGURATION

- `equivalent_modules`

    Space separated list of modules that turn fatal warnings on for you, so a file
    using one of them is not asked for the pragma as well.  Defaults to
    `Moose Moo Mouse strictures Test2::V0`.

    ```
    [RequireFatalWarnings]
    equivalent_modules = strictures My::Company::Policy
    ```

## CAVEATS

Fatal warnings in a module other people `use` can turn a caller's survivable
warning into a death they did not ask for.  That is a real argument, and it is
why this policy is not on by default anywhere but in the distributions that opt
into it.

## METHODS

### supported\_parameters

`equivalent_modules`, modules that enable fatal warnings on your behalf.

### default\_severity

SEVERITY\_MEDIUM

### default\_themes

bugs, maintenance

### applies\_to

PPI::Document

### violates

Standard [Perl::Critic::Policy](https://metacpan.org/pod/Perl%3A%3ACritic%3A%3APolicy) interface.  Reports once per document, on the
`use warnings` that should have been fatal, or on the first statement in the
file when there is no `use warnings` to point at.

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/teodesian/perl-critic-policy-requirefatalwarnings/issues](https://github.com/teodesian/perl-critic-policy-requirefatalwarnings/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHORS

Current Maintainers:

- George S. Baugh <teodesian@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
