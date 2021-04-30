use strict;
use warnings;
use Test::More tests => 7;
use Crypt::CBC;
use MIME::Base64;

my @imports = qw/sanger_cookie_name sanger_username/;
use_ok('npg::authentication::sanger_sso', @imports);
can_ok('npg::authentication::sanger_sso', @imports);

is(sanger_cookie_name(), 'WTSISignOn', 'sanger cookie name');
is(sanger_username(), q[], 'empty string returned if neither the cookie nor key is given');
is(sanger_username('cookie'), q[], 'empty string returned if the  key is not given');
is(sanger_username(undef, 'mykey'), q[], 'empty string returned if the cookie is not given');

my $key = Crypt::CBC->random_bytes(56);
my $crypt = Crypt::CBC->new(
  -pass    => $key,
  -pbkdf   => q[pbkdf2],
  -cipher  => q[Blowfish],
  -padding => q[space]);

my $text = 'Thisdataishushhush';
my $ciphertext = $crypt->encrypt(q[<<<<] . $text);

is(sanger_username(encode_base64($ciphertext), $key), $text,
  'text is decrypted correctly');

1;
