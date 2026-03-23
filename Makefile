GHDL = ghdl
DESIGN_UNIT = GENCORDIC_TB
VHDL_FILES = src/CORDICPackage.vhd src/GENCORDIC.vhd src/GENCORDIC_TB.vhd 
RTIME = 750us

VIVADO_EXECUTABLE = vivado
#/home/lukasrumpel/Software/Vivado/2025.2/Vivado/bin/vivado  
VIVADO_FLOW = PERFORMANCE

# Optional: Eine gespeicherte Ansicht (wenn vorhanden)
WAVE_SAVE = $(DESIGN_UNIT).gtkw

all: simulate

analyze: $(VHDL_FILES)
	@echo "*** starting analysis ***"
	$(GHDL) -a --std=08 $(VHDL_FILES)

elaborate: analyze
	@echo "*** starting elaboration ***"
	$(GHDL) -e --std=08 $(DESIGN_UNIT)

simulate: elaborate
	@echo "*** starting simulation ***"
	$(GHDL) -r --std=08 $(DESIGN_UNIT) --stop-time=$(RTIME) --wave=simOut_$(DESIGN_UNIT).ghw

display: simulate
	@echo "*** opening gtkwave ***"
	gtkwave simOut_$(DESIGN_UNIT).ghw & 

clean:
	@echo "*** clean-up ***"
	rm -f *.cf simOut_$(DESIGN_UNIT).ghw

implement:
	@echo "*** implement design using vivado"
	@export VIVADO_FLOW ;\
	export VIEW_RTL=0 ;\
	$(VIVADO_EXECUTABLE) -mode batch -source tcl/run_impl.tcl -notrace -journal logs/vivado.jou
	
view_rtl:
	@echo "*** elaborate design and open vivado GUI ***"
	@export VIVADO_FLOW;\
	export VIEW_RTL=1 ;\
	$(VIVADO_EXECUTABLE) -mode batch -source tcl/run_impl.tcl -notrace -journal logs/vivado.jou

.PHONY: all analyze elaborate simulate display clean
