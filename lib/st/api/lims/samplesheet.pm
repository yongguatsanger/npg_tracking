package st::api::lims::samplesheet;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Carp;
use File::Slurp;
use Readonly;
use URI::Escape qw(uri_unescape);
use open q(:encoding(UTF8));
use List::MoreUtils qw(any);

use npg_tracking::util::types;
use st::api::lims;
with qw/  
          npg_tracking::glossary::run
          npg_tracking::glossary::lane
          npg_tracking::glossary::tag
       /;

our $VERSION = '0';

=head1 NAME

st::api::lims::samplesheet

=head1 SYNOPSIS

=head1 DESCRIPTION

LIMs parser for the Illumina-style extended samplesheet

=head1 SUBROUTINES/METHODS

=cut

Readonly::Scalar  our $SAMPLESHEET_RECORD_SEPARATOR => q[,];
Readonly::Scalar  our $SAMPLESHEET_ARRAY_SEPARATOR  => q[ ];
Readonly::Scalar  our $SAMPLESHEET_HASH_SEPARATOR   => q[:];
Readonly::Scalar  my  $NOT_INDEXED_FLAG             => q[NO_INDEX];
Readonly::Scalar  my  $RECORD_SPLIT_LIMIT           => -1;
Readonly::Scalar  my  $DATA_SECTION                 => q[Data];
Readonly::Scalar  my  $HEADER_SECTION               => q[Header];

###################################################################
#################  Public attributes  #############################
###################################################################

=head2 path

Samplesheet path

=cut

has 'path' => (
                  isa => 'NpgTrackingReadableFile',
                  is  => 'ro',
                  required => 1,
                  builder  => '_build_path',
                  lazy     => 1,
);

sub _build_path {
  return $ENV{$st::api::lims::CACHED_SAMPLESHEET_FILE_VAR_NAME};
}

=head2 id_run

Run id, optional attribute.

=cut

has '+id_run'   =>        (required        => 0, writer => '_set_id_run',);

=head2 position

Position, optional attribute.

=cut

has '+position' =>        (required        => 0,);

=head2 tag_index

Tag index, optional attribute.

=head2 data

Hash representation of LIMS data

=cut
has 'data' => (
                  isa => 'HashRef',
                  is  => 'ro',
                  lazy => 1,
                  builder => '_build_data',
                  trigger => \&_validate_data,
               );
sub _build_data {
  my $self = shift;

  my @lines = read_file($self->path);
  my $d = {};
  my $current_section = q[];
  my @data_columns = ();
  my $id_run_column_present = 0;

  foreach my $line (@lines) {

    $line or next;
    $line =~ s/\s+$//mxs;
    $line or next;

    my @columns = split $SAMPLESHEET_RECORD_SEPARATOR, $line, $RECORD_SPLIT_LIMIT;
    my @empty = grep {(!defined $_ || $_ eq q[] || $_ =~ /^\s+$/smx)} @columns;
    scalar @empty != scalar @columns or next;

    my $section;
    if ( ($section) = $columns[0] =~ /^\[(\w+)\]$/xms) {
      $current_section = $section;
      $d->{$current_section} = undef;
      next;
    }

    if ($current_section eq 'Data') {

      if (!@data_columns) {
        @data_columns = @columns;
        $id_run_column_present = $self->_assign_id_run($d, @columns);
        next;
      }

      my $row = {'Lane' => 1,};
      foreach my $i (0 .. $#columns) {
        $row->{$data_columns[$i]} = $columns[$i];
      }

      my @lanes = split /\+/smx, $row->{'Lane'};
      delete $row->{'Lane'};

      my $id_run = delete $row->{'id_run'};
      not $id_run and $id_run_column_present and croak 'No value in the id_run column';
      $id_run ||= $self->_get_id_run();

      my $current_num_indexes = $d->{$current_section}->{$id_run}->{$lanes[0]} ?
        scalar keys %{$d->{$current_section}->{$id_run}->{$lanes[0]}} : 0;
      my $index = $self->_parse_index($row, $current_num_indexes);

      # There might be no index column header or the value might be undefined
      foreach my $lane (@lanes) { #give all lanes explicitly
        if (exists $d->{$current_section}->{$id_run}->{$lane}->{$index}) {
          croak "Multiple $current_section section definitions for lane $lane index $index";
        }
        $d->{$current_section}->{$id_run}->{$lane}->{$index} = $row;
      }

    } elsif ($current_section eq 'Reads') {

      my @reads = grep { $_ =~/\d+/smx} @columns;
      @reads or next;
      scalar @reads == 1 or croak 'Multiple read lengths in one row';

      if (!exists $d->{$current_section}) {
        $d->{$current_section} = [$reads[0]];
      } else {
        push @{$d->{$current_section}}, $reads[0];
      }

    } else {
      my @row = grep { defined $_ && ($_ ne q[]) } @columns;
      if (scalar @row > 2) {
        croak "More than two columns defined in one row in section $current_section";
      }
      $d->{$current_section}->{$row[0]} = $row[1];
    }
  }

  if (scalar keys %{$d->{$DATA_SECTION}} > 1) {
    $self->_validate_input4multiple_runs($d);
  }

  return $d;
}

=head2 is_pool

Read-only boolean accessor, not possible to set from the constructor.
True for a pooled lane on a lane level or tag zero, otherwise false.

=cut
has 'is_pool' =>          (isa             => 'Bool',
                           is              => 'ro',
                           init_arg        => undef,
                           lazy_build      => 1,
                          );
sub _build_is_pool {
  my $self = shift;
  if (scalar keys %{$self->data->{$DATA_SECTION}} > 1) {
    return 0;
  }
  if ( $self->position && !$self->tag_index && #lane level or tag zero
      (!exists $self->data->{$DATA_SECTION}->{$self->_get_id_run()}->{$self->position}->{$NOT_INDEXED_FLAG}) ) {
    return 1;
  }
  return 0;
}

=head2 spiked_phix_tag_index

Read-only integer accessor, not possible to set from the constructor.
Defined for a lane and all tags, including tag zero

=cut
has 'spiked_phix_tag_index' =>  (isa             => 'Maybe[NpgTrackingTagIndex]',
                                 is              => 'ro',
                                 init_arg        => undef,
                                 lazy_build      => 1,
                                );
sub _build_spiked_phix_tag_index {
  my $self = shift;
  if (!$self->position) {
    return;
  }
  if ($self->is_pool) { #this covers the lane level and tag zero
    my @controls = grep {$_->is_control } @{$self->_sschildren};
    my $num_controls = scalar @controls;
    if ($num_controls) {
      if( $num_controls > 1) {
        croak qq[$num_controls controls in lane];
      }
      return $controls[0]->tag_index;
    }
  } else {
    my $index = $self->tag_index ? $self->tag_index : $NOT_INDEXED_FLAG;
    return $self->data->{$DATA_SECTION}->{$self->_get_id_run()}->{$self->position}->{$index}->{'spiked_phix_tag_index'} || undef;
  }
  return;
}

###################################################################
#################  Public methods  ################################
###################################################################

=head2 BUILD

Validates attributes given to the constructor against data

=cut

sub BUILD {
  my $self = shift;
  my $id_run = $self->_get_id_run();
  if ($self->position && !exists $self->data->{$DATA_SECTION}->{$id_run}->{$self->position}) {
    croak sprintf 'Position %s not defined in %s', $self->position, $self->path;
  }
  if ($self->tag_index && !exists $self->data->{$DATA_SECTION}->{$id_run}->{$self->position}->{$self->tag_index}) {
    croak sprintf 'Tag index %s not defined in %s', $self->tag_index, $self->path;
  }
  return;
}

=head2 children

Method returning a list objects that are associated with this object
and belong to the next (one lower) level. An empty list for a non-pool lane and for a plex.
For a pooled lane and tag zero contains plex-level objects. On a run level, when the position 
accessor is not set, returns lane level objects.

=cut

sub children {
  my $self = shift;
  return @{$self->_sschildren()};
}

=head2 to_string

Human friendly description of the object

=cut

sub to_string {
  my $self = shift;
  my $s = __PACKAGE__ . q[, path ] . $self->path;
  if (defined $self->id_run) {
    $s .= q[ id_run ] . $self->id_run;
  }
  if (defined $self->position) {
    $s .= q[ position ] . $self->position;
  }
  if (defined $self->tag_index) {
    $s .= q[ tag_index ] . $self->tag_index;
  }
  return $s;
}

#####
#
# Dynamically create standard driver methods as defined in st::api::lims
# in the driver_method_list_short class method.
#

for my $m ( st::api::lims->driver_method_list_short(__PACKAGE__->meta->get_attribute_list) ) {

  __PACKAGE__->meta->add_method( $m, sub {
        my $self=shift;
        if ($self->_data_row) {
          my $column_name = $m;
          if ($m eq 'library_id') {
            $column_name = 'Sample_ID';
          } elsif ($m eq 'sample_name' && (!exists $self->_data_row->{$column_name}) ) {
            $column_name = 'Sample_Name';
          }
          my $value =  $self->_data_row->{$column_name};
          if (defined $value && $value eq q[]) {
            $value = undef;
          }
          if ($m =~ /s$/smx) {
            my @temp = $value ? split $SAMPLESHEET_ARRAY_SEPARATOR, $value : ();
            $value = \@temp;
          } elsif ($m eq 'required_insert_size_range') {
            my $h = {};
            if ($value) {
              my @temp = split $SAMPLESHEET_ARRAY_SEPARATOR, $value;
              foreach my $pair (@temp) {
                my ($key, $val) = split $SAMPLESHEET_HASH_SEPARATOR, $pair;
                $h->{$key} = $val;
              }
            }
            $value = $h;
          } else {
            if ($value) {
              $value = uri_unescape($value);
              if ( not utf8::is_utf8($value)) {
                utf8::decode($value) or croak "Cannot decode $value to UTF8";
              }
            }
          }
          return $value;
        }
        return;
  });
}

###################################################################
#################  Private attributes  ############################
###################################################################

has '_data_row' =>        (isa             => 'Maybe[HashRef]',
                           is              => 'ro',
                           init_arg        => undef,
                           lazy_build      => 1,
                          );
sub _build__data_row {
  my $self = shift;

  my $run_data = $self->data->{$DATA_SECTION}->{$self->_get_id_run()};
  if ($self->position) {
    if ($self->tag_index) {
      my $data = $run_data->{$self->position}->{$self->tag_index};
      if (!defined $data) {
        croak sprintf 'Tag index %s not defined for %s',
                    $self->tag_index, $self->to_string;
      }
      return $data;
    }
    if (!defined $self->tag_index &&
           exists $run_data->{$self->position}->{$NOT_INDEXED_FLAG}) {
      return $run_data->{$self->position}->{$NOT_INDEXED_FLAG};
    }
  }

  return; #nothing on run level, lane-level pool or tag zero
}

has '_sschildren' =>      (isa             => 'ArrayRef',
                           is              => 'ro',
                           init_arg        => undef,
                           clearer         => 'free_children',
                           lazy_build      => 1,
                          );
sub _build__sschildren {
  my $self = shift;

  my @children = ();

  # Do not create children if data for multiple runs are present.
  (scalar keys %{$self->data->{$DATA_SECTION}} > 1) && return \@children;

  my $child_attr_name;
  if ($self->position) {
    if ($self->is_pool) { # lane level pool and tag zero - return plexes
      $child_attr_name = 'tag_index';
    }
  } else { # run level - return lanes
    $child_attr_name = 'position';
  }

  if ($child_attr_name) {
    my $h = $self->data->{$DATA_SECTION}->{$self->_get_id_run()};
    if ($child_attr_name eq 'tag_index') {
      $h = $h->{$self->position};
    }

    my $init = {};
    foreach my $init_attr (qw/id_run path/) {
      if ($self->$init_attr) {
        $init->{$init_attr} = $self->$init_attr;
      }
    }
    if ($child_attr_name eq 'tag_index') {
      $init->{'position'} = $self->position;
    }

    foreach my $attr_value (sort {$a <=> $b} keys %{$h}) {
      $init->{$child_attr_name} = $attr_value;
      $init->{'data'}           = $self->data;
      push @children, __PACKAGE__->new($init);
    }
  }

  return \@children;
}

###################################################################
#################  Private methods  ###############################
###################################################################

sub _assign_id_run {
  my ($self, $d, @data_columns) = @_;

  my $id_run_column_present = any { $_ eq 'id_run' } @data_columns;

  if (not $self->id_run) {
    $id_run_column_present and croak q[id_run column is present in a samplesheet,] .
      q[ id_run attribute should be set];
    my $en = _id_run_from_header($d);
    if ($en) {
      $self->_set_id_run($en);
      carp qq[id_run is set to Experiment Name, $en];
    }
  }

  return $id_run_column_present;
}

sub _parse_index {
  my ($self, $row, $current_num_indexes) = @_;

  if (not exists $row->{'default_tag_sequence'}) { #use custom NPG column if provided
    if ($row->{'Index'}) {
      $row->{'default_tag_sequence'} = $row->{'Index'};
      delete $row->{'Index'};
      if ($row->{'Index2'}) {
        $row->{'default_tagtwo_sequence'} = $row->{'Index2'};
        delete $row->{'Index2'};
      }
    }
  }

  my $index = $row->{'tag_index'};
  if ($index) {
    delete $row->{'tag_index'};
  } elsif ($row->{'default_tag_sequence'}) {
    $index = $current_num_indexes + 1;
  } else {
    $index = $NOT_INDEXED_FLAG;
  }

  return $index;
}

sub _validate_data { # this is a callback for Moose trigger
                     # $old_data might not be set
  my ( $self, $data, $old_data ) = @_;

  if (!exists $data->{$DATA_SECTION}) {
    croak "$DATA_SECTION section is missing";
  }

  my $id_run = _id_run_from_header($data);
  if ($id_run && $self->id_run && $id_run != $self->id_run) {
    carp sprintf 'Supplied id_run %i does not match Experiment Name, %s',
                  $self->id_run, $id_run;
  }

  return;
}

sub _id_run_from_header {
  my $data = shift;
  return $data->{$HEADER_SECTION}->{'Experiment Name'};
}

sub _get_id_run {
  my $self = shift;
  return $self->id_run ? $self->id_run : q[NO_ID_RUN];
}

sub _validate_input4multiple_runs {
  my ($self, $d) = @_;
  my $m = join q[ ], 'Samplesheet', $self->path, 'with data for multiple runs, ';
  $self->position or
    croak $m . 'position attribute should be set';
  (defined $self->tag_index) and ($self->tag_index == 0) and
    croak $m . 'not possible to get data for tag zero';
  (not defined $self->tag_index) and
  (not exists $d->{$DATA_SECTION}->{$self->id_run}->{$self->position}->{$NOT_INDEXED_FLAG}) and
    croak $m . 'pool data not available';
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::StrictConstructor

=item namespace::autoclean

=item Carp

=item Readonly

=item File::Slurp

=item URI::Escape

=item open

=item List::MoreUtils

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2019 Genome Research Ltd.

This file is part of NPG.

NPG is free software: you can redistribute it and/or modify
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
