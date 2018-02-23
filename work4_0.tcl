set ns [new Simulator]

set f0 [open out0.tr w]
set f1 [open out1.tr w]
set f2 [open out2.tr w]

set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]

$ns duplex-link $n0 $n3 1Mb 100ms DropTail
$ns duplex-link $n1 $n3 1Mb 100ms DropTail
$ns duplex-link $n2 $n3 1Mb 100ms DropTail
$ns duplex-link $n3 $n4 1Mb 100ms DropTail

proc finish {} {
    global f0 f1 f2
    close $f0
    close $f1
    close $f2
    #Runs Xgraph with such parameters: window size and names of input files
    exec xgraph out0.tr out1.tr out2.tr -geometry 800x600 \
    -0 source0 -1 source1 -2 source2 &
    exit 0
}

#Procedure of creating and connecting sources with sinks
proc attach-expoo-traffic {node sink size burst idle rate } {
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

#Procedure for collecting information. Counts current traffic of every source and writes it down into appropriate output files
proc record {} {
    global sink0 sink1 sink2 f0 f1 f2
    set ns [Simulator instance]
    #set interval of monitoring
    set time 0.5
    set bw0 [$sink0 set bytes_]
    set bw1 [$sink1 set bytes_]
    set bw2 [$sink2 set bytes_]
    set now [$ns now]
    puts $f0 "$now [expr $bw0/$time*8/1000000]"
    puts $f1 "$now [expr $bw1/$time*8/1000000]"
    puts $f2 "$now [expr $bw2/$time*8/1000000]"
    $sink0 set bytes_ 0
    $sink1 set bytes_ 0
    $sink2 set bytes_ 0
    $ns at [expr $now+$time] "record"
}

#Receiver with monitor of missed packets
set sink0 [new Agent/LossMonitor]
set sink1 [new Agent/LossMonitor]
set sink2 [new Agent/LossMonitor]

$ns attach-agent $n4 $sink0
$ns attach-agent $n4 $sink1
$ns attach-agent $n4 $sink2

set source0 [attach-expoo-traffic $n0 $sink0 200 2s 1s 100k]
set source1 [attach-expoo-traffic $n1 $sink1 200 2s 1s 200k]
set source2 [attach-expoo-traffic $n1 $sink2 200 2s 1s 300k]

$ns at 0.0 "record"
$ns at 10.0 "$source0 start"
$ns at 10.0 "$source1 start"
$ns at 10.0 "$source2 start"

$ns at 50.0 "$source0 stop"
$ns at 50.0 "$source1 stop"
$ns at 50.0 "$source2 stop"

$ns at 60.0 "finish"

$ns run
