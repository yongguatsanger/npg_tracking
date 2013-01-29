package npg_tracking::Schema::Result::InstrumentFormat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

npg_tracking::Schema::Result::InstrumentFormat

=cut

__PACKAGE__->table("instrument_format");

=head1 ACCESSORS

=head2 id_instrument_format

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 id_manufacturer

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 model

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 iscurrent

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 default_tiles

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 default_columns

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 days_between_washes

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 runs_between_washes

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id_instrument_format",
  {
    data_type => "bigint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "id_manufacturer",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "model",
  { data_type => "char", is_nullable => 1, size => 64 },
  "iscurrent",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "default_tiles",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "default_columns",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "days_between_washes",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "runs_between_washes",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id_instrument_format");

=head1 RELATIONS

=head2 instruments

Type: has_many

Related object: L<npg_tracking::Schema::Result::Instrument>

=cut

__PACKAGE__->has_many(
  "instruments",
  "npg_tracking::Schema::Result::Instrument",
  { "foreign.id_instrument_format" => "self.id_instrument_format" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 manufacturer

Type: belongs_to

Related object: L<npg_tracking::Schema::Result::Manufacturer>

=cut

__PACKAGE__->belongs_to(
  "manufacturer",
  "npg_tracking::Schema::Result::Manufacturer",
  { id_manufacturer => "id_manufacturer" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 instrument_utilisations

Type: has_many

Related object: L<npg_tracking::Schema::Result::InstrumentUtilisation>

=cut

__PACKAGE__->has_many(
  "instrument_utilisations",
  "npg_tracking::Schema::Result::InstrumentUtilisation",
  { "foreign.id_instrument_format" => "self.id_instrument_format" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 runs

Type: has_many

Related object: L<npg_tracking::Schema::Result::Run>

=cut

__PACKAGE__->has_many(
  "runs",
  "npg_tracking::Schema::Result::Run",
  { "foreign.id_instrument_format" => "self.id_instrument_format" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-07 09:30:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2hcs/wHffxBSBeO/Cz3oAA
# Author:        david.jackson@sanger.ac.uk
# Maintainer:    $Author: jo3 $
# Created:       2010-04-08
# Last Modified: $Date: 2010-09-13 18:21:28 +0100 (Mon, 13 Sep 2010) $
# Id:            $Id: InstrumentFormat.pm 10867 2010-09-13 17:21:28Z jo3 $
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/new-pipeline-dev/npg-tracking/trunk/lib/npg_tracking/Schema/Result/InstrumentFormat.pm $

use Readonly; Readonly::Scalar our $VERSION => do { my ($r) = q$LastChangedRevision: 10867 $ =~ /(\d+)/mxs; $r; };

1;

