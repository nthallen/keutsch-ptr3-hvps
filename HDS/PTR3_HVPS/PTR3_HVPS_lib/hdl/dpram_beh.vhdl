--
-- VHDL Architecture PTR3_HVPS_lib.dpram.beh
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 16:03:46 11/10/2016
--
-- A very simple dual-ported RAM design with arbitration
-- RdAck goes high when rData is valid. Maximum latency is 2 clocks
--   RdAck goes low after RdEn goes low
-- WrAck goes high when data has been stored
--   WrAck goes low after WrEn goes low
-- RdAck is guaranteed to follow one clock behind RdEn
-- WrAck is guaranteed to be one or two clocks behind WrEn
--
-- This could be improved to guarantee instant ack for both Rd and Wr,
-- although one or the other will always need to be delayed at least one
-- clock.
--
-- The bidirectional handshake limits the throughput to half the
-- clock rate. That is fine for this implementation.

--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY dpram IS
   GENERIC (
     MEM_SIZE : integer := 16;
     WORD_SIZE : integer := 16
   );
   PORT( 
      RdAddr  : IN     std_logic_vector (15 DOWNTO 0);
      RdEn    : IN     std_logic;
      WrAddr1 : IN     std_logic_vector (15 DOWNTO 0);
      WrEn1   : IN     std_logic;
      clk     : IN     std_ulogic;
      rst     : IN     std_ulogic;
      wData1  : IN     std_logic_vector (WORD_SIZE-1 DOWNTO 0);
      RdAck   : OUT    std_logic;
      WrAck   : OUT    std_logic;
      rData   : OUT    std_logic_vector (WORD_SIZE-1 DOWNTO 0)
   );

-- Declarations

END dpram ;

--
ARCHITECTURE beh OF dpram IS
   type Data_t is array (MEM_SIZE-1 DOWNTO 0) of std_logic_vector(WORD_SIZE-1 DOWNTO 0);
   SIGNAL Data : Data_t;
   SIGNAL RdAck_Int : std_logic;
   SIGNAL WrAck_Int : std_logic;
BEGIN
  dpram_fsm : PROCESS (clk) IS
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF rst = '1' THEN
        FOR i IN MEM_SIZE-1 DOWNTO 0 LOOP
          Data(i) <= (others => '0');
        END LOOP;
        RdAck_int <= '0';
        WrAck_int <= '0';
        rData <= (others => '0');
      ELSE
        IF RdEn = '1' AND conv_integer(RdAddr) < MEM_SIZE AND RdAck_int = '0' THEN
          rdata <= Data(conv_integer(RdAddr));
          RdAck_int <= '1';
        ELSIF WrEn1 = '1' AND conv_integer(WrAddr1) < MEM_SIZE AND WrAck_int = '0' THEN
          Data(conv_integer(WrAddr1)) <= wData1;
          WrAck_int <= '1';
        END IF;
        IF RdAck_int = '1' AND RdEn = '0' THEN
          RdAck_int <= '0';
        END IF;
        IF WrAck_int = '1' AND WrEn1 = '0' THEN
          WrAck_int <= '0';
        END IF;
      END IF;
    END IF;
  END PROCESS;
  RdAck <= RdAck_Int;
  WrAck <= WrAck_Int;
END ARCHITECTURE beh;

