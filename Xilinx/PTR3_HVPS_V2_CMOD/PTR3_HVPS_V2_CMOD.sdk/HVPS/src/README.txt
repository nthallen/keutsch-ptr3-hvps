Subbus server code for PTR3_HVPS driver.
Copied from PTR3/tripole project 11/29/16
Added INTA_ADDRESS that can be defined in the
  Project->Properties->C/C++ Build->Settings->Defined Variables (-D)
  For this project, I am setting INTA_ADDRESS=0x4
  This setting of course needs to match the setting of INTA_ADDR
  defined in vhdl/hvps_io_struct.vhd in the instantiation of the
  syscon.
