ELF=MBlaze/SDK/PTR3_HVPS/Debug/PTR3_HVPS.elf
# The Nexys4 uses a Quad SPI Flash, Spansion S25FL128S
.PHONY : all
all : hvps_nexys4.mcs
hvps_nexys4.mcs : hvps_nexys4.bit
	promgen -spi -w -p mcs -o hvps_nexys4.mcs -s 16384 -u 0 hvps_nexys4.bit
hvps_nexys4.bit : MBlaze/implementation/MBlaze.bit $(ELF)
	@echo hvps_nexys4.bit is out of date with respect to $?
	@ls -lt *.mcs *.bit $(ELF)
	@false
