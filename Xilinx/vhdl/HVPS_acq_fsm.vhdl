--
-- VHDL Architecture PTR3_HVPS_lib.HVPS_acq.fsm
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 16:12:58 11/14/2016
--
-- HVPS_acq provides a state machine (or machines) to control
-- the HVPS interfaces. It must:
--   -Initialize and poll the HVPS ADCs and DACs, manipulating the
--    I2C Muxes as necessary.
--   -Write collected data, including communication status, to the
--    dpram so it is accessible to the host computer.
--   -Respond to DAC output commands

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY HVPS_acq IS
   GENERIC( 
      ADDR_WIDTH : integer range 16 downto 8 := 16;
      WORD_SIZE  : integer                   := 16;
      N_CHANNELS : integer                   := 14
   );
   PORT( 
      ChanAddr2 : IN     std_logic_vector (3 DOWNTO 0);
      Done      : IN     std_logic;
      Err       : IN     std_logic;
      WrEn2     : IN     std_logic;
      WrRdy1    : IN     std_logic;
      clk       : IN     std_ulogic;
      i2c_rdata : IN     std_logic_vector (7 DOWNTO 0);
      rst       : IN     std_ulogic;
      wData2    : IN     std_logic_vector (15 DOWNTO 0);
      Rd        : OUT    std_logic;
      Start     : OUT    std_logic;
      Stop      : OUT    std_logic;
      Wr        : OUT    std_logic;
      WrAck2    : OUT    std_logic;
      WrAddr1   : OUT    std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
      WrEn1     : OUT    std_logic;
      i2c_wdata : OUT    std_logic_vector (7 DOWNTO 0);
      wData1    : OUT    std_logic_vector (15 DOWNTO 0);
      RdStat    : IN     std_logic
   );

-- Declarations

END HVPS_acq ;

