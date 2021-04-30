use strict;
use warnings;
use t::util;
use Test::More tests => 17;
use Test::Exception;

our $IF = 'npg::model::instrument_format';

use_ok('npg::model::instrument');
use_ok($IF);

my $util = t::util->new({fixtures => 1});

{
  my $if = $IF->new({
         util => $util,
        });
  isa_ok($if, $IF);
}

{
  my $if = $IF->new({
         util => $util,
        });
  my $cifs = $if->current_instrument_formats();
  isa_ok($cifs, 'ARRAY');
  is((scalar @{$cifs}), 7, 'unprimed cache cif');
  is((scalar @{$if->current_instrument_formats()}), 7, 'primed cache cif');
  my $name;
  lives_ok {$if->manufacturer_name},
    'no error calling manufacturer_name on an object used in list context';
  is($name, undef, 'manufacturer name is undefined');
}

{
  my $if = $IF->new({
         util => $util,
         id_instrument_format => 4,
        });
  my $is = $if->instruments();
  isa_ok($is, 'ARRAY');
  is((scalar @{$is}), 13, 'instruments');
  is($if->manufacturer_name, 'Illumina', 'correct manufacturer name');
}

{
  my $if = $IF->new({
         util => $util,
         id_instrument_format => 4,
        });
  my $cis = $if->current_instruments();
  isa_ok($cis, 'ARRAY');
  is((scalar @{$cis}), 12, 'unprimed cache current_instruments');
  is((scalar @{$if->current_instruments}), 12, 'primed cache current_instruments');
}

{
  my $if = $IF->new({
         util => $util,
         id_instrument_format => 4,
        });
  my $ic = $if->current_instruments_count();
  is($ic, 12, 'current instrument count');
}


our $INS = q{npg::model::instrument};

{
  my $if = $IF->new();
  my $if_hk = $IF->new({
    model => q{HK},
    current_instruments => [
      $INS->new({ name => q{GA3} }),
      $INS->new({ name => q{GA1} }),
      $INS->new({ name => q{GA38} }),
    ],
  });
  my $if_hs = $IF->new({
    model => q{HiSeq},
    current_instruments => [
      $INS->new({ name => q{HS5} }),
      $INS->new({ name => q{HS7} }),
      $INS->new({ name => q{HS17} }),
    ],
  });
  $if->{current_instrument_formats} = [$if_hk, $if_hs];
  my $cur_inst_by_format = $if->current_instruments_by_format();
  is( $cur_inst_by_format, $if->current_instruments_by_format(), q{cache current_instruments_by_format} );

  my $expected_result = {
    q{GA-II} => [ qw{GA1 GA3 GA38} ],
    HiSeq    => [ qw{HS5 HS7 HS17} ],
  };
  my $obtained = {};
  foreach my $key ( keys %{ $cur_inst_by_format } ) {
    $obtained->{$key} = [];
    foreach my $inst ( @{ $cur_inst_by_format->{$key} } ) {
      push @{ $obtained->{$key} }, $inst->name();
    }
  }
  is_deeply( $obtained, $expected_result, q{instruments ordered by name} );
}

1;
