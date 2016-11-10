--
-- VHDL Architecture PTR3_HVPS_lib.HVPS_txn_tester.rtl
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 15:33:08 11/ 9/2016
--
-- using Mentor Graphics HDL Designer(TM) 2013.1b (Build 2)
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY HVPS_txn_tester IS
   GENERIC( 
      GOOD_I2C_ADDR : std_logic_vector (6 DOWNTO 0) := "1000100";
      BAD_I2C_ADDR  : std_logic_vector (6 DOWNTO 0) := "1000000"
   );
   PORT( 
      Done      : IN     std_logic;
      Err       : IN     std_logic;
      WE        : IN     std_logic;
      i2c_rdata : IN     std_logic_vector (7 DOWNTO 0);
      start1    : IN     std_ulogic;
      stop1     : IN     std_ulogic;
      wdata     : IN     std_ulogic_vector (7 DOWNTO 0);
      Rd        : OUT    std_logic;
      Start     : OUT    std_logic;
      Stop      : OUT    std_logic;
      Wr        : OUT    std_logic;
      clk       : OUT    std_ulogic;
      i2c_wdata : OUT    std_logic_vector (7 DOWNTO 0);
      rdata     : OUT    std_logic_vector (7 DOWNTO 0);
      rst       : OUT    std_ulogic;
      RE        : INOUT  std_logic;
      scl       : INOUT  std_logic;
      sda       : INOUT  std_logic
   );

-- Declarations

END HVPS_txn_tester ;

--
ARCHITECTURE rtl OF HVPS_txn_tester IS
  SIGNAL clk_100MHz : std_logic;
  SIGNAL SimDone : std_logic;
BEGIN
  f100m_clk : Process is
  Begin
    clk_100MHz <= '0';
    -- pragma synthesis_off
    wait for 20 ns;
    while SimDone = '0' loop
      clk_100MHz <= '1';
      wait for 5 ns;
      clk_100MHz <= '0';
      wait for 5 ns;
    end loop;
    wait;
    -- pragma synthesis_on
  End Process;

  test_proc: PROCESS IS
    procedure process_txn(W, R, Sta, Sto : IN std_logic;
      WD : IN std_logic_vector(7 DOWNTO 0)) is
    begin
      Wr <= W;
      Rd <= R;
      Start <= Sta;
      Stop <= Sto;
      i2c_wdata <= WD;
      -- pragma synthesis_off
      wait until Done = '0' AND Err = '0';
      Wr <= '0';
      Rd <= '0';
      wait until (Done = '1' OR Err = '1') for 150 us;
      IF Err = '1' THEN
        assert stop1 = '1'
          report "Expected STOP condition after ERR"
          severity error;
      ELSE
        assert Done = '1' AND stop1 = Sto
          report "Expected Done and STOP condition"
          severity error;
        IF Sta = '0' AND W = '1' THEN
          assert wdata = WD
            report "Slave write error"
            severity error;
        END IF;
      END IF;
      -- pragma synthesis_on
      return;
    end procedure process_txn;
  BEGIN
    SimDone <= '0';
    i2c_wdata <= (others => '0');
    Wr <= '0';
    Rd <= '0';
    Start <= '0';
    Stop <= '0';
    sda <= 'H';
    scl <= 'H';
    rdata <= (others => '0');
    RE <= '0';
    rst <= '1';
    -- pragma synthesis_off
    wait until clk_100MHz'Event and clk_100MHz = '1';
    wait until clk_100MHz'Event and clk_100MHz = '1';
    rst <= '0';
    wait until clk_100MHz'Event and clk_100MHz = '1';
    assert Done = '0' AND Err = '0' report "Done or Err too early" severity error;
    wait until Done = '1' for 200 ns;
    assert Done = '1' report "Not Done on reset" severity error;
    
    process_txn('1','0','1','0', BAD_I2C_ADDR & '0');
    assert Done = '0' AND Err = '1'
      report "Expected Err on bad I2C addr"
      severity error;

    process_txn('1','0','1','0', GOOD_I2C_ADDR & '0');
    assert Done = '1' AND Err = '0'
      report "Expected Done on good I2C addr"
      severity error;
      
    process_txn('1','0','0','1', X"55");
    assert Done = '1' AND Err = '0'
      report "Expected Done on good I2C addr"
      severity error;
      
    process_txn('0','1','1','0', GOOD_I2C_ADDR & '0');
    assert Done = '1' AND Err = '0'
      report "Expected Done on good I2C addr Rd"
      severity error;
    process_txn('0','1','0','0', X"00");
    assert Done = '1' AND Err = '0' AND i2c_rdata = X"55"
      report "Invalid rdata"
      severity error;
    process_txn('0','1','0','1', X"00");
    assert Done = '1' AND Err = '0' AND i2c_rdata = X"56"
      report "Invalid rdata"
      severity error;
  
    -- Test a restart: Write one byte, then read 2
    process_txn('1','0','1','0', GOOD_I2C_ADDR & '0');
    process_txn('1','0','0','0', X"AA");
    process_txn('0','1','1','0', GOOD_I2C_ADDR & '0');
    process_txn('0','1','0','0', X"00");
    process_txn('0','1','0','1', X"00");
    


    SimDone <= '1';
    wait;
    -- pragma synthesis_on
  END PROCESS;
  
  clk <= clk_100MHz;
END ARCHITECTURE rtl;

