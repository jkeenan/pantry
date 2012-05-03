use v5.14;
use warnings;

package Pantry::App::Command::apply;
# ABSTRACT: Implements pantry apply subcommand
# VERSION

use Pantry::App -command;
use autodie;

use namespace::clean;

sub abstract {
  return 'apply recipes or attributes to a node'
}

sub usage_desc {
  my ($self) = shift;
  return $self->target_usage;
}

sub description {
  my ($self) = @_;
  my $preamble = <<'HERE';
The 'apply' command adds recipes or attributes to a target data file.
HERE

  return join("\n", $preamble, $self->target_description, $self->options_description);
}

sub options {
  my ($self) = @_;
  return $self->data_options;
}

sub validate {
  my ($self, $opts, $args) = @_;
  my ($type, $name) = @$args;

  # validate type
  if ( ! length $type ) {
    $self->usage_error( "This command requires a target type and name" );
  }
  elsif ( $type ne 'node' ) {
    $self->usage_error( "Invalid type '$type'" );
  }

  # validate name
  if ( ! length $name ) {
    $self->usage_error( "This command requires the name for the thing to modify" );
  }

  return;
}

sub execute {
  my ($self, $opt, $args) = @_;

  my ($type, $name) = splice(@$args, 0, 2);

  if ( $type eq 'node' ) {
    my $node = $self->pantry->node( $name )
      or $self->usage_error( "Node '$name' does not exist" );

    if ($opt->{recipe}) {
      $node->append_to_run_list(map { "recipe[$_]" } @{$opt->{recipe}});
    }

    if ($opt->{default}) {
      for my $attr ( @{ $opt->{default} } ) {
        my ($key, $value) = split /=/, $attr, 2; # split on first '='
        if ( $value =~ /(?<!\\),/ ) {
          # split on unescaped commas, then unescape escaped commas
          $value = [ map { s/\\,/,/gr } split /(?<!\\),/, $value ];
        }
        $node->set_attribute($key, $value);
      }
    }

    $node->save;
  }

  return;
}

1;

=for Pod::Coverage options validate

=head1 SYNOPSIS

  $ pantry apply node foo.example.com --recipe nginx --default nginx.port=8080

=head1 DESCRIPTION

This class implements the C<pantry apply> command, which is used to apply recipes or attributes
to a node.

=cut

# vim: ts=2 sts=2 sw=2 et:
