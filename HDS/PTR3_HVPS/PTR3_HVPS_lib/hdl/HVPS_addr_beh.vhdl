--
-- VHDL Architecture PTR3_HVPS_lib.HVPS_addr.beh
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 17:25:42 11/11/2016
--
-- using Mentor Graphics HDL Designer(TM) 2013.1b (Build 2)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY PTR3_HVPS_lib;
USE PTR3_HVPS_lib.HVPS_cfg.all;

ENTITY HVPS_addr IS
  GENERIC( 
    BASE_ADDR  : std_logic_vector(15 DOWNTO 0) := X"0010";
    ADDR_WIDTH : integer range 16 downto 8     := 16;
    N_CHANNELS : integer range 15 downto 1     := 14;
    WORD_SIZE  : integer                       := 16
  );
  PORT( 
    ExpAddr   : IN     std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
    RdEn      : IN     std_logic;
    WrAck2    : IN     std_logic;
    WrEn      : IN     std_logic;
    clk       : IN     std_logic;
    wData     : IN     std_logic_vector (15 DOWNTO 0);
    BdEn      : OUT    std_logic;
    BdWrEn    : OUT    std_logic;
    ChanAddr2 : OUT    std_logic_vector (3 DOWNTO 0);
    RdAddr    : OUT    std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
    WrEn2     : OUT    std_logic;
    dpRdEn    : OUT    std_logic;
    wData2    : OUT    std_logic_vector (15 DOWNTO 0);
    RdStat    : OUT    std_logic;
    rst       : IN     std_logic
  );

-- Declarations

END ENTITY HVPS_addr ;

--
ARCHITECTURE beh OF HVPS_addr IS
  SIGNAL WrOK : std_logic;
  SIGNAL Read : std_logic;
  SIGNAL WrEn2_int : std_logic;
BEGIN
  Addrs : PROCESS (ExpAddr, WrEn2_int, WrAck2) IS
    Variable Offset : unsigned(ADDR_WIDTH-1 DOWNTO 0);
    Variable Chan : unsigned(3 DOWNTO 0);
  BEGIN
    IF unsigned(ExpAddr) >= unsigned(BASE_ADDR(ADDR_WIDTH-1 DOWNTO 0)) AND
       unsigned(ExpAddr) < unsigned(BASE_ADDR(ADDR_WIDTH-1 DOWNTO 0))
                 + N_CHANNELS*4 + 4 THEN
      BdEn <= '1';
      Offset := unsigned(ExpAddr) - unsigned(BASE_ADDR(ADDR_WIDTH-1 DOWNTO 0));
      Chan := Offset(5 DOWNTO 2);
      IF Chan >= 1 AND Offset(1 DOWNTO 0) = "00" AND WrEn2_int = '0' AND WrAck2 = '0' THEN
        WrOK <= '1';
      ELSE
        WrOK <= '0';
      END IF;
    ELSE
      BdEn <= '0';
      WrOK <= '0';
    END IF;
  END PROCESS;
  
  Writing : PROCESS (clk) IS
    Variable Offset : unsigned(ADDR_WIDTH-1 DOWNTO 0);
    Variable Chan : unsigned(3 DOWNTO 0);
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF rst = '1' THEN
        WrEn2_int <= '0';
      ELSE
        IF WrEn = '1' AND WrOK = '1' THEN
          Offset := unsigned(ExpAddr) - unsigned(BASE_ADDR(ADDR_WIDTH-1 DOWNTO 0));
          Chan := Offset(5 DOWNTO 2);
          ChanAddr2 <= std_logic_vector(Chan - 1);
          WrEn2_int <= '1';
          wData2 <= wData(WORD_SIZE-1 DOWNTO 0);
        END IF;
        IF WrAck2 = '1' THEN
          WrEn2_int <= '0';
        END IF;
      END IF;
    END IF;
  END PROCESS;
  
  Reading : PROCESS (clk) IS
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF RdEn = '1' AND Read = '0' THEN
        RdAddr <= std_logic_vector(unsigned(ExpAddr) -
                   unsigned(BASE_ADDR(ADDR_WIDTH-1 DOWNTO 0)));
        dpRdEn <= '1';
        Read <= '1';
      ELSIF RdEn = '1' AND Read = '1' THEN
        dpRdEn <= '0';
      ELSE
        dpRdEn <= '0';
        Read <= '0';
      END IF;
    END IF;
  END PROCESS;

  BdWrEn <= WrOK;
  WrEn2 <= WrEn2_int;
END ARCHITECTURE beh;

