onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib mmcm_ip_opt

do {wave.do}

view wave
view structure
view signals

do {mmcm_ip.udo}

run -all

quit -force
