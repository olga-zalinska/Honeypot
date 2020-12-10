#!/usr/bin/perl

use strict;
use warnings;

use Time::Local;
use Time::HiRes qw(usleep);
use Getopt::Long;

use Cwd 'abs_path';

my $dirname = abs_path($0);
$dirname =~ s/main.pl//;

my $FULL_MODE_LOGS_LOCATION = '/volume/';
my $DEFAULT_DIRECORY_WITH_LOGS = 'logs/';
my $COMMANDS_LOG = 'commands.log';
my $COMMANDS_WITH_OUTPUTS_LOG = 'commands_with_outputs.log';
my $OUTPUT_START = 'output_start';
my $OUTPUT_END = 'output_end';
my $USER = "user>";
my $P0F_FILE = "p0f_scan.log";

sub read_events_from_commands_log {
    my $filename = $_[0];
    my %events = ();
    open(FH, '<', $filename) or die "Nie znaleziono pliku commands.log. W pierwszej kolejności użyj main.py by wywołać i zalogować komendy.";
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

    open(FH, '<', $filename) or die "Nie znaleziono pliku commands_with_outputs.log. W pierwszej kolejności użyj main.py by wywołać i zalogować komendy.";
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

sub read_ssh_statistics {
    my $regex = qr"\[((\d+)\/(\d+)\/(\d+)) ((\d+):(\d+):(\d+))\] mod=[a-z|+]+\|cli=((\d+).(\d+).(\d+).(\d+))\/(\d+)\|srv=((\d+).(\d+).(\d+).(\d+))\/(\d+)\|subj=[a-z]+\|([a-z]+)=(.+)";
    my $p0f_file = $_[0];
    my %intruder_ips = ();
    my %intruder_operating_system = ();

    open(FH, '<', $p0f_file) or die "Nie znaleziono pliku p0f_scan.log. Jest on tworzony tylko gdy ktoś zaloguje się do honeypota przez SSH.";
    while (<FH>) {
        my $log_line = $_;
        if (length($log_line) > 1) {
            my @params = $log_line =~ $regex;

            if("os" eq $params[20] && index($params[21],"?") == -1) {
                my $intruder_ip = $params[8];
                $intruder_ips{$intruder_ip} += 1;
                my @rest = split / /, $params[21];
                $intruder_operating_system{$intruder_ip} = $rest[0];
            }
        }
    }
    for (keys %intruder_ips){
        my $key = $_;
        print "Intruder IP: $key; His operating system: '$intruder_operating_system{$key}' Login number: $intruder_ips{$key}\n";
    }
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
    my %events = @_;

    for (sort keys %events) {
        my $key = $_;
        my @value_array = @{$events{$key}};
        print "$value_array[0] $USER $value_array[1]\n";
    }
}

my $executed_commands = 0;
my $play_logged_actions = 0;
my $full_mode = 0;
my $dir_with_logs = '';
my $help = 0;
my $ssh_statistics = 0;

GetOptions(
    'help'       => \$help,
    'executed_commands'       => \$executed_commands,
    'play_logged_actions'     => \$play_logged_actions,
    'ssh_statistics'     => \$ssh_statistics,
    'full_mode'     => \$full_mode,
) or die "Incorrect usage!\n";


if($help == 1){
    print("Wyświetl komendy wywołane przez włamywacza: --executed_commands
    Wyswietl komendy z outputem które były wywoływane przez wlamywacza: --play_logged_actions
    Wyświetl statystyki połączeń SSH: --ssh_statistics
    By korzystać z trybu z dockerem, użyj też --full_mode
    By zobaczyć szczegółowy opis projektu, wywołaj --help z pliku main.sh
    --help, --executed_commands, --play_logged_actions, --ssh_statistics, --full_mode \n");
    exit(1)
}

if($full_mode == 0){
    $dir_with_logs = $dirname . $DEFAULT_DIRECORY_WITH_LOGS;
}
else{
    $dir_with_logs = $FULL_MODE_LOGS_LOCATION;
}

my %events = read_events_from_commands_log($dir_with_logs . $COMMANDS_LOG);

if($play_logged_actions == 1){
    my @execution_dates = (sort keys %events);
    my %outputs = read_events_outputs($dir_with_logs . $COMMANDS_WITH_OUTPUTS_LOG, \@execution_dates);
    print_commands_imitating_time(\%events, \%outputs);
}
elsif($executed_commands == 1){
    print_commands(%events);
}
if($ssh_statistics == 1){
    read_ssh_statistics($dir_with_logs . $P0F_FILE);
}

exit(0)
