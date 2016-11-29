--
-- VHDL Architecture PTR3_HVPS_lib.dpram.beh
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 16:03:46 11/10/2016
--
-- A very simple dual-ported RAM design with arbitration
--
-- Read operations always have priority and are guaranteed to
-- complete in one clock cycle.
--
-- Write operations will complete in one clock cycle if there is
-- not a simultaneous read operation. In the event of a simple
-- collision, the write data is stored and the write operation
-- will complete on the next clock cycle without a conflicting
-- read operation. In the event that multiple read operations
-- are being performed back-to-back with no intervening idle
-- cycles, the WrRdy output will be driven low to indicate
-- that write operations during that cycle will not be
-- performed. This allows for a streamlined state machine
-- implementation for write:
--
--   WHEN Wr_1 =>
--     WrEn <= '1';
--     WrAddr <= ADDR;
--     wData <= DATA;
--     next_state <= Wr_2;
--   WHEN Wr_2 =>
--     IF WrRdy = '1' THEN
--       -- Move on to next operation
--       WrEn <= '0';
--       etc.
--       next_state <= Something_else;
--     ELSE
--       next_state <= Wr_2;
--     END IF;
--
-- Since write operations will be guaranteed to be recognized
-- in one clock cycle in the absence of back-to-back read cycles,
-- it is safe to ignore WrRdy when back-to-back read cycles
-- are not possible.

--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY dpram IS
   GENERIC( 
      ADDR_WIDTH : integer range 16 downto 8 := 16;
      MEM_SIZE  : integer := 16;
      WORD_SIZE : integer := 16
   );
   PORT( 
      RdAddr : IN     std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
      RdEn   : IN     std_logic;
      WrAddr : IN     std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
      WrEn   : IN     std_logic;
      clk    : IN     std_ulogic;
      rst    : IN     std_ulogic;
      wData  : IN     std_logic_vector (WORD_SIZE-1 DOWNTO 0);
      WrRdy  : OUT    std_logic;
      rData  : OUT    std_logic_vector (WORD_SIZE-1 DOWNTO 0)
   );

-- Declarations

END dpram ;

--
ARCHITECTURE beh OF dpram IS
   type Data_t is array (MEM_SIZE-1 DOWNTO 0) of std_logic_vector(WORD_SIZE-1 DOWNTO 0);
   SIGNAL Data : Data_t;
   SIGNAL WrRdy_int : std_logic;
   SIGNAL WAddr_save : std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
   SIGNAL WData_save : std_logic_vector (WORD_SIZE-1 DOWNTO 0);
BEGIN
  dpram_fsm : PROCESS (clk) IS
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF rst = '1' THEN
        FOR i IN MEM_SIZE-1 DOWNTO 0 LOOP
          Data(i) <= (others => '0');
        END LOOP;
        WrRdy_int <= '1';
        rData <= (others => '0');
      ELSE
        IF RdEn = '1' AND conv_integer(RdAddr) < MEM_SIZE THEN
          rdata <= Data(conv_integer(RdAddr));
          IF WrEn = '1' AND WrRdy_int = '1' AND conv_integer(WrAddr) < MEM_SIZE THEN
            WAddr_save <= WrAddr;
            WData_save <= wData;
            WrRdy_int <= '0';
          END IF;
        ELSIF WrRdy_int <= '0' THEN
          Data(conv_integer(WAddr_save)) <= WData_save;
          WrRdy_int <= '1';
        ELSIF WrEn = '1' AND conv_integer(WrAddr) < MEM_SIZE THEN
          Data(conv_integer(WrAddr)) <= wData;
        END IF;
      END IF;
    END IF;
  END PROCESS;
  
  WrRdy <= WrRdy_Int;
END ARCHITECTURE beh;