--
ARCHITECTURE fsm OF HVPS_acq IS
  TYPE State1_t IS (
    S1_TXN, S1_TXN_1,
    S1_RAM,
    S1_MUX_WR, S1_MUX_WR_1, S1_MUX_WR_2, S1_MUX_WR_3,
    S1_ADC_RD, S1_ADC_RD_0, S1_ADC_RD_1, S1_ADC_RD_2, S1_ADC_RD_3,
    S1_ADC_RD_4, S1_ADC_RD_5, S1_ADC_RD_6, S1_ADC_RD_7, S1_ADC_RD_8,
    S1_ADC_RD_9, S1_ADC_RD_10,
    S1_ADC_WR, S1_ADC_WR_1, S1_ADC_WR_2, S1_ADC_WR_3,
    S1_DAC_WR, S1_DAC_WR_1, S1_DAC_WR_2, S1_DAC_WR_3,
    S1_DAC_RD, S1_DAC_RD_1, S1_DAC_RD_2, S1_DAC_RD_3,
    S1_LOOP_ITER, S1_LOOP_ITER_1,
    S1_MUX_ERR, S1_MUX_ERR_1,
    S1_ADC_ERR, S1_ADC_ERR_1,
    S1_DAC_ERR, S1_DAC_ERR_1,
    S1_INIT, S1_INIT_1, S1_INIT_2, S1_INIT_3, S1_INIT_4,
    S1_LOOP, S1_LOOP_1, S1_LOOP_2,
    S1_LOOP_INIT, S1_LOOP_INIT_1, S1_LOOP_INIT_2, S1_LOOP_INIT_2A,
    S1_LOOP_INIT_3, S1_LOOP_INIT_4,
    S1_LOOP_ADCIRD, S1_LOOP_ADCIWR, S1_LOOP_ADCVCFG,
    S1_LOOP_DAC, S1_LOOP_DAC_1, S1_LOOP_DAC_2,
    S1_LOOP1_ITER,
    S1_LOOP2_INIT,
    S1_LOOP_ADCVRD, S1_LOOP_ADCVWR, S1_LOOP_ADCICFG,
    S1_LOOP2_ITER,
    S1_LOOP_END, S1_LOOP_END_1
  );
  SIGNAL crnt_state1 : State1_t;
  SIGNAL txn_err : State1_t;
  SIGNAL txn_nxt : State1_t;
  SIGNAL mux_nxt : State1_t;
  SIGNAL adc_nxt : State1_t;
  SIGNAL dac_nxt : State1_t;
  SIGNAL ram_nxt : State1_t;
  SIGNAL err_recovery_nxt : State1_t;
  SIGNAL loop_end_nxt : State1_t;
  SIGNAL loop_nxt_nxt : State1_t;
  SIGNAL Stat0_init : std_logic_vector(WORD_SIZE-1 DOWNTO 0);
  SIGNAL Stat1_mux : std_logic_vector(WORD_SIZE-1 DOWNTO 0);
  SIGNAL Stat2_adc : std_logic_vector(WORD_SIZE-1 DOWNTO 0);
  SIGNAL Stat3_dac : std_logic_vector(WORD_SIZE-1 DOWNTO 0);
  SIGNAL Fresh : std_logic;
  SIGNAL Chan : std_logic_vector(3 DOWNTO 0);
  SIGNAL RData : std_logic_vector(15 DOWNTO 0);
  SIGNAL adc_wr_ptr : std_logic_vector(7 DOWNTO 0);
  SIGNAL adc_wr_data : std_logic_vector(15 DOWNTO 0);
  SIGNAL dac_reg_data : std_logic_vector(7 DOWNTO 0);
  SIGNAL dac_wr_data : std_logic_vector(15 DOWNTO 0);
  SIGNAL mux_cfg : std_logic_vector(7 DOWNTO 0);
  TYPE Cfg_t is array (0 TO N_CHANNELS-1) of std_logic_vector(5 DOWNTO 0);
  -- Hi-order 3 bits are board address
  -- Next 2 bits are channel address on the board
  -- LSB indicates channel is the last one on the board
  constant ChanCfgs : Cfg_t :=
    ( "000000", "000010", "000100", "000111",
      "001000", "001011",
      "010001",
      "011000", "011011",
      "100001",
      "101000", "101011",
      "110001",
      "111001" );
  constant MUX_I2C_PREFIX : std_logic_vector(3 DOWNTO 0) := "1110";
  constant MUX_DISABLE : std_logic_vector(7 DOWNTO 0) := X"00";
  constant ADC_I2C_ADDR : std_logic_vector(7 DOWNTO 0) := "10010000";
  constant DAC_I2C_ADDR : std_logic_vector(7 DOWNTO 0) := "10011000";
  constant DAC_WR_IO : std_logic_vector(7 DOWNTO 0) := "00110000";
  constant DAC_WR_CTRL : std_logic_vector(7 DOWNTO 0) := "01000000";
  constant LO_THRESH_PTR : std_logic_vector(7 DOWNTO 0) := "00000010";
  constant LO_THRESH : std_logic_vector(15 DOWNTO 0) := X"0010";
  constant HI_THRESH_PTR : std_logic_vector(7 DOWNTO 0) := "00000011";
  constant HI_THRESH : std_logic_vector(15 DOWNTO 0) := X"4010";
  constant ADC_CNV_PTR : std_logic_vector(7 DOWNTO 0) := "00000000";
  constant ADC_CFG_PTR : std_logic_vector(7 DOWNTO 0) := "00000001";
  constant ADC_VOLTAGE_CFG : std_logic_vector(15 DOWNTO 0) := X"9140";
    	-- OS = 1: begin single conversion
    	-- MUX = 001 (AIN0/AIN3) or 000 (AIN0/AIN1)
    	-- PGA = 000 +/-6.144V
    	-- Mode = 1: power-down single-shot mode
    	-- DR = 010 : 32 SPS (fast enough to convert two channels within 0.1 sec)
    	-- COMP_MODE : 0 (traditional with hysteresis)
    	-- COMP_POL : 0 (active low output)
    	-- COMP_LAT : 0 (not latching)
    	-- COMP_QUE : 00 (assert after one)
 	constant ADC_CURRENT_CFG : std_logic_vector(15 DOWNTO 0) := X"B140";
    	-- MUX = 011 (AIN2/AIN3)

  constant DAC_SETPOINT_OFFSET : integer := 4;
  constant DAC_READBACK_OFFSET : integer := 5;
  constant ADC_VOLTAGE_OFFSET : integer := 6;
  constant ADC_CURRENT_OFFSET : integer := 7;
  
  function int2slv(val : IN integer; len : IN integer)
  return std_logic_vector is
    Variable bit : integer range 0 to 16;
    Variable rval : integer range 0 to 65535;
    Variable slv : std_logic_vector(len-1 DOWNTO 0);
  begin
    bit := 0;
    rval := val;
    slv := (others => '0');
    while bit < len loop
      if rval mod 2 > 0 then
        slv(bit) := '1';
      else
        slv(bit) := '0';
      end if;
      rval := rval / 2;
      bit := bit + 1;
    end loop;
    return slv;
  end function int2slv;
