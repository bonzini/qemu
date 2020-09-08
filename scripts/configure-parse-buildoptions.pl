#! /usr/bin/env perl

# Parse configure command line options based on Meson's user build options
# introspection data (passed on stdin).
#
# Copyright (C) 2020 Red Hat, Inc.
#
# Author: Paolo Bonzini <pbonzini@redhat.com>

use warnings FATAL => 'all';
use strict;
use JSON::PP;

use constant FEATURE_CHOICES => 'auto/disabled/enabled';
use constant LINE_WIDTH => 74;
use constant SKIP_OPTIONS => ('docdir', 'qemu_firmwarepath', 'sphinx_build', 'qemu_suffix');

sub value_to_help ($)
{
  my ($value) = @_;
  return $value if not JSON::PP::is_bool($value);
  return $value ? 'enabled' : 'disabled';
}

sub wrap($$$$)
{
  my ($text, $indent, $initial_indent, $subsequent_indent) = @_;
  my $length = LINE_WIDTH - $indent;
  my $line_re = qr/^(\s*)(.{1,$length}|\S+)(?=\s|$)/;

  my $spaces = ' ' x $indent;
  my $prefix = substr ($initial_indent . $spaces, 0, $indent);
  $subsequent_indent = substr ($subsequent_indent . $spaces, 0, $indent);

  while ($text =~ $line_re) {
    print "$prefix$2\n";
    $text = substr($text, (length $1) + (length $2));
    $prefix = $subsequent_indent;
  }
}

sub print_help_line($$$)
{
  my ($key, $opt, $indent) = @_;
  my $help = value_to_help($opt->{'value'});
  $key =~ s/_/-/g;
  $key = "  $key";
  my $value = $opt->{'description'} . " [$help]";
  if (length ($key) >= $indent) {
    print "$key\n";
    $key = '';
  }
  wrap($value, $indent, $key, '');

  if ($opt->{'type'} eq 'combo') {
    my $choices = $opt->{'choices'};
    my $list = join('/', sort @$choices);
    wrap("(choices: $list)", $indent, '', '')
      if $list ne FEATURE_CHOICES;
  }
}

sub allow_no_arg($)
{
  my ($item) = @_;
  return 1 if $item->{'type'} eq 'boolean';
  return 0 if $item->{'type'} ne 'combo';

  # Combos allow no argument only if "enabled" and "disabled"
  # are valid values
  my $choices = $item->{'choices'};
  return (grep { /^(enabled|disabled)$/ } @$choices) == 2;
}

sub allow_arg($)
{
  my ($item) = @_;
  return 0 if $item->{'type'} eq 'boolean';
  return 1 if $item->{'type'} ne 'combo';

  # Combos allow an argument only if they accept other values
  # than "auto", "enabled", and "disabled"
  my $choices = $item->{'choices'};
  return (join('/', sort @$choices) ne FEATURE_CHOICES);
}

sub print_choices($$)
{
  my ($item, $indent) = @_;
}

sub print_help(%)
{
  my (%options) = @_;
  foreach my $opt (sort keys %options) {
    my $item = $options{$opt};
    print_help_line("--enable-$opt", $item, 24)
      if ! allow_no_arg($item);
  }
  print("\n");
  print("Optional features, enabled with --enable-FEATURE and\n");
  print("disabled with --disable-FEATURE:\n");

  foreach my $opt (sort keys %options) {
    my $item = $options{$opt};
    print_help_line($opt, $item, 18)
      if allow_no_arg($item);
  }
  exit 0;
}

sub error($)
{
  my ($msg) = @_;
  print STDERR "ERROR: $msg\n";
  exit 1;
}

sub shell_quote($)
{
  my ($word) = @_;
  $word =~ s/'/'\\''/g;
  return "'$word'";
}


# Read Meson introspection data and convert it to a dictionary

my $input = do { local $/; <STDIN> };
my $json = decode_json $input;
my %options = ();

foreach my $item (@$json) {
  next if $item->{'section'} ne 'user';
  next if $item->{'name'} =~ /:/;
  $options{$item->{'name'}} = $item
    unless grep {$_ eq $item->{'name'}} SKIP_OPTIONS;
}

exit if ! @ARGV;
print_help(%options) if ($ARGV[0] eq '--print-help');

my @args = ();
foreach my $arg (@ARGV) {
  my ($before, $opt, $value) = $arg =~ /--(enable|disable)-([^=]*)(?:=(.*))?/;
  die "internal error parsing command line"
    if ! defined $before ;
  my $key =~ s/-/_/g;
  my $option = $options{$key};
  error("Unknown option --$before-$opt")
    if ! defined $options{$key} || ($before == 'disable' && ! allow_no_arg ($option));

  if (! defined $value) {
    error("option --$before-$opt requires an argument")
      if (! allow_no_arg ($option));
    if ($option->{'type'} eq 'combo') {
      $value = "${before}d";
    } else {
      $value = $before eq 'enable' ? 'true' : 'false';
    }
  } else {
    error("option --$before-$opt does not take an argument")
      if ($before eq 'disable' || ! allow_arg ($option));
  }
  push @args, shell_quote("-D$key=$value");
}
print join(' ', @args);
