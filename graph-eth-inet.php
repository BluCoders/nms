<?php

/*
 * This script can be used in conjunction with gnuplot to create a basic network graph
 */

$tsleep = time()+1;
//$t = exec("date +%T");
$data = explode(" ", `cat /proc/net/dev | grep eth-inet | sed 's/  */ /g'`);
$prx=$data[1];
$ptx=$data[9];
while(true){
	time_sleep_until($tsleep++);
	$t = exec("date +%T");
	$data = explode(" ", `cat /proc/net/dev | grep eth-inet | sed 's/  */ /g'`);
	$rx = $data[1];
	$tx = $data[9];

	$dr = trim(`echo '8*($rx-$prx)' | bc`);
	$dt = trim(`echo '8*($tx-$ptx)' | bc`);

	echo $tsleep." ".$dr." ".$dt."\n";

	$prx=$rx;
	$ptx=$tx;
}
