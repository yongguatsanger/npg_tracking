package npg_tracking::daemon::jenkins;

use Moose;
use Carp;
use Readonly;
use FindBin qw($Bin);
FindBin::again();

use npg_tracking::util::types;
extends 'npg_tracking::daemon';

our $VERSION = '0';

Readonly::Scalar our $PROXY_SERVER     => q[wwwcache.sanger.ac.uk];
Readonly::Scalar our $PROXY_PORT       => 3128;
Readonly::Scalar our $JENKINS_PORT     => 9960;
Readonly::Scalar our $TIMEOUT_HOURS    => 6;
Readonly::Scalar our $MINUTES_PER_HOUR => 60;

Readonly::Scalar our $SSH_PK_FILENAME   => q[key.pem];
Readonly::Scalar our $SSH_CERT_FILENAME => q[server.pem];


has 'session_timeout' => ('is'        => 'ro',
                          'isa'       => 'NpgTrackingPositiveInt',
                          'required'  => 0,
                          'default'   => $MINUTES_PER_HOUR * $TIMEOUT_HOURS,
                          'predicate' => 'has_session_timeout',
                          'clearer'   => 'clear_session_timeout',);

override '_build_hosts'    => sub { return ['sf2-farm-srv2']; };
override '_build_env_vars' => sub { return {'http_proxy' => qq[http://$PROXY_SERVER:$PROXY_PORT]}; };

has 'npg_ssl_home' => ('is'         => 'ro',
                       'isa'        => 'NpgTrackingDirectory',
                       'required'   => 0,
                       'lazy_build' => 1, );
sub _build_npg_ssl_home {
  my $self = shift;
  my $npg_ssl_home = $ENV{'NPG_SSL_HOME'};
  if (!$npg_ssl_home) {
    $npg_ssl_home = join q[/], $Bin, q[..], 'wtsi_local';
  }
  return $npg_ssl_home;
}

has 'jenkins_war' => ('is'         => 'ro',
                      'isa'        => 'NpgTrackingReadableFile',
                      'required'   => 0,
                      'lazy_build' => 1, );

sub _build_jenkins_war {
  my $sub = shift;
  my $home = $ENV{'HOME'};
  if (!$home) {
    croak 'User home is not defined';
  }
  return join q[/], $home, q[jenkins.war];
}

# We assume that $JENKINS_HOME is the same both where the daemon monitor is run and the jenkins server is started.
override 'command'  => sub {
  my ($self, $host) = @_;

  my $tmpdir = $ENV{'JENKINS_HOME'} ? "-Djava.io.tmpdir=$ENV{'JENKINS_HOME'}/tmp" : q[];
  my $npg_ssl_home = $self->npg_ssl_home();
  my $https_cert_path = "$npg_ssl_home/$SSH_CERT_FILENAME";
  if(! -f $https_cert_path) {
    croak qq[Path to SSL certificate is not available $https_cert_path.];
  }

  my $https_key_path  = "$npg_ssl_home/$SSH_PK_FILENAME";
  if(! -f $https_key_path) {
    croak qq[Path to SSL private key is not available $https_key_path.];
  }

  my $socket_opts = sprintf '--httpPort=-1 --httpsPort=%i --httpsCertificate=%s --httpsPrivateKey=%s',
    $JENKINS_PORT,
    $https_cert_path,
    $https_key_path;

  my $command = sprintf 'java -Xmx2g %s -Dhttp.proxyHost=%s -Dhttp.proxyPort=%i -jar %s %s',
                        $tmpdir,
                        $PROXY_SERVER,
                        $PROXY_PORT,
                        $self->jenkins_war,
                        $socket_opts;

  my $log_name = join q[_], q[jenkins], $host, $self->timestamp();
  $log_name .=  q[.log];
  $command = join q[ ], $command, q[--logfile=] . $self->log_dir . q[/]. $log_name;

  # Extra, optional arguments appear at the end of the generated
  # command line
  if ($self->has_session_timeout) {
    $command = join q[ ], $command,
      q[--sessionTimeout=] . $self->session_timeout;
  }

  return $command;
};

override 'daemon_name'  => sub { return 'npg_jenkins'; };


no Moose;

1;
__END__

=head1 NAME

npg_tracking::daemon::jenkins

=head1 SYNOPSIS

=head1 DESCRIPTION

Metadata for a daemon that starts up jenkins integration server.

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL

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
