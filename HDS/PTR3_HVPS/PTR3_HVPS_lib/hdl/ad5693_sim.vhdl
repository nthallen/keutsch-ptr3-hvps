--
-- VHDL Architecture PTR3_HVPS_lib.ad5693.sim
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 16:17:21 11/18/2016
--
-- using Mentor Graphics HDL Designer(TM) 2013.1b (Build 2)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY ad5693 IS
  PORT (
    clk : IN std_logic;
    rst : IN std_logic;
    sda : INOUT std_logic;
    scl : IN std_logic
  );
END ENTITY ad5693;

--
ARCHITECTURE sim OF ad5693 IS
  
  COMPONENT i2c_slave
     GENERIC (
        I2C_ADDR : std_logic_vector(6 DOWNTO 0) := "1000000"
     );
     PORT (
        clk   : IN     std_ulogic;
        rdata : IN     std_logic_vector(7 DOWNTO 0);
        rst   : IN     std_ulogic;
        scl   : IN     std_logic;
        WE    : OUT    std_logic;
        start : OUT    std_ulogic;
        stop  : OUT    std_ulogic;
        wdata : OUT    std_ulogic_vector(7 DOWNTO 0);
        rdreq : OUT    std_logic;
        RE    : INOUT  std_logic;
        sda   : INOUT  std_logic
     );
  END COMPONENT i2c_slave;
  SIGNAL WE : std_logic;
  SIGNAL start : std_logic;
  SIGNAL stop : std_logic;
  SIGNAL wdata : std_logic_vector(7 DOWNTO 0);
  SIGNAL rdreq : std_logic;
  SIGNAL RE : std_logic;
BEGIN
  RE <= '0';
  
  dac : i2c_slave
     GENERIC MAP (
        I2C_ADDR => "1001100"
     )
     PORT MAP (
        clk   => clk,
        rdata => X"00",
        rst   => rst,
        scl   => scl,
        WE    => WE,
        start => start,
        stop  => stop,
        wdata => wdata,
        rdreq => rdreq,
        RE    => RE,
        sda   => sda
     );
END ARCHITECTURE sim;

