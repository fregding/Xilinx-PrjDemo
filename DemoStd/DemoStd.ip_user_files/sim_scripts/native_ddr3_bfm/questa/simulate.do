onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib native_ddr3_bfm_opt

do {wave.do}

view wave
view structure
view signals

do {native_ddr3_bfm.udo}

run -all

quit -force
