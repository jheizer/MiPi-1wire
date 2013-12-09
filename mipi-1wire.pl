#! /usr/bin/perl -w
use warnings;
use POSIX qw/strftime/;

#---------------------------Configure-----------------------------

#Put your web server directory here
$webdir = '/usr/share/nginx/www/';

#Max temp (C) - It will retry if higher than this 
$maxtemp = 40;

#------------------------------------------------------------------

@list = `cat /sys/bus/w1/devices/w1_bus_master1/w1_master_slaves`;
chomp(@list);

#Date/Time for manually seeing the file has been updated
$dt = strftime('%Y-%m-%d %H-%M',localtime);
$xml = "<a updated='$dt'>\n";

foreach $sen(@list) {
  $c = 0;

  #retry until we have a reasonable value
  do {
    #increase sleep with each retry
    sleep $c;

    $output = `cat /sys/bus/w1/devices/$sen/w1_slave`;
    $output =~ /t=(?<temp>\d+)/;
    $calc = $+{temp} / 1000;
    
    $c += 1;
  } while (($calc > $maxtemp || $calc == 0) && $c < 20);

  #1 decimal place
  $calc = sprintf("%.1f", $calc);

  #Generate XML
  $xml = $xml . "<owd>\n";
  $xml = $xml . "<Name>DS18B20</Name>\n";
  $xml = $xml . "<ROMId>$sen</ROMId>\n";
  $xml = $xml . "<Temperature>$calc</Temperature>\n";
  $xml = $xml . "</owd>\n";

  sleep .1;
}

$xml = $xml . "</a>\n";


#debug mode
if ($#ARGV == 0) {
  if ($ARGV[0] eq "-d") {
    print $xml;
  }
}
else
{
  #write out the file
  open DETAILS, '>', $webdir . 'details.xml';
  print DETAILS $xml; 
  close DETAILS; 
}



