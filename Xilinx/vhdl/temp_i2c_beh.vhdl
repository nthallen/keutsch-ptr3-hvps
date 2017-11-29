--
-- VHDL Architecture idx_fpga_lib.temp_i2c.beh
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 20:30:36 05/ 7/2015
--
-- using Mentor Graphics HDL Designer(TM) 2013.1b (Build 2)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
Library UNISIM;
use UNISIM.vcomponents.all;

ENTITY temp_i2c IS
  PORT( 
    scl_pad_o    : IN     std_logic;
    scl_padoen_o : IN     std_logic;
    sda_pad_o    : IN     std_logic;
    sda_padoen_o : IN     std_logic;
    scl_pad_i    : OUT    std_logic;
    sda_pad_i    : OUT    std_logic;
    scl          : INOUT  std_logic;
    sda          : INOUT  std_logic
  );

-- Declarations

END ENTITY temp_i2c ;

--
ARCHITECTURE beh OF temp_i2c IS
BEGIN
  IOBUF_sda : IOBUF
    port map (
      O => sda_pad_i, -- Buffer output
      IO => sda, -- Buffer inout port (connect directly to top-level port)
      I => sda_pad_o, -- Buffer input
      T => sda_padoen_o -- 3-state enable input, high=input, low=output
    );
  IOBUF_scl : IOBUF
    port map (
      O => scl_pad_i, -- Buffer output
      IO => scl, -- Buffer inout port (connect directly to top-level port)
      I => scl_pad_o, -- Buffer input
      T => scl_padoen_o -- 3-state enable input, high=input, low=output
    );
END ARCHITECTURE beh;

