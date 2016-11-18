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
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY HVPS_addr IS
   GENERIC( 
      BASE_ADDR  : std_logic_vector(15 DOWNTO 0) := X"0030";
      N_CHANNELS : integer                       := 14;
      WORD_SIZE  : integer                       := 16
   );
   PORT( 
      ExpAddr   : IN     std_logic_vector (15 DOWNTO 0);
      RdEn      : IN     std_ulogic;
      WrAck2    : IN     std_logic;
      WrEn      : IN     std_ulogic;
      clk       : IN     std_ulogic;
      wData     : IN     std_logic_vector (15 DOWNTO 0);
      BdEn      : OUT    std_ulogic;
      BdWrEn    : OUT    std_ulogic;
      ChanAddr2 : OUT    std_logic_vector (3 DOWNTO 0);
      RdAddr    : OUT    std_logic_vector (15 DOWNTO 0);
      WrEn2     : OUT    std_logic;
      dpRdEn    : OUT    std_logic;
      wData2    : OUT    std_logic_vector (15 DOWNTO 0);
      RdStat    : OUT    std_logic
   );

-- Declarations

END HVPS_addr ;

--
ARCHITECTURE beh OF HVPS_addr IS
  SIGNAL WrOK : std_logic;
  SIGNAL Read : std_logic;
  SIGNAL WrEn2_int : std_logic;
BEGIN
  Addrs : PROCESS (ExpAddr, WrEn2_int, WrAck2) IS
    Variable Offset : std_logic_vector(15 DOWNTO 0);
    Variable Chan : std_logic_vector(13 DOWNTO 0);
  BEGIN
    IF ExpAddr >= BASE_ADDR AND ExpAddr < BASE_ADDR + N_CHANNELS*4 + 4 THEN
      BdEn <= '1';
      Offset := ExpAddr - BASE_ADDR;
      Chan := Offset(15 DOWNTO 2);
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
    Variable Offset : std_logic_vector(15 DOWNTO 0);
    Variable Chan : std_logic_vector(3 DOWNTO 0);
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF WrEn = '1' AND WrOK = '1' THEN
        Offset := ExpAddr - BASE_ADDR;
        Chan := Offset(5 DOWNTO 2);
        ChanAddr2 <= Chan - 1;
        WrEn2_int <= '1';
        wData2 <= wData(WORD_SIZE-1 DOWNTO 0);
      END IF;
      IF WrAck2 = '1' THEN
        WrEn2_int <= '0';
      END IF;
    END IF;
  END PROCESS;
  
  Reading : PROCESS (clk) IS
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF RdEn = '1' AND Read = '0' THEN
        RdAddr <= ExpAddr - BASE_ADDR;
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

