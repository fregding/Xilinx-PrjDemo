onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib scfifo_256x8_opt

do {wave.do}

view wave
view structure
view signals

do {scfifo_256x8.udo}

run -all

quit -force
