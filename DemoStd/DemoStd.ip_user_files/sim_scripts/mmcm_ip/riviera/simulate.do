onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+mmcm_ip -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.mmcm_ip xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {mmcm_ip.udo}

run -all

endsim

quit -force
