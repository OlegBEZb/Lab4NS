proc finish {label mod} {
exec rm -f temp.rands
set f [open temp.rands w]
puts $f "TitleText: $label"
puts $f "Device: Postscript"

exec rm -f temp.p
exec touch temp.p
exec awk {
	{
	if (($1 == "+" || $1 == "-") && ($5 == "exp")) \
			print $2, $8 * (mod + 10) + ($11 % mod)
	}
} mod=$mod out0.tr > temp.p

exec rm -f temp.d
exec touch temp.d
exec awk {
{
	if ($1 == "d") \
			print $2, $8 * (mod + 10) + ($11 % mod)
	}
} mod=$mod out0.tr > temp.d

puts $f \"enque/deque
#flush $f
exec cat temp.p >@ $f
#flush $f

puts $f \n\"drops
#flush $f

#exec head -1 temp.d >@ $f
exec cat temp.d >@ $f
close $f

set tx "time (sec)"
set ty "packet number (mod $mod)"

exec xgraph -bb -tk -nl -m -zg 0 -x $tx -y $ty temp.rands &
exit 0
}

proc attach-expoo-traffic { node sink size burst idle rate } {
	set ns [Simulator instance]
	set source [new Agent/CBR/UDP]
	$ns attach-agent $node $source
	set traffic [new Traffic/Expoo]
	$traffic set packet-size $size
	$traffic set burst-time $burst
	$traffic set idle-time $idle
	$traffic set rate $rate
	$source attach-traffic $traffic
	$ns connect $source $sink
	return $source
}

set ns [new Simulator]
set label "Expoo_Traffic"
set mod 50

$ns color 0 Blue
$ns color 1 Red

for {set index 0} {$index <= 3} {incr index} {
	set n($index) [$ns node]
}

$ns duplex-link $n(0) $n(2) 1Mb 100ms DropTail
$ns duplex-link $n(1) $n(2) 1Mb 100ms DropTail
$ns duplex-link $n(2) $n(3) 128kb 100ms DropTail
#$ns queue-limit $n2 $n3 10

exec rm -f out0.tr
set fout [open out0.tr w]

set sink(0) [new Agent/Null]
set sink(1) [new Agent/Null]

$ns attach-agent $n(3) $sink(0)
$ns attach-agent $n(3) $sink(1)

$ns queue-limit $n(2) $n(3) 15
$ns trace-queue $n(2) $n(3) $fout

set source(0) [attach-expoo-traffic $n(0) $sink(0) 500 0.1s 0.1s 150k]
set source(1) [attach-expoo-traffic $n(1) $sink(1) 500 0.1s 0.1s 250k]

$source(0) set fid_ 0
$source(1) set fid_ 1

$ns at 0.1 "$source(0) start"
$ns at 0.1 "$source(1) start"
$ns at 2.5 "$source(0) stop"
$ns at 2.5 "$source(1) stop"

$ns at 3.0 "ns flush-trace; close $fout;\
	    finish $label $mod"
$ns run