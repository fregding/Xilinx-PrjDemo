onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib ram_256x8_truedual_opt

do {wave.do}

view wave
view structure
view signals

do {ram_256x8_truedual.udo}

run -all

quit -force
