-------------------------------------------------------------------------------
-- hvps_nexys4.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity hvps_nexys4 is
  GENERIC (
    ADDR_WIDTH : integer range 16 DOWNTO 8 := 8
  );
  port (
    RS232_TX        : OUT   std_logic;
    RS232_RX        : IN    std_logic;
    
    JXADC           : IN    std_logic_vector (7 DOWNTO 0);
    
    JA_I1           : IN    std_logic_vector (1 DOWNTO 0);
    JA_IO           : INOUT std_logic_vector (3 DOWNTO 2);
    JA_I2           : IN    std_logic_vector (7 DOWNTO 4);
    
    JB              : IN    std_logic_vector (7 DOWNTO 0);
    JC              : IN    std_logic_vector (7 DOWNTO 0);
    JD              : IN    std_logic_vector (7 DOWNTO 0);
    Nexys4_LEDs     : OUT   std_logic_vector(15 downto 0);
    Nexys4_Switches : IN    std_logic_vector(15 downto 0);
    clk_100MHz_in   : IN    std_logic;
    RESET           : IN    std_logic
  );
end hvps_nexys4;

architecture STRUCTURE of hvps_nexys4 is
  SIGNAL subbus_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
  SIGNAL subbus_ctrl : std_logic_vector(6 downto 0);
  SIGNAL subbus_data_i : std_logic_vector(15 downto 0);
  SIGNAL subbus_data_o : std_logic_vector(15 downto 0);
  SIGNAL subbus_status : std_logic_vector(3 downto 0);
  SIGNAL subbus_collision : std_logic;
  SIGNAL subbus_fail_in : std_logic;
  SIGNAL clk_100MHz : std_logic;
  SIGNAL Flt_CPU_Reset : std_logic;
  SIGNAL Fail_Out : std_logic;
  SIGNAL LEDs : std_logic_vector(15 downto 0);
  
  component MBlaze is
    port (
      RS232_TX : out std_logic;
      RS232_RX : in std_logic;
      RESET : in std_logic;
      axi_gpio_subbus_addr_pin : out std_logic_vector(7 downto 0);
      axi_gpio_subbus_ctrl_pin : out std_logic_vector(6 downto 0);
      axi_gpio_subbus_data_i_pin : in std_logic_vector(15 downto 0);
      axi_gpio_subbus_data_o_pin : out std_logic_vector(15 downto 0);
      axi_gpio_subbus_status_pin : in std_logic_vector(3 downto 0);
      axi_gpio_subbus_leds_pin : out std_logic_vector(15 downto 0);
      axi_gpio_subbus_switches_pin : in std_logic_vector(15 downto 0);
      clk_100MHz_in_pin : in std_logic;
      CLK_OUT : out std_logic
    );
  end component;

  attribute BOX_TYPE : STRING;
  attribute BOX_TYPE of MBlaze : component is "user_black_box";

  component hvps_io IS
    GENERIC( 
      N_INTERRUPTS : integer range 15 downto 0 := 0;
      N_BOARDS     : integer range 15 downto 0 := 1;
      ADDR_WIDTH   : integer                   := 8
    );
    PORT( 
      clk              : IN     std_ulogic;
      subbus_addr      : IN     std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
      subbus_ctrl      : IN     std_logic_vector (6 DOWNTO 0);
      subbus_data_o    : IN     std_logic_vector (15 DOWNTO 0);
      subbus_fail_in   : IN     std_ulogic;
      Flt_CPU_Reset    : OUT    std_ulogic;
      subbus_collision : OUT    std_ulogic;
      subbus_data_i    : OUT    std_logic_vector (15 DOWNTO 0);
      subbus_fail_out  : OUT    std_ulogic;
      subbus_status    : OUT    std_logic_vector (3 DOWNTO 0);
      hvps_scl         : INOUT  std_logic;
      hvps_sda         : INOUT  std_logic
    );
  end component;

begin

  MBlaze_i : MBlaze
    port map (
      RS232_TX => RS232_TX,
      RS232_RX => RS232_RX,
      RESET => RESET,
      axi_gpio_subbus_addr_pin => subbus_addr,
      axi_gpio_subbus_ctrl_pin => subbus_ctrl,
      axi_gpio_subbus_data_i_pin => subbus_data_i,
      axi_gpio_subbus_data_o_pin => subbus_data_o,
      axi_gpio_subbus_status_pin => subbus_status,
      axi_gpio_subbus_leds_pin => LEDs,
      axi_gpio_subbus_switches_pin => Nexys4_Switches,
      clk_100MHz_in_pin => clk_100MHz_in,
      CLK_OUT => clk_100MHz
    );

  hvps : hvps_io
    generic map ( ADDR_WIDTH => ADDR_WIDTH )
    port map (
      clk => clk_100MHz,
      subbus_addr => subbus_addr,
      subbus_ctrl => subbus_ctrl,
      subbus_data_o => subbus_data_o,
      subbus_fail_in => subbus_fail_in,
      Flt_CPU_Reset => Flt_CPU_Reset,
      subbus_collision => subbus_collision,
      subbus_data_i => subbus_data_i,
      subbus_fail_out => Fail_Out,
      subbus_status => subbus_status,
      hvps_scl => JA_IO(2),
      hvps_sda => JA_IO(3)
    );
  
  subbus_fail_in <= LEDs(0);
  Nexys4_LEDs(0) <= Fail_Out;
  Nexys4_LEDs(15 downto 1) <= LEDs(15 downto 1);
end architecture STRUCTURE;

