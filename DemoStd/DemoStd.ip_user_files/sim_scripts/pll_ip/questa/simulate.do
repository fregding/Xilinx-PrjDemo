onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib pll_ip_opt

do {wave.do}

view wave
view structure
view signals

do {pll_ip.udo}

run -all

quit -force
