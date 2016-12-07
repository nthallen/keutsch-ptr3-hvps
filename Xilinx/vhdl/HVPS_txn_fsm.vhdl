--
-- VHDL Architecture PTR3_HVPS_lib.HVPS_txn.fsm
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 14:53:43 11/ 8/2016
--
-- This engine provides byte-level control of the I2C bus.
-- It interfaces directly to the I2C Master Core designed
-- by Richard Herveille <rherveille@opencores.org> found
-- at opencores.org.
--
-- Commands are issued by asserting Rd or Wr along with
-- optional Start or Stop. Completion of the operation
-- is indicated by Done or Err, but these will not be
-- set until Rd and Wr are cleared. Done and Err will
-- be cleared as soon as a Rd or Wr command is recognized.
--
-- Rd+Start and Wr+Start are both actually write
-- operations, with the 7-bit I2C address in
-- i2c_wdata(7 DOWNTO 1). The correct RW bit is filled
-- in automatically. Rd w/o Start is a read operation,
-- and the result is on i2c_rdata when Done.
-- Rd+Stop will assert NACK after the data is read and
-- then issue a STOP.
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY HVPS_txn IS
   GENERIC( I2C_CLK_PRESCALE : std_logic_vector (15 DOWNTO 0) := X"000E" );
   PORT( 
      Rd        : IN     std_logic;
      Start     : IN     std_logic;
      Stop      : IN     std_logic;
      Wr        : IN     std_logic;
      clk       : IN     std_ulogic;
      i2c_wdata : IN     std_logic_vector (7 DOWNTO 0);
      rst       : IN     std_ulogic;
      wb_ack_o  : IN     std_logic;
      wb_dat_o  : IN     std_logic_vector (7 DOWNTO 0);
      wb_inta_o : IN     std_logic;
      Done      : OUT    std_logic;
      Err       : OUT    std_logic;
      Timeout   : OUT    std_logic;
      i2c_rdata : OUT    std_logic_vector (7 DOWNTO 0);
      wb_adr_i  : OUT    std_logic_vector (2 DOWNTO 0);
      wb_cyc_i  : OUT    std_logic;
      wb_dat_i  : OUT    std_logic_vector (7 DOWNTO 0);
      wb_stb_i  : OUT    std_logic;
      wb_we_i   : OUT    std_logic
   );

-- Declarations

END HVPS_txn ;

