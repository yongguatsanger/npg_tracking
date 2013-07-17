#########
# Author:        rmp
# Maintainer:    $Author: dj3 $
# Created:       2007-10
# Last Modified: $Date: 2012-01-30 14:59:22 +0000 (Mon, 30 Jan 2012) $
# Id:            $Id: 10-model-run_status_dict.t 15060 2012-01-30 14:59:22Z dj3 $
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/new-pipeline-dev/npg-tracking/trunk/t/10-model-run_status_dict.t $
#
use strict;
use warnings;
use t::util;
use npg::model::instrument;
use npg::model::user;
use npg::model::annotation;
use Test::More tests => 46;
use Test::Deep;

use_ok('npg::model::run_status_dict');

my $util = t::util->new({fixtures=>1});

{
  my $rsd = npg::model::run_status_dict->new({
					      util        => $util,
					      description => 'run pending',
					     });
  is($rsd->id_run_status_dict(), 1, 'load by description');
}

{
  my $rsd = npg::model::run_status_dict->new({
					      util        => $util,
					      id_run_status_dict => 22,
					     });
  is($rsd->description(), 'run stopped early', 'load by id');
}

{
  my $rsd = npg::model::run_status_dict->new({
					      util        => $util,
					      id_run_status_dict => 22,
					     });
  my $rsds = $rsd->run_status_dicts();

  isa_ok($rsds, 'ARRAY');
  is((scalar @{$rsds}), 24, 'all run status dicts');

}

{
  my $rsd = npg::model::run_status_dict->new({
					      util        => $util,
					      id_run_status_dict => 22,
					     });
  my $rsds = $rsd->run_status_dicts_sorted();
  my $rsds_length = scalar @{$rsds};

  isa_ok($rsds, 'ARRAY');
  is(($rsds_length), 21, 'all sorted run status dicts');

  my $ordered = [
           {
             'id_run_status_dict' => '1',
             'description' => 'run pending'
           },
           {
             'id_run_status_dict' => '2',
             'description' => 'run in progress'
           },
           {
             'id_run_status_dict' => '3',
             'description' => 'run on hold'
           },
           {
             'id_run_status_dict' => '5',
             'description' => 'run cancelled'
           },
           {
             'id_run_status_dict' => '22',
             'description' => 'run stopped early'
           },
           {
             'id_run_status_dict' => '4',
             'description' => 'run complete'
           },
           {
             'id_run_status_dict' => '11',
             'description' => 'run mirrored'
           },
           {
             'id_run_status_dict' => '6',
             'description' => 'analysis pending'
           },
           {
             'id_run_status_dict' => '10',
             'description' => 'analysis cancelled'
           },
           {
             'id_run_status_dict' => '21',
             'description' => 'data discarded'
           },
           {
             'id_run_status_dict' => '8',
             'description' => 'analysis on hold'
           },
           {
             'id_run_status_dict' => '7',
             'description' => 'analysis in progress'
           },
           {
             'id_run_status_dict' => '24',
             'description' => 'secondary analysis in progress'
           },
           {
             'id_run_status_dict' => '9',
             'description' => 'analysis complete'
           },
           {
             'id_run_status_dict' => '19',
             'description' => 'qc review pending'
           },
           {
             'id_run_status_dict' => '26',
             'description' => 'qc in progress'
           },
           {
             'id_run_status_dict' => '25',
             'description' => 'qc on hold'
           },
           {
             'id_run_status_dict' => '17',
             'description' => 'archival pending'
           },
           {
             'id_run_status_dict' => '18',
             'description' => 'archival in progress'
           },
           {
             'id_run_status_dict' => '12',
             'description' => 'run archived'
           },
           {
             'id_run_status_dict' => '20',
             'description' => 'qc complete'
           }
         ];

  is(scalar @{$ordered}, 21, 'Only want current run status values');
  
  for (my $index = 0; $index < $rsds_length; $index++){
    my $status = @{$rsds}[$index]->{description};
    my $expected_status = @{$ordered}[$index]->{description};
    is($status, $expected_status, "Status $status is in correct order");
  }

}

{
  my $rsd = npg::model::run_status_dict->new({
					      util        => $util,
					      description => 'analysis complete',
					     });
  my $runs = $rsd->runs();
  isa_ok($runs, 'ARRAY');
  is((scalar @{$runs}), 2, 'unprimed cache runs');

  my $runs2 = $rsd->runs();
  isa_ok($runs2, 'ARRAY');
  is((scalar @{$runs2}), 2, 'primed cache runs');
}

{
  my $rsd = npg::model::run_status_dict->new({
					      util               => $util,
					      id_run_status_dict => 11,
					     });
  my $first_two = $rsd->runs({len => 2});
  is((scalar @{$first_two}),     2, 'first two runs for id_rsd 11');
  is($first_two->[0]->id_run(), 12, 'first run id for id_rsd 11');
  is($first_two->[1]->id_run(), 11, 'second run id ');

  my $second_two = $rsd->runs({
			       len   => 2,
			       start => 1,
			      });
  is((scalar @{$second_two}),     2, 'second two runs for id_rsd 11');
  is($second_two->[0]->id_run(), 11, 'second run id');
  is($second_two->[1]->id_run(), 5,  'third run id');

  is((scalar @{$rsd->runs()}), 3, 'run list unmodified');
}

{
  my $rsd = npg::model::run_status_dict->new({
					      util        => $util,
					      description => 'analysis complete',
					     });
  my $count_runs = $rsd->count_runs();
  is($count_runs, 2, 'unprimed cache count_runs - analysis complete - all formats');
  is($count_runs, 2, 'primed cache count_runs - analysis complete - all formats');
}
{

  my $rsd = npg::model::run_status_dict->new({
					      util        => $util,
					      description => 'run complete',
					     });

  my $count_runs = $rsd->count_runs( {
    id_instrument_format => 10,
  } );
  is($count_runs, 3, 'unprimed cache count_runs(3) - run complete - id_instrument_format = 10');
  is($count_runs, 3, 'primed cache count_runs(3) - run complete - id_instrument_format = 10');

  $count_runs = $rsd->count_runs( {
    id_instrument_format => 7,
  } );
  is($count_runs, 1, 'unprimed cache count_runs(1) - run complete - id_instrument_format = 7');
  is($count_runs, 1, 'primed cache count_runs(1) - run complete - id_instrument_format = 7');

}
