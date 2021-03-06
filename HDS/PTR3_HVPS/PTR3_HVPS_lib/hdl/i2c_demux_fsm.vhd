-- VHDL Entity idx_fpga_lib.i2c_demux.symbol
--
-- Created:
--          by - nort.UNKNOWN (NORT-NBX200T)
--          at - 16:07:45 11/28/2011
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2010.3 (Build 21)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY i2c_demux IS
   PORT( 
      clk    : IN     std_logic;
      di     : IN     std_logic;
      rst    : IN     std_logic;
      doen_o : OUT    std_logic;
      dio    : INOUT  std_logic
   );

-- Declarations

END i2c_demux ;

--
-- VHDL Architecture idx_fpga_lib.i2c_demux.fsm
--
-- Created:
--          by - nort.UNKNOWN (NORT-NBX200T)
--          at - 16:07:45 11/28/2011
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2010.3 (Build 21)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
 
ARCHITECTURE fsm OF i2c_demux IS

   TYPE STATE_TYPE IS (
      s0,
      s1,
      s2
   );
 
   -- Declare current and next state signals
   SIGNAL current_state : STATE_TYPE;
   SIGNAL next_state : STATE_TYPE;

BEGIN

   -----------------------------------------------------------------
   clocked_proc : PROCESS ( 
      clk
   )
   -----------------------------------------------------------------
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         IF (rst = '1') THEN
            current_state <= s0;
         ELSE
            current_state <= next_state;
         END IF;
      END IF;
   END PROCESS clocked_proc;
 
   -----------------------------------------------------------------
   nextstate_proc : PROCESS ( 
      current_state,
      di,
      dio
   )
   -----------------------------------------------------------------
   BEGIN
      CASE current_state IS
         WHEN s0 => 
            IF (dio = '0') THEN 
               next_state <= s1;
            ELSIF (di = '0') THEN 
               next_state <= s2;
            ELSE
               next_state <= s0;
            END IF;
         WHEN s1 => 
            IF (dio /= '0') THEN 
               next_state <= s0;
            ELSE
               next_state <= s1;
            END IF;
         WHEN s2 => 
            IF (di /= '0') THEN 
               next_state <= s0;
            ELSE
               next_state <= s2;
            END IF;
         WHEN OTHERS =>
            next_state <= s0;
      END CASE;
   END PROCESS nextstate_proc;
 
   -----------------------------------------------------------------
   output_proc : PROCESS ( 
      current_state
   )
   -----------------------------------------------------------------
   BEGIN
      -- Default Assignment
      doen_o <= 'Z';
      dio <= 'Z';

      -- Combined Actions
      CASE current_state IS
         WHEN s0 => 
            dio <= 'Z';
            doen_o <= 'Z';
         WHEN s1 => 
            doen_o <= '0';
         WHEN s2 => 
            dio <= '0';
         WHEN OTHERS =>
            NULL;
      END CASE;
   END PROCESS output_proc;
 
END fsm;
