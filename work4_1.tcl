set ns [new Simulator]

set f0 [open out0.tr w]

set s1 [$ns node]
set s2 [$ns node]
set s3 [$ns node]

set r1 [$ns node]
set r2 [$ns node]
set r3 [$ns node]
set r4 [$ns node]
set r5 [$ns node]

set k1 [$ns node]
set k2 [$ns node]
set k3 [$ns node]

$ns duplex-link $r1 $r2 128kb 20ms DropTail
$ns duplex-link-op $r1 $r2 orient right

$ns duplex-link $s1 $r1 128kb 20ms DropTail
$ns duplex-link-op $s1 $r1 orient right

$ns duplex-link $r1 $s2 128kb 20ms DropTail
$ns duplex-link-op $r1 $s2 orient up

$ns duplex-link $r1 $s3 1Mb 100ms DropTail
$ns duplex-link-op $r1 $s3 orient down

$ns duplex-link $r2 $r3 1Mb 100ms DropTail
$ns duplex-link-op $r2 $r3 orient right-up

$ns duplex-link $r2 $r5 1Mb 100ms DropTail
$ns duplex-link-op $r2 $r5 orient right-down

$ns duplex-link $r3 $k1 1Mb 100ms DropTail
$ns duplex-link-op $r3 $k1 orient right-up

$ns duplex-link $r3 $r4 1Mb 100ms DropTail
$ns duplex-link-op $r3 $r4 orient right

$ns duplex-link $r4 $k2 1Mb 100ms DropTail
$ns duplex-link-op $r4 $k2 orient right

$ns duplex-link $r5 $k3 1Mb 100ms DropTail
$ns duplex-link-op $r5 $k3 orient right

$ns duplex-link $r4 $k3 1Mb 100ms DropTail
$ns duplex-link-op $r4 $k3 orient down

$ns queue-limit $r1 $r2 30
$ns duplex-link-op $r1 $r2 queuePos 0.5

#Создаём объект типа QueueMonitor
set qm0 [ $ns monitor-queue $r1 $r2 [ $ns get-ns-traceall] ]

#Процедура мониторинга очереди с помощью объекта qm0
proc trqueue {} {
    global qm0 f0
    set ns [Simulator instance]
    set time 0.1
#Переменная состояния, определяющая размер очереди в пакетах
    set q1 [$qm0 set pkts_]
    set now [$ns now]
    puts $f0 "$now $q1"
    $qm0 reset
    $ns at [expr $now+$time] "trqueue"    
}


proc finish {} {
    global f0
    close $f0
    #Runs Xgraph with such parameters: window size,window position and names of input files
    exec xgraph out0.tr -geometry 800x600+100+100 \
    -0 source0 &
    exit 0
}

#Procedure of creating and connecting expoo-sources with sinks
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

set sink0 [new Agent/Null]
set sink1 [new Agent/Null]

$ns attach-agent $k1 $sink0
$ns attach-agent $k2 $sink1

set source0 [attach-expoo-traffic $s1 $sink0 300 0.1s 0.1s 150k]
set source1 [attach-expoo-traffic $s2 $sink1 300 0.1s 0.1s 250k]


$ns at 0.0 "trqueue"
$ns at 0.1 "$source0 start"
$ns at 0.1 "$source1 start"
$ns at 5.0 "$source0 stop"
$ns at 5.0 "$source1 stop"
$ns at 6.0 "finish"

$ns run
