--
-- VHDL Architecture PTR3_HVPS_lib.HVPS_R2.beh
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 15:15:54 11/28/2017
--
-- HVPS_R2 is a wrapper for HVPS_IO redefining the configuration for
-- Zhen Dai's experiments. This configuration uses one board with
-- 4 Negative 1000 Volt supplies.
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY PTR3_HVPS_lib;
USE PTR3_HVPS_lib.HVPS_cfg.all;

ENTITY HVPS_R2 IS
    GENERIC (
      ADDR_WIDTH   : integer                   := 8
    );
    PORT (
      clk              : IN     std_logic;
      subbus_addr      : IN     std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
      subbus_ctrl      : IN     std_logic_vector(6 DOWNTO 0);
      subbus_data_o    : IN     std_logic_vector(15 DOWNTO 0);
      subbus_fail_in   : IN     std_logic;
      Flt_CPU_Reset    : OUT    std_logic;
      subbus_collision : OUT    std_logic;
      subbus_data_i    : OUT    std_logic_vector(15 DOWNTO 0);
      subbus_fail_out  : OUT    std_logic;
      subbus_status    : OUT    std_logic_vector(3 DOWNTO 0);
      hvps_scl         : INOUT  std_logic;
      hvps_sda         : INOUT  std_logic
    );
END ENTITY HVPS_R2;

--
ARCHITECTURE beh OF HVPS_R2 IS
  COMPONENT HVPS_IO
    GENERIC (
      N_INTERRUPTS : integer range 15 downto 0 := 0;
      N_BOARDS     : integer range 15 downto 0 := 1;
      ADDR_WIDTH   : integer                   := 8;
      N_CHANNELS   : integer                   := 14;
      ChanCfgs     : PTR3_HVPS_lib.HVPS_cfg.Cfg_t := ("000000000", "000000010", "001000100", "010000111", "011001000", "011001011", "100010001", "011011000", "011011011", "100100001", "011101000", "011101011", "100110001", "100111001")
    );
    PORT (
      clk              : IN     std_logic;
      subbus_addr      : IN     std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
      subbus_ctrl      : IN     std_logic_vector(6 DOWNTO 0);
      subbus_data_o    : IN     std_logic_vector(15 DOWNTO 0);
      subbus_fail_in   : IN     std_logic;
      Flt_CPU_Reset    : OUT    std_logic;
      subbus_collision : OUT    std_logic;
      subbus_data_i    : OUT    std_logic_vector(15 DOWNTO 0);
      subbus_fail_out  : OUT    std_logic;
      subbus_status    : OUT    std_logic_vector(3 DOWNTO 0);
      hvps_scl         : INOUT  std_logic;
      hvps_sda         : INOUT  std_logic
    );
  END COMPONENT HVPS_IO;
  FOR ALL : HVPS_IO USE ENTITY PTR3_HVPS_lib.HVPS_IO;
BEGIN
  --  hds hds_inst
  IO : HVPS_IO
    GENERIC MAP (
      N_INTERRUPTS => 0,
      N_BOARDS     => 1,
      ADDR_WIDTH   => ADDR_WIDTH,
      N_CHANNELS   => 8,
      ChanCfgs     => ("101000000", "101000010", "101000100", "101000111")
        -- 8:6 => Voltage range
        --   000 => 200
        --   001 => 400
        --   010 => (-)800
        --   011 => 2000
        --   100 => 3000
        --   101 => (-)1000
        -- 5:3 => board address
        -- 2:1 => Next 2 bits are channel address on the board
        -- 0 => LSB indicates channel is the last one on the board
    )
    PORT MAP (
      clk              => clk,
      subbus_addr      => subbus_addr,
      subbus_ctrl      => subbus_ctrl,
      subbus_data_o    => subbus_data_o,
      subbus_fail_in   => subbus_fail_in,
      Flt_CPU_Reset    => Flt_CPU_Reset,
      subbus_collision => subbus_collision,
      subbus_data_i    => subbus_data_i,
      subbus_fail_out  => subbus_fail_out,
      subbus_status    => subbus_status,
      hvps_scl         => hvps_scl,
      hvps_sda         => hvps_sda
    );
END ARCHITECTURE beh;

