--
-- VHDL Architecture PTR3_HVPS_lib.HVPS_tester.rtl
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 14:57:23 11/16/2016
--
-- using Mentor Graphics HDL Designer(TM) 2013.1b (Build 2)
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY PTR3_HVPS_lib;
USE PTR3_HVPS_lib.ALL;

ENTITY HVPS_tester IS
  GENERIC( 
    ADDR_WIDTH : integer range 16 DOWNTO 8 := 16
  );
  PORT( 
    ExpAck  : IN     std_logic;
    rData   : IN     std_logic_vector (15 DOWNTO 0);
    ExpAddr : OUT    std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
    ExpRd   : OUT    std_logic;
    ExpWr   : OUT    std_logic;
    clk     : OUT    std_logic;
    rst     : OUT    std_logic;
    wData   : OUT    std_logic_vector (15 DOWNTO 0);
    scl     : INOUT  std_logic;
    sda     : INOUT  std_logic
  );

-- Declarations

END ENTITY HVPS_tester ;

--
ARCHITECTURE rtl OF HVPS_tester IS
  SIGNAL SimDone : std_logic;
  SIGNAL clk_100MHz : std_logic;
  SIGNAL m1_scl : std_logic_vector(4 DOWNTO 0);
  SIGNAL m1_sda : std_logic_vector(4 DOWNTO 0);
  SIGNAL m2_scl : std_logic_vector(4 DOWNTO 0);
  SIGNAL m2_sda : std_logic_vector(4 DOWNTO 0);
  SIGNAL m3_scl : std_logic_vector(4 DOWNTO 0);
  SIGNAL m3_sda : std_logic_vector(4 DOWNTO 0);
  SIGNAL m4_scl : std_logic_vector(4 DOWNTO 0);
  SIGNAL m4_sda : std_logic_vector(4 DOWNTO 0);
  SIGNAL m5_scl : std_logic_vector(4 DOWNTO 0);
  SIGNAL m5_sda : std_logic_vector(4 DOWNTO 0);
  SIGNAL m6_scl : std_logic_vector(4 DOWNTO 0);
  SIGNAL m6_sda : std_logic_vector(4 DOWNTO 0);
  SIGNAL m7_scl : std_logic_vector(4 DOWNTO 0);
  SIGNAL m7_sda : std_logic_vector(4 DOWNTO 0);
  SIGNAL m8_scl : std_logic_vector(4 DOWNTO 0);
  SIGNAL m8_sda : std_logic_vector(4 DOWNTO 0);
  SIGNAL dummy : std_logic;
  SIGNAL ReadData : std_logic_vector(15 DOWNTO 0);
  SIGNAL mux_en : std_logic_vector(8 DOWNTO 1);
  
  COMPONENT i2c_ext_switch
     GENERIC (
        N_SWBITS : NATURAL range 8 downto 2     := 8;
        I2C_ADDR : std_logic_vector(6 downto 0) := "1110000"
     );
     PORT (
        clk   : IN     std_ulogic;
        m_scl : INOUT  std_logic_vector(N_SWBITS DOWNTO 0);
        en    : IN     std_logic;
        m_sda : INOUT  std_logic_vector(N_SWBITS DOWNTO 0);
        rst   : IN     std_ulogic;
        scl   : INOUT  std_logic;
        sda   : INOUT  std_logic
     );
  END COMPONENT i2c_ext_switch;
  
  COMPONENT ads1115
     PORT (
        clk : IN     std_logic;
        rst : IN     std_logic;
        sda : INOUT  std_logic;
        scl : INOUT  std_logic
     );
  END COMPONENT ads1115;
  
  COMPONENT ad5693 IS
    PORT (
      clk : IN std_logic;
      rst : IN std_logic;
      sda : INOUT std_logic;
      scl : IN std_logic
    );
  END COMPONENT ad5693;
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

  Mux1 : i2c_ext_switch
      GENERIC MAP (
         N_SWBITS => 4,
         I2C_ADDR => "1110000"
      )
      PORT MAP (
         clk   => clk_100MHz,
         m_scl => m1_scl,
         m_sda => m1_sda,
         rst   => rst,
         scl   => scl,
         sda   => sda,
         en    => mux_en(1)
      );
  
  adc_1_1 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m1_sda(0),
        scl => m1_scl(0)
     );

  dac_1_1 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m1_sda(0),
        scl => m1_scl(0)
     );

  adc_1_2 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m1_sda(1),
        scl => m1_scl(1)
     );

  dac_1_2 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m1_sda(1),
        scl => m1_scl(1)
     );

  adc_1_3 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m1_sda(2),
        scl => m1_scl(2)
     );

  dac_1_3 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m1_sda(2),
        scl => m1_scl(2)
     );

  adc_1_4 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m1_sda(3),
        scl => m1_scl(3)
     );

  dac_1_4 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m1_sda(3),
        scl => m1_scl(3)
     );

  Mux2 : i2c_ext_switch
      GENERIC MAP (
         N_SWBITS => 4,
         I2C_ADDR => "1110001"
      )
      PORT MAP (
         clk   => clk_100MHz,
         m_scl => m2_scl,
         m_sda => m2_sda,
         rst   => rst,
         scl   => scl,
         sda   => sda,
         en    => mux_en(2)
      );
  
  adc_2_1 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m2_sda(0),
        scl => m2_scl(0)
     );

  dac_2_1 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m2_sda(0),
        scl => m2_scl(0)
     );

  adc_2_2 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m2_sda(1),
        scl => m2_scl(1)
     );

  dac_2_2 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m2_sda(1),
        scl => m2_scl(1)
     );

  Mux3 : i2c_ext_switch
      GENERIC MAP (
         N_SWBITS => 4,
         I2C_ADDR => "1110010"
      )
      PORT MAP (
         clk   => clk_100MHz,
         m_scl => m3_scl,
         m_sda => m3_sda,
         rst   => rst,
         scl   => scl,
         sda   => sda,
         en    => mux_en(3)
      );
  
  adc_3_1 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m3_sda(0),
        scl => m3_scl(0)
     );

  dac_3_1 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m3_sda(0),
        scl => m3_scl(0)
     );

  Mux4 : i2c_ext_switch
      GENERIC MAP (
         N_SWBITS => 4,
         I2C_ADDR => "1110011"
      )
      PORT MAP (
         clk   => clk_100MHz,
         m_scl => m4_scl,
         m_sda => m4_sda,
         rst   => rst,
         scl   => scl,
         sda   => sda,
         en    => mux_en(4)
      );
  
  adc_4_1 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m4_sda(0),
        scl => m4_scl(0)
     );

  dac_4_1 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m4_sda(0),
        scl => m4_scl(0)
     );

  adc_4_2 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m4_sda(1),
        scl => m4_scl(1)
     );

  dac_4_2 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m4_sda(1),
        scl => m4_scl(1)
     );

  Mux5 : i2c_ext_switch
      GENERIC MAP (
         N_SWBITS => 4,
         I2C_ADDR => "1110100"
      )
      PORT MAP (
         clk   => clk_100MHz,
         m_scl => m5_scl,
         m_sda => m5_sda,
         rst   => rst,
         scl   => scl,
         sda   => sda,
         en    => mux_en(5)
      );
  
  adc_5_1 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m5_sda(0),
        scl => m5_scl(0)
     );

  dac_5_1 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m5_sda(0),
        scl => m5_scl(0)
     );

  Mux6 : i2c_ext_switch
      GENERIC MAP (
         N_SWBITS => 4,
         I2C_ADDR => "1110101"
      )
      PORT MAP (
         clk   => clk_100MHz,
         m_scl => m6_scl,
         m_sda => m6_sda,
         rst   => rst,
         scl   => scl,
         sda   => sda,
         en    => mux_en(6)
      );
  
  adc_6_1 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m6_sda(0),
        scl => m6_scl(0)
     );

  dac_6_1 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m6_sda(0),
        scl => m6_scl(0)
     );

  adc_6_2 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m6_sda(1),
        scl => m6_scl(1)
     );

  dac_6_2 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m6_sda(1),
        scl => m6_scl(1)
     );

  Mux7 : i2c_ext_switch
      GENERIC MAP (
         N_SWBITS => 4,
         I2C_ADDR => "1110110"
      )
      PORT MAP (
         clk   => clk_100MHz,
         m_scl => m7_scl,
         m_sda => m7_sda,
         rst   => rst,
         scl   => scl,
         sda   => sda,
         en    => mux_en(7)
      );
  
  adc_7_1 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m7_sda(0),
        scl => m7_scl(0)
     );

  dac_7_1 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m7_sda(0),
        scl => m7_scl(0)
     );

  Mux8 : i2c_ext_switch
      GENERIC MAP (
         N_SWBITS => 4,
         I2C_ADDR => "1110111"
      )
      PORT MAP (
         clk   => clk_100MHz,
         m_scl => m8_scl,
         m_sda => m8_sda,
         rst   => rst,
         scl   => scl,
         sda   => sda,
         en    => mux_en(8)
      );
  
  adc_8_1 : ads1115
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m8_sda(0),
        scl => m8_scl(0)
     );

  dac_8_1 : ad5693
     PORT MAP (
        clk => clk,
        rst => rst,
        sda => m8_sda(0),
        scl => m8_scl(0)
     );


     
  test_proc: PROCESS IS
    -- This sbwr is at the subbus_io component level, not the syscon level
    procedure sbwr(
        addr : IN std_logic_vector(15 DOWNTO 0);
        data : IN std_logic_vector(15 DOWNTO 0);
        AckExpected : std_logic ) is
    begin
      ExpAddr <= addr(ADDR_WIDTH-1 DOWNTO 0);
      wData <= data;
      -- pragma synthesis_off
      wait until clk_100MHz'EVENT AND clk_100MHz = '1';
      ExpWr <= '1';
      for i in 1 to 8 loop
        wait until clk_100MHz'EVENT AND clk_100MHz = '1';
      end loop;
      if AckExpected = '1' then
        assert ExpAck = '1' report "Expected Ack" severity error;
      else
        assert ExpAck = '0' report "Expected no Ack" severity error;
      end if;
      ExpWr <= '0';
      wait until clk_100MHz'EVENT AND clk_100MHz = '1';
      -- pragma synthesis_on
      return;
    end procedure sbwr;
    
    procedure sbrd(
        addr : IN std_logic_vector(15 DOWNTO 0) ) is
    begin
      ExpAddr <= addr(ADDR_WIDTH-1 DOWNTO 0);
      -- pragma synthesis_off
      wait until clk_100MHz'EVENT AND clk_100MHz = '1';
      ExpRd <= '1';
      for i in 1 to 8 loop
        wait until clk_100MHz'EVENT AND clk_100MHz = '1';
      end loop;
      assert ExpAck = '1' report "Expected Ack on sbrd" severity error;
      ReadData <= rData;
      ExpRd <= '0';
      wait until clk_100MHz'EVENT AND clk_100MHz = '1';
      -- pragma synthesis_on
      return;
    end procedure sbrd;
    
    Variable test_opt : integer := 1;
  BEGIN
    ExpAddr <= (others => '0');
    wData <= (others => '0');
    ExpRd <= '0';
    ExpWr <= '0';
    SimDone <= '0';
    sda <= 'H';
    scl <= 'H';
    m1_scl <= (others => 'H');
    m1_sda <= (others => 'H');
    m2_scl <= (others => 'H');
    m2_sda <= (others => 'H');
    m3_scl <= (others => 'H');
    m3_sda <= (others => 'H');
    m4_scl <= (others => 'H');
    m4_sda <= (others => 'H');
    m5_scl <= (others => 'H');
    m5_sda <= (others => 'H');
    m6_scl <= (others => 'H');
    m6_sda <= (others => 'H');
    m7_scl <= (others => 'H');
    m7_sda <= (others => 'H');
    m8_scl <= (others => 'H');
    m8_sda <= (others => 'H');
    mux_en <= (others => '1');
    rst <= '1';
    -- pragma synthesis_off
    wait until clk_100MHz'EVENT AND clk_100MHz = '1';
    wait until clk_100MHz'EVENT AND clk_100MHz = '1';
    rst <= '0';
    wait for 5 ms;
    if (test_opt = 1) then
      mux_en <= (1 => '1', others => '0');
      sbrd(X"0034");
      sbwr(X"0034",X"1234",'1');
      wait for 100 ms;
      sbrd(X"0034");
      assert ReadData = X"1234" report "Readback failed" severity error;
      mux_en(1) <= '0';
      wait for 20 ms;
      mux_en(1) <= '1';
      wait for 20 ms;
      sbrd(X"0034");
      assert ReadData = X"0000" report "Setpoint readback should be zero after reinit"
        severity error;
      sbwr(X"0044",X"4321",'1');
      wait for 20 ms;
      sbrd(X"0044");
      assert ReadData /= X"4321" report "Readback from disabled channel succeeded" severity error;
      sbwr(X"0034",X"1234",'1');
      wait for 100 ms;
      sbrd(X"0034");
      assert ReadData = X"1234" report "Readback after disabled channel failed" severity error;
    else
      wait for 20 ms;
      scl <= '0';
      wait for 20 ms;
      scl <= 'H';
      wait for 80 ms;
    end if;

    SimDone <= '1';
    wait;
    -- pragma synthesis_on
  END PROCESS;

  clk <= clk_100MHz;
  dummy <= 'H';
END ARCHITECTURE rtl;

