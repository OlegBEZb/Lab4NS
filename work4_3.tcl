set ns [new Simulator]

#Задаём заголовок графика и период вывода номеров пакетов
set label "Expoo_Traffic"
set mod 50

$ns color 0 Blue
$ns color 1 Red

#Подготавливаем выходной файл симулятора out.tr
exec rm -f out.tr
set fout [open out.tr w]

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

$ns queue-limit $r1 $r2 15
$ns duplex-link-op $r1 $r2 queuePos 0.5
#Задаём мониторинг очереди
$ns trace-queue $r1 $r2 $fout

#Создаём объекти типа QueueMonitor
set qm0 [ $ns monitor-queue $r1 $r2 [ $ns get-ns-traceall] ]

#Процедура обработки выодных данных
proc finish {label mod} {
#Создаём и подготавливаем выходной файл данных
    exec rm -f temp.rands
    set f [open temp.rands w]
    puts $f "TitleText: $label"
    puts $f "Device: Postscript"
    exec rm -f temp.p
    exec touch temp.p
#Обрабатываем файл данных мимулятора out.tr и заносим из него данные о полученных/отправленных пакетах очереди во временный файл temp.p   
    exec awk {
          {
            if (($1=="+"||$1=="-")&&\
                ($5=="exp"))\
                           print $2,$8*(mod+10) + ($11 % mod)
          }
    } mod=$mod out.tr > temp.p
#Заносим данные об отброшенных пакетах очереди во временный файл temp.p
    exec rm -f temp.d
    exec touch temp.d
    exec awk {
          {
            if($1=="d")
                print $2,$8*(mod+10) + ($11 % mod)
          }
    } mod=$mod out.tr > temp.d
#Заносим даные из временных файлов temp.p и temp.d в выходной файл для xgraph temp.rands
    puts $f\"enque/deque
    flush $f
    exec cat temp.p >@ $f
    flush $f

    puts $f\n\"drops
    flush $f

    exec head -1 temp.d >@ $f
    exec cat temp.d >@ $f
    close $f
    set tx "time (sec)"
    set ty "packet number (mod $mod)"

#Запускаем Xgraph со входным файлом temp.rands
    exec xgraph -bb -tk -nl -m -zg 0 -x $tx -y $ty temp.rands &
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


#Receiver with monitor of missed packets
set sink0 [new Agent/Null]
set sink1 [new Agent/Null]

$ns attach-agent $k1 $sink0
$ns attach-agent $k2 $sink1

set source0 [attach-expoo-traffic $s1 $sink0 500 0.1s 0.1s 150k]
$source0 set fid_ 0
set source1 [attach-expoo-traffic $s2 $sink1 500 0.1s 0.1s 250k]
$source1 set fid_ 1

$ns at 0.1 "$source0 start"
$ns at 0.1 "$source1 start"
$ns at 2.5 "$source0 stop"
$ns at 2.5 "$source1 stop"
$ns at 3.0 "ns flush-trace; close $fout;\
            finish $label $mod"

$ns run
