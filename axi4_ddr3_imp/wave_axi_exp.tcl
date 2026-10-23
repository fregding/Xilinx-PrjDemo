#-----------------------------------------------------------------------------
# File name : wave_axi_exp.tcl
# Description : Batch Tcl sourced by xsim on every launch of tb_axi_exp.
#   Waveform groups are NOT built here anymore. They come from the .wcfg file
#   passed with "-view" (same mechanism as the DemoStd project), which is set
#   by sim_exp.tcl into xsim.simulate.xsim.more_options.
#   This script only runs the simulation to $finish.
#   ASCII only.
#-----------------------------------------------------------------------------

puts "WAVE: running tb_axi_exp to \$finish"

if {[catch {current_wave_config} cfg]} {
    puts "WAVE: no wave config loaded, check the -view option"
} else {
    puts "WAVE: wave config = $cfg"
}

run all
