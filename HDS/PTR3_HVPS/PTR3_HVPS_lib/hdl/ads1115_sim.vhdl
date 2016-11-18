--
-- VHDL Architecture PTR3_HVPS_lib.ads1115.sim
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 10:50:14 11/17/2016
--
-- using Mentor Graphics HDL Designer(TM) 2013.1b (Build 2)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY ads1115 IS
  PORT (
    clk : IN std_logic;
    rst : IN std_logic;
    sda : INOUT std_logic;
    scl : IN std_logic
  );
END ENTITY ads1115;

--
ARCHITECTURE sim OF ads1115 IS
   SIGNAL rdata : std_logic_vector(7 DOWNTO 0);
   SIGNAL WE    : std_logic;
   SIGNAL start : std_ulogic;
   SIGNAL stop  : std_ulogic;
   SIGNAL wdata : std_ulogic_vector(7 DOWNTO 0);
   SIGNAL RE    : std_logic;
   SIGNAL rdreq : std_logic;
   SIGNAL bytes : std_logic_vector(2 DOWNTO 0);
   SIGNAL ptr   : std_logic_vector(1 DOWNTO 0);
   TYPE regs_t IS array (3 DOWNTO 0) of std_logic_vector(15 DOWNTO 0);
   SIGNAL regs : regs_t;
   TYPE State_t IS (
     S_INIT, S_START, S_RD, S_RD_1,
     S_WR, S_WR_1 );
   SIGNAL crnt_state : State_t;
   SIGNAL oreg : std_logic_vector(15 DOWNTO 0);
   SIGNAL timer : std_logic_vector(23 DOWNTO 0);
   CONSTANT CONVERT_TIME : std_logic_vector(23 DOWNTO 0) := X"2FAF08";
   TYPE cvt_t IS (
     C_IDLE, C_CVTING, C_CVTED, C_CVTED_1 );
   SIGNAL cvt_state : cvt_t;
   SIGNAL creg : std_logic_vector(15 DOWNTO 0);

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
         RE    : INOUT  std_logic;
         sda   : INOUT  std_logic;
         rdreq : OUT    std_logic
      );
   END COMPONENT i2c_slave;

BEGIN
  slave : i2c_slave
    GENERIC MAP (
      I2C_ADDR => "1001000"
    )
    PORT MAP (
      clk   => clk,
      rdata => rdata,
      rst   => rst,
      scl   => scl,
      WE    => WE,
      start => start,
      stop  => stop,
      wdata => wdata,
      RE    => RE,
      sda   => sda,
      rdreq => rdreq
    );
  
  fsm : PROCESS (clk) IS
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF rst = '1' THEN
        ptr <= "00";
        regs(0) <= X"0000";
        regs(1) <= X"8000"; -- Not converting
        regs(2) <= X"0000";
        regs(3) <= X"0000";
        cvt_state <= C_IDLE;
        crnt_state <= S_INIT;
        timer <= (others => '0');
      ELSE
        CASE cvt_state IS
          WHEN C_IDLE =>
            IF (timer > 0) THEN
              cvt_state <= C_CVTING;
            ELSE
              cvt_state <= C_IDLE;
            END IF;
          WHEN C_CVTING =>
            IF (timer = 0) THEN
              creg <= regs(1);
              cvt_state <= C_CVTED;
            ELSE
              timer <= timer - 1;
              cvt_state <= C_CVTING;
            END IF;
          WHEN C_CVTED =>
            creg(15) <= '1';
            cvt_state <= C_CVTED_1;
          WHEN C_CVTED_1 =>
            regs(1) <= creg;
            cvt_state <= C_IDLE;
          WHEN OTHERS =>
            cvt_state <= C_IDLE;
        END CASE;
        CASE crnt_state IS
          WHEN S_INIT =>
            IF (start = '1') THEN
              crnt_state <= S_START;
            ELSE
              crnt_state <= S_INIT;
            END IF;
          WHEN S_START =>
            bytes <= "000";
            IF (rdreq = '1') THEN
              oreg <= regs(conv_integer(ptr));
              crnt_state <= S_RD;
            ELSIF (WE = '1') THEN
              crnt_state <= S_WR;
            ELSE
              crnt_state <= S_START;
            END IF;
          WHEN S_RD =>
            IF (bytes = "000") THEN
              RE <= '1';
              rdata <= oreg(15 DOWNTO 8);
            ELSIF (bytes = "001") THEN
              RE <= '1';
              rdata <= oreg(7 DOWNTO 0);
            END IF;
            IF (rdreq = '0') THEN
              bytes <= bytes+1;
              crnt_state <= S_RD_1;
            ELSE
              crnt_state <= S_RD;
            END IF;
          WHEN S_RD_1 =>
            IF (start = '1') THEN
              crnt_state <= S_START;
            ELSIF (rdreq = '1') THEN
              crnt_state <= S_RD;
            ELSE
              crnt_state <= S_RD_1;
            END IF;
          WHEN S_WR =>
            IF (bytes = "000") THEN
              ptr <= wdata(1 DOWNTO 0);
            ELSIF (bytes = "001") THEN
              oreg(15 DOWNTO 8) <= wdata;
            ELSIF (bytes = "010") THEN
              IF (ptr = "01" AND oreg(15) = '1') THEN
                oreg(15) <= '0';
                timer <= CONVERT_TIME;
              END IF;
              oreg(7 DOWNTO 0) <= wdata;
            END IF;
            IF (WE = '0') THEN
              bytes <= bytes + 1;
              crnt_state <= S_WR_1;
            ELSE
              crnt_state <= S_WR;
            END IF;
          WHEN S_WR_1 =>
            IF (bytes = "011") THEN
              regs(conv_integer(ptr)) <= oreg;
            END IF;
            IF (start = '1') THEN
              crnt_state <= S_START;
            ELSIF (WE = '0') THEN
              crnt_state <= S_WR;
            ELSE
              crnt_state <= S_WR_1;
            END IF;
          WHEN OTHERS =>
            crnt_state <= S_INIT;
        END CASE;
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE sim;

