
set top_module "GENCORDIC"
#set part_number "xc7a100tcsg324-2"
#set part_number "xc7a35ticsg324-1L"
set part_number "xc7s6cpga196-2"
#set part_number "xcau25p-sfvb784-2-e"

set view_rtl 0
if { [info exists ::env(VIEW_RTL)] } {
    set view_rtl $::env(VIEW_RTL)
}

set_param chipscope.maxJobs 32
set_param runs.launchOptions { -jobs 32 }
set_param general.usePosixSpawnForFork 1

create_project -in_memory -part $part_number
set_property design_mode GateLvl [current_fileset]

read_vhdl -vhdl2008 [glob ./src/*.vhd]

read_xdc ./constraints/timing.xdc
set_property USED_IN {synthesis} [get_files ./constraints/timing.xdc] ;#implementation out_of_context

if {$view_rtl == 1} {

    synth_design -top $top_module -part $part_number -rtl -name rtl_1

    start_gui

    show_schematic [get_cells]

    return ;
}

synth_design -top $top_module -part $part_number -global_retiming on -mode out_of_context -directive Default;#-directive PerformanceOptimized

read_xdc ./constraints/timing.xdc

opt_design ;#-directive Explore
place_design ;#-directive Explore
phys_opt_design ;#-directive AggressiveExplore
route_design -directive NoTimingRelaxation
phys_opt_design -directive Explore

set_param project.isImplRun true
generate_parallel_reports -reports { \
    "report_timing_summary -max_paths 10 -file ./build/timing_summary.rpt" \
    "report_utilization -hierachical -file ./build/utilization.rpt" \
}
set_param project.isImplRun false

write_checkpoint -force ./build/${top_module}_routed.dcp

puts ">>> Flow completed with WNS: [get_property SLACK [get_timing_paths]]"

puts "\n======================================================================="
puts "                       IMPLEMENTATION SUMMARY                            "
puts "=======================================================================\n"


set wns [get_property SLACK [get_timing_paths -setup -max_paths 1]]
set whs [get_property SLACK [get_timing_paths -hold -max_paths 1]]

puts "--- TIMING ---"
if {$wns < 0} {
    puts " Worst Negative Slack (WNS) : $wns ns  <-- TIMING VIOLATION!"
} else {
    puts " Worst Negative Slack (WNS) : $wns ns"
}
puts "  Worst Hold Slack (WHS)     : $whs ns\n"



puts "--- UTILIZATION ---"
puts [report_utilization -hierarchical -return_string]

puts "=======================================================================\n"
