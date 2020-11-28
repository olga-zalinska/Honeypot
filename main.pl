#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use lib dirname (__FILE__);

use Time::Local;
use Time::HiRes qw(usleep);
use Getopt::Long;

my $COMMANDS_LOG = '/volume/commands.log';
my $COMMANDS_WITH_OUTPUTS_LOG = '/volume/commands_with_outputs.log';
my $OUTPUT_START = 'output_start';
my $OUTPUT_END = 'output_end';
my $USER = "user>"; #todo root>

sub read_events_from_commands_log {
    my $filename = $_[0];
    my %events = ();
    open(FH, '<', $filename) or die $!;
    while (<FH>) {
        my $log_line = $_;
        if (length($log_line) > 1) {
            my ($y, $m, $d, $H, $M, $S) = $log_line =~ m|(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)|;
            my ($x, $command) = $log_line =~ m|(.*)Command: ([a-z].+)|;
            if (!defined $command) {
                $command = '';
            }
            my $timet = timelocal($S, $M, $H, $d, $m - 1, $y);
            my $formatted_date = "$y-$m-$d $H:$M:$S";
            my @event_data = ($formatted_date, $command);
            $events{$timet} = [ @event_data ];
        }
    }
    close(FH);
    return %events;
}

sub read_events_outputs{
    my $filename = $_[0];
    my @execution_dates = @{$_[1]};
    my %outputs = ();
    my $dates_iterator = 0;

    open(FH, '<', $filename) or die $!;
    my $single_output = '';
    my $is_in_output = 0;
    while (<FH>) {
        my $log_line = $_;
        if (index($log_line, $OUTPUT_START ) != -1){
            $is_in_output = 1;
            next;
        }
        if (index($log_line, $OUTPUT_END) != -1){
            $is_in_output = 0;
            $single_output = $single_output;
            $outputs{$execution_dates[$dates_iterator]} = $single_output;
            $single_output = '';
            $dates_iterator += 1;
            next;
        }
        if ($is_in_output == 1){
            $single_output = $single_output . $log_line ;
        }
    }
    close FH;
    return %outputs;
}

sub print_commands_imitating_time {
    my %events = %{$_[0]};
    my %outputs = %{$_[1]};
    my $prev_time = (sort keys %events)[0];

    for (sort keys %events) {
        my $key = $_;
        my @value_array = @{$events{$key}};
        print "$value_array[0] $USER $value_array[1]\n";
        open my $fh, '<', \$outputs{$key} or die $!;
            while (<$fh>) {
                 print "$_";
                 usleep(100000);
            }
        close $fh;
        my $sleep_time = $key - $prev_time;
        if ($sleep_time > 15) {
            $sleep_time = 15;
        }
        sleep($sleep_time);
        $prev_time = $key;
    }
}

sub print_commands {
    my %events = %{$_[0]};

    for (sort keys %events) {
        my $key = $_;
        my @value_array = @{$events{$key}};
        print "$value_array[0] $USER $value_array[1]\n";
    }
}

my $executed_commands = 0;
my $play_logged_actions = 0;

GetOptions(
    'executed_commands=s'       => \$executed_commands,
    'play_logged_actions=i'     => \$play_logged_actions,
) or die "Incorrect usage!\n";

my %events = read_events_from_commands_log($COMMANDS_LOG);

if($executed_commands == 1){
    print_commands(%events);
}
elsif($play_logged_actions  == 1){
    my @execution_dates = (sort keys %events);
    my %outputs = read_events_outputs($COMMANDS_WITH_OUTPUTS_LOG, \@execution_dates);
    print_commands_imitating_time(\%events, \%outputs);
}
