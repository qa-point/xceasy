#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

if [ "$#" -eq 0 ]; then
    set -- \
        "$repository_root/XCEasy/Sources" \
        "$repository_root/XCEasyIntegrationFixture/Sources"
fi

for source_root in "$@"; do
    [ -e "$source_root" ] || {
        echo "Swift documentation root does not exist: $source_root" >&2
        exit 66
    }
done

legacy_header_found=false
for header_root in "$repository_root" "$@"; do
    if rg -n \
        'Created by|Created on|^//  .+\.(swift|m|h)$' \
        "$header_root" \
        --glob '*.swift' \
        --glob '*.m' \
        --glob '*.h' \
        --glob '!Derived/**' \
        --glob '!**/.build/**' \
        --glob '!**/*.xcodeproj/**'
    then
        legacy_header_found=true
    fi
done
if [ "$legacy_header_found" = true ]; then
    echo "Legacy author/date/file banner found in hand-written code." >&2
    exit 1
fi

perl - "$@" <<'PERL'
use strict;
use warnings;
use File::Find;

my $declaration = qr{
    ^\s*
    (?:\@\w+(?:\([^)]*\))?\s+)*
    (?:(?:public|open|internal|private|fileprivate|final|required|convenience|
        override|class|static|mutating|nonmutating|indirect)\s+)*
    (?:func\s+|init(?:\?|!)?\s*\(|subscript\s*\(|deinit\b)
}x;

my @files;
for my $root (@ARGV) {
    if (-f $root) {
        push @files, $root if $root =~ /\.swift\z/;
        next;
    }
    find(
        {
            no_chdir => 1,
            wanted => sub { push @files, $File::Find::name if -f && /\.swift\z/ }
        },
        $root
    );
}

my @missing;
my $declaration_count = 0;
for my $file (sort @files) {
    open my $handle, '<', $file or die "Cannot read $file: $!\n";
    my @lines = <$handle>;
    close $handle;

    for my $index (0 .. $#lines) {
        next unless $lines[$index] =~ $declaration;
        $declaration_count++;

        my $cursor = $index - 1;
        while ($cursor >= 0) {
            my $line = $lines[$cursor];
            $line =~ s/^\s+|\s+$//g;
            if ($line eq '' || $line =~ /^\@/) {
                $cursor--;
                next;
            }
            last;
        }

        my $documented = $cursor >= 0 && (
            $lines[$cursor] =~ /^\s*\/\/\// ||
            $lines[$cursor] =~ /\*\//
        );
        if (!$documented) {
            my $signature = $lines[$index];
            $signature =~ s/^\s+|\s+$//g;
            push @missing, "$file:" . ($index + 1) . ": $signature";
        }
    }
}

if (@missing) {
    print STDERR "Missing Swift DocC comments:\n", join("\n", @missing), "\n";
    exit 1;
}

print "Swift documentation validation passed: $declaration_count callable declarations.\n";
PERL
