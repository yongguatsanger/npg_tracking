package reference;

use strict;
use warnings;
use Test::More tests => 22;
use Test::Exception;
use npg_testing::intweb qw(npg_is_accessible);

use_ok('npg_tracking::data::reference');
use_ok('npg_tracking::data::bait');
use npg_tracking::data::reference::list;

my $REP_ROOT=$npg_tracking::data::reference::list::REP_ROOT;
my $PHIX_FILE=$REP_ROOT.q{references/PhiX/Sanger-SNPs/all/fasta/phix_unsnipped_short_no_N.fa}; 

{
SKIP: {

  if (!npg_is_accessible()) {
    skip 'Internal Sanger website is not accessible', 20;
  }
  if (!-e $REP_ROOT) {
    skip 'reference repository is not accessible', 20;
  }
  my $r = npg_tracking::data::reference->new(id_run => 4354,position=>1);
  is(join(q[ ], @{$r->refs}), 
     $REP_ROOT . q[references/Salmonella_enterica/Typhimurium_LT2/all/fasta/Salmonella_typimurium_LT2.fasta],
     'reference for run 4354 lane 1');

  $r = npg_tracking::data::reference->new(id_run => 4350,position=>5);
  is(join(q[ ], @{$r->refs}), 
     $REP_ROOT . q[references/Neisseria_meningitidis/MC58/all/fasta/N_meningitidis_MC58.fasta],
     'reference for run 4350 lane 5');

  $r = npg_tracking::data::reference->new(id_run => 4415,position=>4);
  is(join(q[ ], @{$r->refs}), 
     $PHIX_FILE,
     'reference for run 4415 lane 4');

  $r = npg_tracking::data::reference->new(id_run => 4710,position=>3);
  my @refs =  @{$r->refs};
  is (scalar @refs, 1, 'one ref for run 4710 lane 3');
  my @expected =  $REP_ROOT . qw{
   references/Human_herpesvirus_4/Wild_type/all/fasta/Hhv4_wild_type.fasta
  };
  is(join(q[ ], sort @refs), join(q[ ], @expected), 'reference for run 4710 lane 3');

  $r = npg_tracking::data::reference->new(id_run => 5082, position=>6);
  is (scalar @{$r->refs}, 0, 'no refs for run 5082 lane 6');
  $r = npg_tracking::data::reference->new(id_run => 5082,position=>4);
  is(join(q[ ], @{$r->refs}), 
     $PHIX_FILE,
     'reference for run 4415 lane 4');

 
  $r = npg_tracking::data::reference->new(id_run => 4784,position=>8);
  is (scalar @{$r->refs}, 0, 'no refs for run 4784 position 8');

  $r = npg_tracking::data::reference->new(id_run => 5175,position=>1);
  @refs =  @{$r->refs};
  is(join(q[ ], @refs), 
     $REP_ROOT . q[references/Streptococcus_pneumoniae/ATCC_700669/all/fasta/S_pneumoniae_700669.fasta],
     'reference for run 5175 lane 1 through the reference genome field');

  $r = npg_tracking::data::reference->new(id_run => 5970,position=>1);
  is ($r->refs->[0], $REP_ROOT . 'references/Anopheles_gambiae/PEST/all/fasta/agambiae.CHROMOSOMES-PEST.AgamP3.fasta', 'lane refs');

  $r = npg_tracking::data::reference->new(id_run => 5970,position=>1, tag_index=>168);
  throws_ok {$r->refs} qr/No plexes defined for lane 1 in batch 9659/, 'error if using tag_index 168 in the contex of not-pool library';
  $r = npg_tracking::data::reference->new(id_run => 5970,position=>1, for_spike => 1);
  is ($r->refs->[0], $PHIX_FILE, 'spiked phix ref');
  $r = npg_tracking::data::reference->new(id_run => 5970,position=>6, tag_index=>888);
  is ($r->refs->[0], $PHIX_FILE, 'spiked phix ref');

  $r = npg_tracking::data::reference->new(id_run => 5970,position=>4);
  is ($r->refs->[0], $PHIX_FILE, 'control phix ref');

  $r = npg_tracking::data::reference->new(id_run => 6009,position=>1);
  is ($r->refs->[0], $REP_ROOT . 'references/Homo_sapiens/1000Genomes/all/fasta/human_g1k_v37.fasta', 'lane ref from the correct study');

  $r = npg_tracking::data::reference->new(id_run => 6009,position=>7, tag_index=>7);
  is ($r->refs->[0], $REP_ROOT . 'references/Homo_sapiens/1000Genomes/all/fasta/human_g1k_v37.fasta', 'tag ref from the correct study');

  is(npg_tracking::data::bait->new(id_run=>8043, position=>3, tag_index=>1)->bait_path,
   $r->bait_repository . '/Human_all_exon_50MB/1000Genomes_hs37d5', 'baits path');      

  lives_ok {$r->repository_contents} 'repository listing performed';
  my $report;
  lives_ok {$report = $r->report} 'report generated';
  #diag $report;
  lives_ok {$report = $r->short_report} 'short report generated';
  #diag $report;
}
}
