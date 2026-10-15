onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+pll_ip -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.pll_ip xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {pll_ip.udo}

run -all

endsim

quit -force
