use utf8;
package npg_tracking::Schema::Result::Annotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

npg_tracking::Schema::Result::Annotation

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<annotation>

=cut

__PACKAGE__->table("annotation");

=head1 ACCESSORS

=head2 id_annotation

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 id_user

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 0

=head2 attachment_name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 attachment

  data_type: 'longblob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id_annotation",
  {
    data_type => "bigint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "id_user",
  {
    data_type => "bigint",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "comment",
  { data_type => "text", is_nullable => 0 },
  "attachment_name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "attachment",
  { data_type => "longblob", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_annotation>

=back

=cut

__PACKAGE__->set_primary_key("id_annotation");

=head1 RELATIONS

=head2 instrument_annotations

Type: has_many

Related object: L<npg_tracking::Schema::Result::InstrumentAnnotation>

=cut

__PACKAGE__->has_many(
  "instrument_annotations",
  "npg_tracking::Schema::Result::InstrumentAnnotation",
  { "foreign.id_annotation" => "self.id_annotation" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 instrument_status_annotations

Type: has_many

Related object: L<npg_tracking::Schema::Result::InstrumentStatusAnnotation>

=cut

__PACKAGE__->has_many(
  "instrument_status_annotations",
  "npg_tracking::Schema::Result::InstrumentStatusAnnotation",
  { "foreign.id_annotation" => "self.id_annotation" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 run_annotations

Type: has_many

Related object: L<npg_tracking::Schema::Result::RunAnnotation>

=cut

__PACKAGE__->has_many(
  "run_annotations",
  "npg_tracking::Schema::Result::RunAnnotation",
  { "foreign.id_annotation" => "self.id_annotation" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 run_lane_annotations

Type: has_many

Related object: L<npg_tracking::Schema::Result::RunLaneAnnotation>

=cut

__PACKAGE__->has_many(
  "run_lane_annotations",
  "npg_tracking::Schema::Result::RunLaneAnnotation",
  { "foreign.id_annotation" => "self.id_annotation" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user

Type: belongs_to

Related object: L<npg_tracking::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "npg_tracking::Schema::Result::User",
  { id_user => "id_user" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2014-02-20 10:43:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fw1PGLynbasn+IKgeZzzTw

# Author:        david.jackson@sanger.ac.uk
# Created:       2010-04-08

our $VERSION = '0';

=head2 username

Username corresponding to the object returned bu the user relationship.

=cut
sub username {
  my $self = shift;
  return $self->user()->username();
}

=head2 date_as_string

=cut
sub date_as_string {
  my $self = shift;
  return $self->date()->strftime('%F %T');
}

__PACKAGE__->meta->make_immutable;
1;
