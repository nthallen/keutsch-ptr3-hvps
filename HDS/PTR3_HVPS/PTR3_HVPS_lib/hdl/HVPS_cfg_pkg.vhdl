--
-- VHDL Package Header PTR3_HVPS_lib.HVPS_cfg
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 13:05:40 11/28/2017
--
-- using Mentor Graphics HDL Designer(TM) 2016.1 (Build 8)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
PACKAGE HVPS_cfg IS
  constant CHANCFGBITS : integer := 9;
  TYPE Cfg_t is array (natural range <>) of std_logic_vector(CHANCFGBITS-1 DOWNTO 0);
  -- 8:6 => Voltage range
  --   000 => 200
  --   001 => 400
  --   010 => -800
  --   011 => 2000
  --   100 => 3000
  -- 5:3 => board address
  -- 2:1 => Next 2 bits are channel address on the board
  -- 0 => LSB indicates channel is the last one on the board
END HVPS_cfg;