BEGIN
  FSM : PROCESS (clk) IS
    Variable ChanCfg : std_logic_vector(5 DOWNTO 0);
 
    PROCEDURE start_txn(W,R,Sta,Sto : IN std_logic;
      wD : IN std_logic_vector(7 DOWNTO 0);
      cur : IN State1_t;
      nxt : IN State1_t;
      err_nxt : IN State1_t ) IS
    BEGIN
      IF Done = '1' OR Err = '1' THEN
        Wr <= W;
        Rd <= R;
        Start <= Sta;
        Stop <= Sto;
        i2c_wdata <= wD;
        txn_err <= err_nxt;
        txn_nxt <= nxt;
        crnt_state1 <= S1_TXN;
      ELSE
        crnt_state1 <= cur;
      END IF;
      return;
    END PROCEDURE start_txn;
    
    PROCEDURE clear_txn(nxt : IN State1_t ) IS
    BEGIN
      Wr <= '0';
      Rd <= '0';
      Start <= '0';
      Stop <= '0';
      crnt_state1 <= nxt;
      return;
    END PROCEDURE clear_txn;
    
    PROCEDURE start_ram(
      Addr : IN integer;
      wData : IN std_logic_vector(15 DOWNTO 0);
      nxt : IN State1_t ) IS
    BEGIN
      WrEn1 <= '1';
      WrAddr1 <= int2slv(Addr,ADDR_WIDTH);
      wData1 <= wData;
      ram_nxt <= nxt;
      crnt_state1 <= S1_RAM;
      return;
    END PROCEDURE start_ram;
    
    PROCEDURE start_mux_wr(
      cfg : IN std_logic_vector(7 DOWNTO 0);
      nxt : IN State1_t ) IS
    BEGIN
      mux_cfg <= cfg;
      mux_nxt <= nxt;
      crnt_state1 <= S1_MUX_WR;
      return;
    END PROCEDURE start_mux_wr;
    
    PROCEDURE start_adc_rd( nxt : IN State1_t ) IS
    BEGIN
      adc_nxt <= nxt;
      crnt_state1 <= S1_ADC_RD;
      return;
    END PROCEDURE start_adc_rd;
    
    PROCEDURE start_adc_wr(
      ptr : IN std_logic_vector(7 DOWNTO 0);
      data : IN std_logic_vector(15 DOWNTO 0);
      nxt : IN State1_t ) IS
    BEGIN
      adc_wr_ptr <= ptr;
      adc_wr_data <= data;
      adc_nxt <= nxt;
      crnt_state1 <= S1_ADC_WR;
      return;
    END PROCEDURE start_adc_wr;
    
    PROCEDURE start_dac_wr(
      reg : IN std_logic_vector(7 DOWNTO 0);
      data : IN std_logic_vector(15 DOWNTO 0);
      nxt : IN State1_t ) IS
    BEGIN
      dac_reg_data <= reg;
      dac_wr_data <= data;
      dac_nxt <= nxt;
      crnt_state1 <= S1_DAC_WR;
      return;
    END PROCEDURE start_dac_wr;
    
    PROCEDURE start_dac_rd(
      nxt : IN State1_t ) IS
    BEGIN
      dac_nxt <= nxt;
      crnt_state1 <= S1_DAC_RD;
      return;
    END PROCEDURE start_dac_rd;
    
    PROCEDURE chan_loop_iterate(
      nxt_nxt : IN State1_t;
      end_nxt : IN State1_t ) IS
    BEGIN
      loop_nxt_nxt <= nxt_nxt;
      loop_end_nxt <= end_nxt;
      crnt_state1 <= S1_LOOP_ITER;
      return;
    END PROCEDURE chan_loop_iterate;
    
    FUNCTION mux_bit(cfg : std_logic_vector(5 DOWNTO 0))
        return std_logic_vector IS
      Variable slv : std_logic_vector(7 DOWNTO 0);
    BEGIN
      CASE cfg(2 DOWNTO 1) IS
        WHEN "00" => slv := "00000001";
        WHEN "01" => slv := "00000010";
        WHEN "10" => slv := "00000100";
        WHEN "11" => slv := "00001000";
        WHEN OTHERS => slv := "00000000";
      END CASE;
      return slv;
    END FUNCTION mux_bit;

    PURE FUNCTION mux_addr(cfg : std_logic_vector(5 DOWNTO 0))
        return std_logic_vector IS
    BEGIN
      return  MUX_I2C_PREFIX & cfg(5 DOWNTO 3) & '0';
    END FUNCTION mux_addr;

    PURE FUNCTION mux_clr_bit(cfg : std_logic_vector(5 DOWNTO 0))
        return std_logic IS
    BEGIN
      return  cfg(0);
    END FUNCTION mux_clr_bit;

  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF rst = '1' THEN
        Fresh <= '0';
        WrEn1 <= '0';
        WrAddr1 <= (others => '0');
        wData1 <= (others => '0');
        WrAck2 <= '0';
        Rd <= '0';
        Wr <= '0';
        Start <= '0';
        Stop <= '0';
        i2c_wdata <= X"00";
        crnt_state1 <= S1_INIT;
      ELSE
        IF RdStat = '1' THEN
          Fresh <= '0';
        END IF;
        CASE crnt_state1 IS
          -- start_txn(): byte-level interface to HVPS_txn
          WHEN S1_TXN =>
            IF Done = '0' AND Err = '0' THEN
              clear_txn(S1_TXN_1);
            ELSE
              crnt_state1 <= S1_TXN;
            END IF;
          WHEN S1_TXN_1 =>
            IF Err = '1' THEN
              crnt_state1 <= txn_err;
            ELSIF Done = '1' THEN
              crnt_state1 <= txn_nxt;
            ELSE
              crnt_state1 <= S1_TXN_1;
            END IF;

          -- start_ram(): Writes to dpram
          WHEN S1_RAM =>
            IF WrRdy1 = '1' THEN
              WrEn1 <= '0';
              crnt_state1 <= ram_nxt;
            ELSE
              crnt_state1 <= S1_RAM;
            END IF;

          -- start_mux_wr(): Write mux configuration
          WHEN S1_MUX_WR =>
            ChanCfg := ChanCfgs(conv_integer(Chan));
            start_txn('1','0','1','0',mux_addr(ChanCfg),S1_MUX_WR, S1_MUX_WR_1, S1_MUX_ERR);
          WHEN S1_MUX_WR_1 =>
            start_txn('1','0','0','1',mux_cfg,S1_MUX_WR_1, S1_MUX_WR_2, S1_MUX_ERR);
          WHEN S1_MUX_WR_2 =>
            IF Stat1_mux(conv_integer(Chan)) = '1' THEN
              Stat1_mux(conv_integer(Chan)) <= '0';
              crnt_state1 <= S1_MUX_WR_3;
            ELSE
              crnt_state1 <= mux_nxt;
            END IF;
          WHEN S1_MUX_WR_3 =>
            start_ram(1,Stat1_mux,mux_nxt);

          -- start_adc_rd(): reads the last conversion value
          WHEN S1_ADC_RD => -- Reads config, then reads data when ready
            start_txn('1','0','1','0',ADC_I2C_ADDR,S1_ADC_RD,S1_ADC_RD_0,S1_ADC_ERR);
          WHEN S1_ADC_RD_0 =>
            start_txn('1','0','0','0',ADC_CFG_PTR,S1_ADC_RD_0,S1_ADC_RD_1,S1_ADC_ERR);
          WHEN S1_ADC_RD_1 =>
            start_txn('0','1','1','0',ADC_I2C_ADDR,S1_ADC_RD_1,S1_ADC_RD_2,S1_ADC_ERR);
          WHEN S1_ADC_RD_2 =>
            start_txn('0','1','0','0',X"00",S1_ADC_RD_2,S1_ADC_RD_3,S1_ADC_ERR);
          WHEN S1_ADC_RD_3 =>
            RData(15 DOWNTO 8) <= i2c_rdata;
            start_txn('0','1','0','1',X"00",S1_ADC_RD_3,S1_ADC_RD_4,S1_ADC_ERR);
          WHEN S1_ADC_RD_4 =>
            RData(7 DOWNTO 0) <= i2c_rdata;
            IF RData(15) = '1' THEN
              crnt_state1 <= S1_ADC_RD_5;
            ELSE
              crnt_state1 <= S1_ADC_RD_1;
            END IF;
          WHEN S1_ADC_RD_5 => -- Conversion is complete, now read channel
            start_txn('1','0','1','0',ADC_I2C_ADDR,S1_ADC_RD_5,S1_ADC_RD_6,S1_ADC_ERR);
          WHEN S1_ADC_RD_6 =>
            start_txn('1','0','0','0',ADC_CNV_PTR,S1_ADC_RD_6,S1_ADC_RD_7,S1_ADC_ERR);
          WHEN S1_ADC_RD_7 =>
            start_txn('0','1','1','0',ADC_I2C_ADDR,S1_ADC_RD_7,S1_ADC_RD_8,S1_ADC_ERR);
          WHEN S1_ADC_RD_8 =>
            start_txn('0','1','0','0',X"00",S1_ADC_RD_8,S1_ADC_RD_9,S1_ADC_ERR);
          WHEN S1_ADC_RD_9 =>
            RData(15 DOWNTO 8) <= i2c_rdata;
            start_txn('0','1','0','1',X"00",S1_ADC_RD_9,S1_ADC_RD_10,S1_ADC_ERR);
          WHEN S1_ADC_RD_10 =>
            RData(7 DOWNTO 0) <= i2c_rdata;
            crnt_state1 <= adc_nxt;

          -- subroutine to write to ADC, started via start_adc_wr()
          WHEN S1_ADC_WR =>
            start_txn('1','0','1','0', ADC_I2C_ADDR,S1_ADC_WR,S1_ADC_WR_1,S1_ADC_ERR);
          WHEN S1_ADC_WR_1 =>
            start_txn('1','0','0','0',adc_wr_ptr,S1_ADC_WR_1,S1_ADC_WR_2,S1_ADC_ERR);
          WHEN S1_ADC_WR_2 =>
            start_txn('1','0','0','0',adc_wr_data(15 DOWNTO 8),
              S1_ADC_WR_2,S1_ADC_WR_3,S1_ADC_ERR);
          WHEN S1_ADC_WR_3 =>
            start_txn('1','0','0','0',adc_wr_data(7 DOWNTO 0),
              S1_ADC_WR_3,adc_nxt,S1_ADC_ERR);

          -- subroutine to write to DAC: chan_loop_iterate()
          WHEN S1_DAC_WR =>
            start_txn('1','0','1','0',DAC_I2C_ADDR,S1_DAC_WR,S1_DAC_WR_1,S1_DAC_ERR);
          WHEN S1_DAC_WR_1 =>
            start_txn('1','0','0','0',dac_reg_data,S1_DAC_WR_1,S1_DAC_WR_2,S1_DAC_ERR);
          WHEN S1_DAC_WR_2 =>
            start_txn('1','0','0','0',dac_wr_data(15 DOWNTO 8),
              S1_DAC_WR_2,S1_DAC_WR_3,S1_DAC_ERR);
          WHEN S1_DAC_WR_3 =>
            start_txn('1','0','0','1',dac_wr_data(7 DOWNTO 0),
              S1_DAC_WR_3,dac_nxt,S1_DAC_ERR);
              
          -- start_dac_rd():
          WHEN S1_DAC_RD =>
            start_txn('0','1','1','0',DAC_I2C_ADDR,S1_DAC_RD,S1_DAC_RD_1,S1_DAC_ERR);
          WHEN S1_DAC_RD_1 =>
            start_txn('0','1','0','0',X"00",S1_DAC_RD_1,S1_DAC_RD_2,S1_DAC_ERR);
          WHEN S1_DAC_RD_2 =>
            RData(15 DOWNTO 8) <= i2c_rdata;
            start_txn('0','1','0','1',X"00",S1_DAC_RD_2,S1_DAC_RD_3,S1_DAC_ERR);
          WHEN S1_DAC_RD_3 =>
            RData(7 DOWNTO 0) <= i2c_rdata;
            crnt_state1 <= dac_nxt;
          
          -- chan_loop_iterate(): End of loop subroutine (since there are two loops)
          WHEN S1_LOOP_ITER =>
            ChanCfg := ChanCfgs(conv_integer(Chan));
            IF mux_clr_bit(ChanCfg) = '1' AND Stat1_mux(conv_integer(Chan)) = '0' THEN
              start_mux_wr(MUX_DISABLE, S1_LOOP_ITER_1);
            ELSE
              crnt_state1 <= S1_LOOP_ITER_1;
            END IF;
          WHEN S1_LOOP_ITER_1 =>
            IF conv_integer(Chan) = N_CHANNELS-1 THEN
              Chan <= (others => '0');
              crnt_state1 <= loop_end_nxt;
            ELSE
              Chan <= Chan+1;
              crnt_state1 <= loop_nxt_nxt;
            END IF;
          
          -- Handle errors from HVPS_txn
          -- Set bit in the Stat1_mux and write to RAM
          -- Go to err_recovery_nxt
          WHEN S1_MUX_ERR =>
            IF Stat1_mux(conv_integer(Chan)) = '0' THEN
              Stat1_mux(conv_integer(Chan)) <= '1';
              crnt_state1 <= S1_MUX_ERR_1;
            ELSE
              crnt_state1 <= err_recovery_nxt;
            END IF;
          WHEN S1_MUX_ERR_1 =>
            start_ram(1,Stat1_mux,err_recovery_nxt);
          
          -- Handle errors from HVPS_txn
          -- Set bit in the Stat2_adc and write to RAM
          -- Go to err_recovery_nxt
          WHEN S1_ADC_ERR =>
            Stat2_adc(conv_integer(Chan)) <= '1';
            crnt_state1 <= S1_ADC_ERR_1;
          WHEN S1_ADC_ERR_1 =>
            start_ram(2,Stat2_adc,err_recovery_nxt);
          
          -- Handle errors from HVPS_txn
          -- Set bit in the Stat2_adc and write to RAM
          -- Go to err_recovery_nxt
          WHEN S1_DAC_ERR =>
            Stat3_dac(conv_integer(Chan)) <= '1';
            crnt_state1 <= S1_DAC_ERR_1;
          WHEN S1_DAC_ERR_1 =>
            start_ram(3,Stat3_dac,err_recovery_nxt);
            
          WHEN S1_INIT =>
            -- reinitialize most outputs
            Stat0_init <= (others => '0');
            Stat1_mux <= (others => '0');
            Stat2_adc <= (others => '0');
            Stat3_dac <= (others => '0');
            Fresh <= '0';
            WrEn1 <= '0';
            WrAck2 <= '0';
            clear_txn(S1_INIT_1);
          WHEN S1_INIT_1 =>
            start_ram(0,Stat0_init,S1_INIT_2);
          WHEN S1_INIT_2 =>
            start_ram(1,Stat1_mux,S1_INIT_3);
          WHEN S1_INIT_3 =>
            start_ram(2,Stat2_adc,S1_INIT_4);
          WHEN S1_INIT_4 =>
            start_ram(3,Stat3_dac,S1_LOOP);

          WHEN S1_LOOP =>
            Fresh <= '1'; -- If still '1' at the end, we have fresh data
            Chan <= (OTHERS => '0');
            err_recovery_nxt <= S1_LOOP1_ITER;
            crnt_state1 <= S1_LOOP_1;
          WHEN S1_LOOP_1 =>
            ChanCfg := ChanCfgs(conv_integer(Chan));
            start_mux_wr(mux_bit(ChanCfg), S1_LOOP_2);
          WHEN S1_LOOP_2 =>
            IF Stat0_init(conv_integer(Chan)) = '0' THEN
              crnt_state1 <= S1_LOOP_INIT;
            ELSE
              crnt_state1 <= S1_LOOP_ADCIRD;
            END IF;
            
          WHEN S1_LOOP_INIT => -- Initialize Channel
            err_recovery_nxt <= S1_LOOP_INIT_2; -- skip to DAC
            start_adc_wr(LO_THRESH_PTR, LO_THRESH, S1_LOOP_INIT_1);
          WHEN S1_LOOP_INIT_1 =>
            start_adc_wr(HI_THRESH_PTR, HI_THRESH, S1_LOOP_INIT_2);
              
          -- Configure DAC if necessary, but defaults look good
          -- Write 0 to DAC
          WHEN S1_LOOP_INIT_2 =>
            err_recovery_nxt <= S1_LOOP_ADCVCFG; -- skip ahead
            start_dac_wr(DAC_WR_CTRL, X"0800", S1_LOOP_INIT_2A);
          WHEN S1_LOOP_INIT_2A =>
            start_dac_wr(DAC_WR_IO, X"0000", S1_LOOP_INIT_3);
          WHEN S1_LOOP_INIT_3 =>
            Stat0_init(conv_integer(Chan)) <= '1';
            start_ram(conv_integer(Chan)*4+DAC_SETPOINT_OFFSET,X"0000",S1_LOOP_INIT_4);
          WHEN S1_LOOP_INIT_4 =>
            start_ram(0,Stat0_init,S1_LOOP_ADCVCFG);

          WHEN S1_LOOP_ADCIRD => -- Read Channel Current Cfg to verify conversion complete
            err_recovery_nxt <= S1_LOOP_DAC;
            start_adc_rd(S1_LOOP_ADCIWR);
          WHEN S1_LOOP_ADCIWR => -- And write current to ram
            start_ram(conv_integer(Chan)*4+ADC_CURRENT_OFFSET,RData,S1_LOOP_ADCVCFG);
            
          WHEN S1_LOOP_ADCVCFG => -- Configure Channel Voltage reading
            err_recovery_nxt <= S1_LOOP_DAC;
            start_adc_wr(ADC_CFG_PTR, ADC_VOLTAGE_CFG, S1_LOOP_DAC);
          WHEN S1_LOOP_DAC =>
            err_recovery_nxt <= S1_LOOP1_ITER;
            IF WrEn2 = '1' AND ChanAddr2 = Chan THEN
              WrAck2 <= '1';
              start_dac_wr(DAC_WR_IO, WData2, S1_LOOP_DAC_1);
            ELSE
              start_dac_rd(S1_LOOP_DAC_2);
            END IF;
          WHEN S1_LOOP_DAC_1 =>
            WrAck2 <= '0';
            start_ram(conv_integer(Chan)*4+DAC_SETPOINT_OFFSET,WData2,S1_LOOP1_ITER);
          WHEN S1_LOOP_DAC_2 =>
            start_ram(conv_integer(Chan)*4+DAC_READBACK_OFFSET,RData,S1_LOOP1_ITER);
          WHEN S1_LOOP1_ITER =>
            chan_loop_iterate(S1_LOOP_1, S1_LOOP2_INIT);
            
          WHEN S1_LOOP2_INIT =>
            err_recovery_nxt <= S1_LOOP2_ITER;
            ChanCfg := ChanCfgs(conv_integer(Chan));
            start_mux_wr(mux_bit(ChanCfg), S1_LOOP_ADCVRD);
          WHEN S1_LOOP_ADCVRD => -- Read latest converted value
            start_adc_rd(S1_LOOP_ADCVWR);
          WHEN S1_LOOP_ADCVWR => -- And write current to ram
            start_ram(conv_integer(Chan)*4+ADC_VOLTAGE_OFFSET,RData,S1_LOOP_ADCICFG);
          WHEN S1_LOOP_ADCICFG => -- Configure Channel Current reading
            start_adc_wr(ADC_CFG_PTR, ADC_CURRENT_CFG, S1_LOOP2_ITER);
          WHEN S1_LOOP2_ITER =>
            chan_loop_iterate(S1_LOOP2_INIT, S1_LOOP_END);
            
          WHEN S1_LOOP_END =>
            Stat0_init(N_CHANNELS) <= Fresh;
            crnt_state1 <= S1_LOOP_END_1;
          WHEN S1_LOOP_END_1 =>
            start_ram(0,Stat0_init,S1_LOOP);
          WHEN OTHERS =>
            crnt_state1 <= S1_INIT;
        END CASE;
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE fsm;