--
ARCHITECTURE fsm OF HVPS_txn IS

   TYPE S1_TYPE IS ( S1_INIT, S1_INIT_1, S1_INIT_2, S1_INIT_3,
     S1_IDLE,
     S1_WR, S1_WR_1, S1_WR_2, S1_WR_3,
     S1_RD, S1_RD_1, S1_RD_2,
     S1_STOP, S1_STOP_1, S1_ERR, S1_DONE
   );
   TYPE S2_TYPE IS ( S2_IDLE, S2_WACK, S2_WNACK, S2_WIACK );
 
   -- Declare current and next state signals
   SIGNAL current_s1 : S1_TYPE;
   SIGNAL current_s2 : S2_TYPE;
   SIGNAL Rd_req, Start_req, Stop_req : std_logic;
   SIGNAL IA_req : std_logic;
   SIGNAL timeout_cnt : std_logic_vector (14 DOWNTO 0);
  
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
  machine : PROCESS (clk)
    VARIABLE cmd : std_logic_vector(3 DOWNTO 0);
  BEGIN
    IF (clk'EVENT AND clk = '1') THEN
      IF (rst = '1') THEN
        current_s1 <= S1_INIT;
        current_s2 <= S2_IDLE;
        Done <= '0';
        Err <= '0';
        wb_adr_i <= (others => '0');
        wb_dat_i <= (others => '0');
        wb_we_i <= '0';
        wb_cyc_i <= '0';
        wb_stb_i <= '0';
        i2c_rdata <= (others => '0');
        Rd_req <= '0';
        -- Wr_req <= '0';
        Start_req <= '0';
        Stop_req <= '0';
        IA_req <= '0';
        timeout_cnt <= (others => '0');
        Timeout <= '0';
      ELSE
        
        CASE current_s2 IS
          WHEN S2_IDLE =>
            CASE current_s1 IS
              WHEN S1_INIT =>
                wb_adr_i <= "000";
                wb_dat_i <= I2C_CLK_PRESCALE(7 DOWNTO 0);
                wb_we_i <= '1';
                wb_cyc_i <= '1';
                wb_stb_i <= '1';
                current_s1 <= S1_INIT_1;
                current_s2 <= S2_WACK;
              WHEN S1_INIT_1 => -- waiting for acknowledge to be cleared
                wb_adr_i <= "001";
                wb_dat_i <= I2C_CLK_PRESCALE(15 DOWNTO 8);
                wb_we_i <= '1';
                wb_cyc_i <= '1';
                wb_stb_i <= '1';
                current_s1 <= S1_INIT_2;
                current_s2 <= S2_WACK;
              WHEN S1_INIT_2 =>
                wb_adr_i <= "010";
                wb_dat_i <= X"C0"; -- Control Register: Enable I2C Core, Interrupt
                wb_we_i <= '1';
                wb_cyc_i <= '1';
                wb_stb_i <= '1';
                current_s1 <= S1_INIT_3;
                current_s2 <= S2_WACK;
              WHEN S1_INIT_3 =>
                Done <= '1';
                current_s1 <= S1_IDLE;
                current_s2 <= S2_IDLE;
              WHEN S1_IDLE => -- Waiting for a command
                IF (Rd = '1' OR Wr = '1') THEN
                  -- Wr_req <= Wr;
                  Rd_req <= Rd;
                  Start_req <= Start;
                  Stop_req <= Stop;
                  Done <= '0';
                  Err <= '0';
                  cmd := Wr & Rd & Start & Stop;
                  CASE cmd IS
                    WHEN "1000" => current_s1 <= S1_WR;
                    WHEN "1010" => current_s1 <= S1_WR;
                    WHEN "1001" => current_s1 <= S1_WR;
                    WHEN "0100" => current_s1 <= S1_RD;
                    WHEN "0110" => current_s1 <= S1_WR;
                    WHEN "0101" => current_s1 <= S1_RD;
                    WHEN OTHERS => current_s1 <= S1_ERR;
                  END CASE;
                ELSE
                  current_s1 <= S1_IDLE;
                END IF;
                current_s2 <= S2_IDLE;
              WHEN S1_WR =>
                wb_adr_i <= "011"; -- data to transmit register
                wb_dat_i(7 DOWNTO 1) <= i2c_wdata(7 DOWNTO 1);
                IF (Start_req = '1') THEN
                  wb_dat_i(0) <= Rd_req;
                ELSE
                  wb_dat_i(0) <= i2c_wdata(0);
                END IF;
                wb_we_i <= '1';
                wb_cyc_i <= '1';
                wb_stb_i <= '1';
                current_s1 <= S1_WR_1;
                current_s2 <= S2_WACK;
              WHEN S1_WR_1 =>
                wb_adr_i <= "100"; -- data to command reg:
                wb_dat_i <= Start_req & Stop_req & "010001"; -- STA, STO, WR, IACK
                wb_we_i <= '1';
                wb_cyc_i <= '1';
                wb_stb_i <= '1';
                IA_req <= '1'; -- will wait for wb_inta_o, then read status
                current_s1 <= S1_WR_2;
                current_s2 <= S2_WACK;
              WHEN S1_WR_2 =>
                wb_adr_i <= "100"; -- status reg
                wb_we_i <= '0';
                wb_cyc_i <= '1';
                wb_stb_i <= '1';
                current_s1 <= S1_WR_3;
                current_s2 <= S2_WACK;
              WHEN S1_WR_3 =>
                IF (wb_dat_o(7) = '0') THEN -- status reg NACK bit
                  current_s1 <= S1_DONE;
                ELSE
                  IF (Stop_req = '1') THEN
                    current_s1 <= S1_ERR;
                  ELSE
                    current_s1 <= S1_STOP;
                  END IF;
                END IF;
                current_s2 <= S2_IDLE;
              WHEN S1_RD =>
                wb_adr_i <= "100"; -- Command Reg: [STO], RD, IACK
                wb_dat_i <= '0' & Stop_req & "10" & Stop_req & "001";
                wb_we_i <= '1';
                wb_cyc_i <= '1';
                wb_stb_i <= '1';
                IA_req <= '1';
                current_s1 <= S1_RD_1;
                current_s2 <= S2_WACK;
              WHEN S1_RD_1 =>
                wb_adr_i <= "011";
                wb_we_i <= '0';
                wb_cyc_i <= '1';
                wb_stb_i <= '1';
                current_s1 <= S1_RD_2;
                current_s2 <= S2_WACK;
              WHEN S1_RD_2 =>
                i2c_rdata <= wb_dat_o;
                current_s1 <= S1_DONE;
                current_s2 <= S2_IDLE;
              WHEN S1_STOP =>
                wb_adr_i <= "100";
                wb_dat_i <= "01000001"; -- STO, IACK
                wb_we_i <= '1';
                wb_cyc_i <= '1';
                wb_stb_i <= '1';
                IA_req <= '1';
                current_s1 <= S1_STOP_1;
                current_s2 <= S2_WACK;
              WHEN S1_STOP_1 =>
                current_s1 <= S1_ERR;
                current_s2 <= S2_IDLE;
              WHEN S1_ERR =>
                IF (Rd = '0' AND Wr = '0') THEN
                  Err <= '1';
                  current_s1 <= S1_IDLE;
                ELSE
                  current_s1 <= S1_ERR;
                END IF;
                current_s2 <= S2_IDLE;
              WHEN S1_DONE =>
                IF (Rd = '0' AND Wr = '0') THEN
                  Done <= '1';
                  current_s1 <= S1_IDLE;
                ELSE
                  current_s1 <= S1_ERR;
                END IF;
                current_s2 <= S2_IDLE;
              WHEN OTHERS =>
                current_s1 <= S1_INIT;
                current_s2 <= S2_IDLE;
            END CASE;
          WHEN S2_WACK =>
            IF (wb_ack_o = '1') THEN
              wb_cyc_i <= '0';
              wb_stb_i <= '0';
              timeout_cnt <= int2slv(20000,15);
              current_s2 <= S2_WNACK;
            ELSE
              current_s2 <= S2_WACK;
            END IF;
          WHEN S2_WNACK =>
            IF (IA_req = '1') THEN
              IF (wb_ack_o = '0' AND wb_inta_o = '0') THEN
                current_s2 <= S2_WIACK;
              ELSE
                current_s2 <= S2_WNACK;
              END IF;
            ELSE
              IF (wb_ack_o = '0') THEN
                current_s2 <= S2_IDLE;
              ELSE
                current_s2 <= S2_WNACK;
              END IF;
            END IF;
          WHEN S2_WIACK =>
            IF (wb_inta_o = '1') THEN
              IA_req <= '0';
              Timeout <= '0';
              current_s2 <= S2_IDLE;
            ELSE
              IF (conv_integer(timeout_cnt) = 0) THEN
                Timeout <= '1';
              ELSE
                timeout_cnt <= timeout_cnt-1;
              END IF;
              current_s2 <= S2_WIACK;
            END IF;
          WHEN OTHERS =>
            current_s2 <= S2_IDLE; -- This is an error
        END CASE;
      END IF;
    END IF;
  END PROCESS machine;
END ARCHITECTURE fsm;

