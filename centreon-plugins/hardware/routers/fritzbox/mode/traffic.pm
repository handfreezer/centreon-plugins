###############################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Florian Asche <info@florian-asche.de>
#
####################################################################################

package hardware::routers::fritzbox::mode::traffic;

use base qw(centreon::plugins::mode);
use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use hardware::routers::fritzbox::mode::libgetdata;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"          => { name => 'hostname' },
                                  "port:s"              => { name => 'port', default => '49000' },
                                  "timeout:s"           => { name => 'timeout', default => 30 },
                                  "warning:s"           => { name => 'warning', default => '' },
                                  "critical:s"          => { name => 'critical', default => '' },
                                  "units:s"             => { name => 'units', default => 'B' },
                                });
    $self->{result} = {};
    $self->{hostname} = undef;
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify an Hostname.");
       $self->{output}->option_exit(); 
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-in', value => $self->{option_results}->{warning_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'in' threshold '" . $self->{option_results}->{warning_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-in', value => $self->{option_results}->{critical_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'in' threshold '" . $self->{option_results}->{critical_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-out', value => $self->{option_results}->{warning_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'out' threshold '" . $self->{option_results}->{warning_out} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-out', value => $self->{option_results}->{critical_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'out' threshold '" . $self->{option_results}->{critical_out} . "'.");
        $self->{output}->option_exit();
    }

    $self->{statefile_value}->check_options(%options);
    $self->{hostname} = $self->{option_results}->{hostname};
    if (!defined($self->{hostname})) {
        $self->{hostname} = 'me';
    }
}

sub run {
    my ($self, %options) = @_;

    my $new_datas = {};
    $self->{statefile_value}->read(statefile => "cache_linux_local_" . $self->{hostname}  . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{name}) ? md5_hex($self->{option_results}->{name}) : md5_hex('all')));
    $new_datas->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');

    ### GET DATA START
    $self->{pfad} = '/upnp/control/WANCommonIFC1';
    $self->{uri} = 'urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1';

    $self->{space} = 'GetAddonInfos';
    $self->{section} = 'NewTotalBytesSent';
    my $NewTotalBytesSent = hardware::routers::fritzbox::mode::libgetdata::getdata($self);
    #print $NewTotalBytesSent . "\n";

    $self->{space} = 'GetAddonInfos';
    $self->{section} = 'NewTotalBytesReceived';
    my $NewTotalBytesReceived = hardware::routers::fritzbox::mode::libgetdata::getdata($self);
    #print $NewTotalBytesReceived . "\n";

    $self->{space} = 'GetCommonLinkProperties';
    $self->{section} = 'NewLayer1UpstreamMaxBitRate';
    my $NewLayer1UpstreamMaxBitRate = hardware::routers::fritzbox::mode::libgetdata::getdata($self);
    #print $NewLayer1UpstreamMaxBitRate . "\n";

    $self->{space} = 'GetCommonLinkProperties';
    $self->{section} = 'NewLayer1DownstreamMaxBitRate';
    my $NewLayer1DownstreamMaxBitRate = hardware::routers::fritzbox::mode::libgetdata::getdata($self);
    #print $NewLayer1DownstreamMaxBitRate . "\n";
    ### GET DATA END

    # DID U KNOW? 
    # IN AND OUT IS BYTE
    # TOTAL IS BIT... 
    # so if you want all in BYTE... 
    # (8 BIT = 1 BYTE)
    # calc ($VAR / 8)
    $NewLayer1UpstreamMaxBitRate = ($NewLayer1UpstreamMaxBitRate / 8);
    $NewLayer1DownstreamMaxBitRate = ($NewLayer1DownstreamMaxBitRate / 8);
    $new_datas->{'in'} = ($NewTotalBytesReceived);
    $new_datas->{'out'} = ($NewTotalBytesSent);

    my $old_in = $self->{statefile_value}->get(name => 'in');
    my $old_out = $self->{statefile_value}->get(name => 'out');
    if (!defined($old_timestamp) || !defined($old_in) || !defined($old_out)) {
        #next;
        print "ERROR";
    }
    if ($new_datas->{'in'} < $old_in) {
        # We set 0. Has reboot.
        $old_in = 0;
    }
    if ($new_datas->{'out'} < $old_out) {
        # We set 0. Has reboot.
        $old_out = 0;
    }

    my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
    if ($time_delta <= 0) {
        # At least one second. two fast calls ;)
        $time_delta = 1;
    }
    my $in_absolute_per_sec = ($new_datas->{'in'} - $old_in) / $time_delta;
    my $out_absolute_per_sec = ($new_datas->{'out'} - $old_out) / $time_delta;

    my ($exit, $in_prct, $out_prct);

    $in_prct = $in_absolute_per_sec * 100 / $NewLayer1DownstreamMaxBitRate;
    $out_prct = $out_absolute_per_sec * 100 / $NewLayer1UpstreamMaxBitRate;
    if ($self->{option_results}->{units} eq '%') {
        my $exit1 = $self->{perfdata}->threshold_check(value => $in_prct, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $out_prct, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);
        $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    }
    $in_prct = sprintf("%.2f", $in_prct);
    $out_prct = sprintf("%.2f", $out_prct);



    ### Manage Output
    my ($in_value, $in_unit) = $self->{perfdata}->change_bytes(value => $in_absolute_per_sec, network => 1);
    my ($out_value, $out_unit) = $self->{perfdata}->change_bytes(value => $out_absolute_per_sec, network => 1);
    $self->{output}->output_add(short_msg => sprintf("Traffic In : %s/s (%s %%), Out : %s/s (%s %%)", 
                                    $in_value . $in_unit, $in_prct,
                                    $out_value . $out_unit, $out_prct));
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Traffic In : %s/s (%s %%), Out : %s/s (%s %%)", 
                                    $in_value . $in_unit, $in_prct,
                                    $out_value . $out_unit, $out_prct));
    }

    $self->{output}->perfdata_add(label => 'traffic_in', 
                                  unit => 'b/s',
                                  value => sprintf("%.2f", $in_absolute_per_sec),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-in', total => $NewLayer1DownstreamMaxBitRate),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-in', total => $NewLayer1DownstreamMaxBitRate),
                                  min => 0, max => $NewLayer1DownstreamMaxBitRate);
    $self->{output}->perfdata_add(label => 'traffic_out',
                                  unit => 'b/s',
                                  value => sprintf("%.2f", $out_absolute_per_sec),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-out', total => $NewLayer1UpstreamMaxBitRate),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-out', total => $NewLayer1UpstreamMaxBitRate),
                                  min => 0, max => $NewLayer1UpstreamMaxBitRate);
    
    $self->{statefile_value}->write(data => $new_datas);    
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

This Mode Checks your FritzBox Traffic on WAN Interface.
This Mode needs UPNP.

=over 8

=item B<--warning-in>

Threshold warning in percent for 'in' traffic.

=item B<--critical-in>

Threshold critical in percent for 'in' traffic.

=item B<--warning-out>

Threshold warning in percent for 'out' traffic.

=item B<--critical-out>

Threshold critical in percent for 'out' traffic.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').
Percent can be used only if --speed is set.

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=back

=cut
