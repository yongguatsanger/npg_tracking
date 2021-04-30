package Monitor::Roles::Cycle;

use Moose::Role;
use Carp;
use List::Util qw(max);
use Perl6::Slurp;

our $VERSION = '0';

# The transfer of Events.log can lag far behind actual image transfer.
sub get_latest_cycle {
    my ( $self, $run_path ) = @_;

    my @cycle_numbers = $self->_cycle_numbers( $run_path );

    my $status_latest = 0;
    if ( $self->can( q{runfolder_path} ) ) {
      $run_path ||= $self->runfolder_path();
    }

    $self->_cycle_numbers( $run_path, 1 );

    return max( @cycle_numbers, $status_latest, 0 );
}

sub missing_cycles {
  my ( $self, $run_path ) = @_;

  my @cycle_numbers = $self->_cycle_numbers( $run_path );

  my $previous;
  my @missing_cycles;
  foreach my $cycle ( @cycle_numbers ) {
    if ( ! defined $previous || $cycle == $previous + 1 ) {
      $previous = $cycle;
      next;
    }

    foreach my $missing_cycle ( ($previous + 1) .. ($cycle - 1) ) {
      push @missing_cycles, $missing_cycle;
    }
    $previous = $cycle;
  }

  $self->_cycle_numbers( $run_path, 1 );

  return @missing_cycles;
}

sub _cycle_numbers {
  my ( $self, $run_path, $delete ) = @_;

  if ( $self->can( q{runfolder_path} ) ) {
    $run_path ||= $self->runfolder_path();
  }

  # Can't we 'require' this?
  croak q{Run folder not supplied} if !$run_path;

  if ( ! $self->{_cycle_numbers} ) {
    $self->{_cycle_numbers} = {};
  }

  if ( $delete ) {
    delete $self->{_cycle_numbers}->{$run_path};
    return;
  }

  if ( $self->{_cycle_numbers}->{$run_path} ) {
    return @{ $self->{_cycle_numbers}->{$run_path} };
  }

  # We assume that there will always be a lane 1 here. So far this has been
  # safe.
  my @thumbnail_dirs = glob $run_path . '/Thumbnail_Images/L001/C*';
  my @img_cycle_dirs = map { ( $_ =~ m{ L001/C (\d+) [.]1 $}gmsx ) } @thumbnail_dirs;

  my @intensities_dirs = glob $run_path . '/Data/Intensities/L001/C*';
  my @cycle_dirs = map { ( $_ =~ m{ L001/C (\d+) [.]1 $}gmsx ) } @intensities_dirs;
  if ( ! @cycle_dirs) { # fallback when no cifs copied
    @intensities_dirs = glob $run_path . '/Data/Intensities/BaseCalls/L001/C*';
    @cycle_dirs = map { ( $_ =~ m{ L001/C (\d+) [.]1 $}gmsx ) } @intensities_dirs;
  }

  if ( scalar @img_cycle_dirs > scalar @cycle_dirs ) {
    @cycle_dirs = @img_cycle_dirs;
  }

  # guarantee that we return found cycles in numerical order
  my @cycle_numbers = sort { (sprintf q{%04d}, $a) <=> (sprintf q{%04d}, $b) } @cycle_dirs;

  $self->{_cycle_numbers}->{$run_path} = \@cycle_numbers;

  return @{ $self->{_cycle_numbers}->{$run_path} };
}

sub delay {
  my ( $self ) = @_;

  my $run_actual_cycles = $self->tracking_run()->actual_cycle_count();

  my $latest_cycle = $self->get_latest_cycle();

  my $delay = 0;

  if ( $run_actual_cycles != $latest_cycle ) {
    $delay = $run_actual_cycles - $latest_cycle;
    $delay =~ s/-//xms;
  }

  $delay += scalar $self->missing_cycles();

  return $delay;
}

1;


__END__


=head1 NAME

Monitor::Roles::Cycle - establish the lastest run cycle from a run folder on
local staging.

=head1 VERSION


=head1 SYNOPSIS

A role for use by Monitor::Staging and Monitor::SRS::Local

    C<<use Moose;
       with 'Monitor::Roles::Cycle';>>

=head1 DESCRIPTION

Work out what the latest cycle is for a run by rooting through the staging
area.

=head1 SUBROUTINES/METHODS

=head2 get_latest_cycle

Return the highest cycle number for lane 1.

=head2 missing_cycles

Goes through all the cycle directories present for lane 1, and then returns any missing cycles
(as if mirroring to stagung is playing catchup, some directories may be missing)

  my @MissingCycles = $oClass->missing_cycles( $run_path );

=head2 delay

The number of cycles that are delayed coming across from the instrument
actual last cycle recorded - highest cycle found on staging

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Carp

=item List::Util

=item Perl6::Slurp

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

We assume that there will always be a lane 1.

=head1 AUTHOR

John O'Brien
Marina Gourtovaia

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013,2014,2015,2018,2019,2020 Genome Research Ltd.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
