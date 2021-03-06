-- VHDL Entity i2c_slave_bits.symbol
--
-- Created:
--          by - nort.UNKNOWN (NORT-NBX200T)
--          at - 16:49:14 07/19/2013
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2012.1 (Build 6)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY i2c_slave_bits IS
   GENERIC( 
      I2C_ADDR : std_logic_vector(6 downto 0) := "1000000"
   );
   PORT( 
      clk   : IN     std_ulogic;
      err   : IN     std_ulogic;
      rdata : IN     std_logic_vector (7 DOWNTO 0);
      rst   : IN     std_ulogic;
      scl   : IN     std_logic;
      start : IN     std_ulogic;
      stop  : IN     std_ulogic;
      en    : IN     std_logic;
      WE    : OUT    std_logic;
      wdata : OUT    std_ulogic_vector (7 DOWNTO 0);
      rdreq : OUT    std_logic;
      RE    : INOUT  std_logic;
      sda   : INOUT  std_logic
   );

-- Declarations

END i2c_slave_bits ;

--
-- VHDL Architecture i2c_slave_bits.fsm
--
-- Created:
--          by - nort.UNKNOWN (NORT-NBX200T)
--          at - 16:49:15 07/19/2013
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2012.1 (Build 6)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
 
ARCHITECTURE fsm OF i2c_slave_bits IS

   -- Architecture Declarations
   SIGNAL addd : std_ulogic;  
   SIGNAL nb : unsigned(3 DOWNTO 0);  
   SIGNAL rval : unsigned(7 DOWNTO 0);  
   SIGNAL sclq : std_ulogic;  
   SIGNAL sdaq : std_ulogic;  
   SIGNAL sr : std_logic_vector(7 DOWNTO 0);  

   TYPE STATE_TYPE IS (
      i2cs_stop,
      i2cs_addr0,
      i2cs_addr1,
      i2cs_addr2,
      i2cs_addr3,
      i2cs_w,
      i2cs_w1,
      i2cs_w2,
      i2cs_w3,
      i2cs_r,
      i2cs_r1,
      i2cs_r2,
      i2cs_r3,
      i2cs_r4,
      i2cs_r5,
      i2cs_addr4,
      i2cs_addr5,
      i2cs_w4,
      i2cs_w5,
      i2cs_w6
   );
 
   -- Declare current and next state signals
   SIGNAL current_state : STATE_TYPE;
   SIGNAL next_state : STATE_TYPE;

   -- Declare any pre-registered internal signals
   SIGNAL WE_cld : std_logic ;
   SIGNAL wdata_cld : std_ulogic_vector (7 DOWNTO 0);

BEGIN

   -----------------------------------------------------------------
   clocked_proc : PROCESS ( 
      clk
   )
   -----------------------------------------------------------------
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         IF (rst = '1') THEN
            current_state <= i2cs_stop;
            -- Default Reset Values
            WE_cld <= '0';
            wdata_cld <= (others => '0');
            addd <= '0';
            nb <= (others => '0');
            rval <= X"55";
            sr <= (others => '0');
            rdreq <= '0';
         ELSE
            current_state <= next_state;

            -- Combined Actions
            CASE current_state IS
               WHEN i2cs_stop => 
                  IF (start = '1') THEN 
                     nb <= "0000";
                     addd <= '0';
                  END IF;
               WHEN i2cs_addr0 => 
                  IF (stop = '1') THEN 
                  ELSIF (sclq = '1') THEN 
                     sr(7 downto 1) <= sr(6 downto 0);
                     sr(0) <= sdaq;
                     nb <= nb+1;
                  END IF;
               WHEN i2cs_addr2 => 
                  addd <= '1';
                  rdreq <= sr(0);
               WHEN i2cs_addr3 => 
                  IF (sclq = '0' and
                      (addd = '0' or sr(0) ='0')) THEN 
                     nb <= "0000";
                  ELSIF (sclq = '0' and
                         addd = '1' and
                         sr(0) ='1') THEN 
                     nb <= "0000";
                  END IF;
               WHEN i2cs_w => 
                  IF (stop = '1') THEN 
                  ELSIF (sclq = '1') THEN 
                     sr(7 downto 1) <=
                        sr(6 downto 0);
                     sr(0) <= sdaq;
                     nb <= nb+1;
                  ELSIF (start = '1') THEN 
                     nb <= "0000";
                     addd <= '0';
                  END IF;
               WHEN i2cs_w2 => 
                  wdata_cld <=
                    std_ulogic_vector(sr);
                  WE_cld <= '1';
               WHEN i2cs_w3 => 
                  IF (sclq = '0') THEN 
                     nb <= "0000";
                  END IF;
               WHEN i2cs_r =>
                  rdreq <= '0';
                  IF (RE /= '1') THEN 
                     sr <= CONV_STD_LOGIC_VECTOR(rval,8);
                     rval <= rval+1;
                     nb <= "0000";
                  ELSE
                     sr <= rdata;
                     nb <= "0000";
                  END IF;
               WHEN i2cs_r1 => 
                  IF (stop = '1') THEN 
                  ELSIF (sclq = '1') THEN 
                     nb <= nb+1;
                  END IF;
               WHEN i2cs_r2 => 
                  IF (stop = '1') THEN 
                  ELSIF (sclq = '0' and
                           nb /= conv_unsigned(8,4)) THEN 
                     sr(7 downto 1) <=
                       sr(6 downto 0);
                  END IF;
               WHEN i2cs_r3 =>
                  IF (sclq = '1' AND sdaq = '0') THEN
                    rdreq <= '1';
                  END IF;
               WHEN i2cs_r5 => 
                  IF (start = '1') THEN 
                     nb <= "0000";
                     addd <= '0';
                  END IF;
               WHEN i2cs_addr5 => 
                  IF (sclq = '0') THEN 
                     nb <= "0000";
                  END IF;
               WHEN i2cs_w5 => 
                  IF (sclq = '0') THEN 
                     nb <= "0000";
                  END IF;
               WHEN i2cs_w6 => 
                  WE_cld <= '0';
               WHEN OTHERS =>
                  NULL;
            END CASE;
         END IF;
      END IF;
   END PROCESS clocked_proc;
 
   -----------------------------------------------------------------
   nextstate_proc : PROCESS ( 
      RE,
      addd,
      current_state,
      nb,
      sclq,
      sdaq,
      sr,
      start,
      stop
   )
   -----------------------------------------------------------------
   BEGIN
      CASE current_state IS
         WHEN i2cs_stop => 
            IF (start = '1') THEN 
               next_state <= i2cs_addr0;
            ELSE
               next_state <= i2cs_stop;
            END IF;
         WHEN i2cs_addr0 => 
            IF (stop = '1') THEN 
               next_state <= i2cs_stop;
            ELSIF (sclq = '1') THEN 
               next_state <= i2cs_addr1;
            ELSE
               next_state <= i2cs_addr0;
            END IF;
         WHEN i2cs_addr1 => 
            IF (stop = '1') THEN 
               next_state <= i2cs_stop;
            ELSIF (sclq = '0' and nb /= conv_unsigned(8,4)) THEN 
               next_state <= i2cs_addr0;
            ELSIF (sclq = '0' and
                   nb = conv_unsigned(8,4) and
                   sr(7 downto 1) = I2C_ADDR) THEN 
               next_state <= i2cs_addr2;
            ELSIF (sclq = '0' and nb = 8 and
                   sr(7 downto 1) /= I2C_ADDR) THEN 
               next_state <= i2cs_addr4;
            ELSE
               next_state <= i2cs_addr1;
            END IF;
         WHEN i2cs_addr2 => 
            IF (sclq = '1') THEN 
               next_state <= i2cs_addr3;
            ELSE
               next_state <= i2cs_addr2;
            END IF;
         WHEN i2cs_addr3 => 
            IF (sclq = '0' and
                (addd = '0' or sr(0) ='0')) THEN 
               next_state <= i2cs_w;
            ELSIF (sclq = '0' and
                   addd = '1' and
                   sr(0) ='1') THEN 
               next_state <= i2cs_r;
            ELSE
               next_state <= i2cs_addr3;
            END IF;
         WHEN i2cs_w => 
            IF (stop = '1') THEN 
               next_state <= i2cs_stop;
            ELSIF (sclq = '1') THEN 
               next_state <= i2cs_w1;
            ELSIF (start = '1') THEN 
               next_state <= i2cs_addr0;
            ELSE
               next_state <= i2cs_w;
            END IF;
         WHEN i2cs_w1 => 
            IF (stop = '1') THEN 
               next_state <= i2cs_stop;
            ELSIF (sclq = '0' and nb /= conv_unsigned(8,4)) THEN 
               next_state <= i2cs_w;
            ELSIF (sclq = '0' and
                   nb = conv_unsigned(8,4) and
                   addd = '1') THEN 
               next_state <= i2cs_w2;
            ELSIF (sclq = '0' and
                   nb = conv_unsigned(8,4) and
                   addd = '0') THEN 
               next_state <= i2cs_w4;
            ELSE
               next_state <= i2cs_w1;
            END IF;
         WHEN i2cs_w2 => 
            next_state <= i2cs_w6;
         WHEN i2cs_w3 => 
            IF (sclq = '0') THEN 
               next_state <= i2cs_w;
            ELSIF (stop = '1') THEN 
               next_state <= i2cs_stop;
            ELSE
               next_state <= i2cs_w3;
            END IF;
         WHEN i2cs_r => 
            IF (RE /= '1') THEN 
               next_state <= i2cs_r1;
            ELSE
               next_state <= i2cs_r1;
            END IF;
         WHEN i2cs_r1 => 
            IF (stop = '1') THEN 
               next_state <= i2cs_stop;
            ELSIF (sclq = '1') THEN 
               next_state <= i2cs_r2;
            ELSE
               next_state <= i2cs_r1;
            END IF;
         WHEN i2cs_r2 => 
            IF (stop = '1') THEN 
               next_state <= i2cs_stop;
            ELSIF (sclq = '0' and
                     nb /= conv_unsigned(8,4)) THEN 
               next_state <= i2cs_r1;
            ELSIF (sclq = '0' and
                   nb = conv_unsigned(8,4)) THEN 
               next_state <= i2cs_r3;
            ELSE
               next_state <= i2cs_r2;
            END IF;
         WHEN i2cs_r3 => 
            IF (sclq = '1') THEN 
               next_state <= i2cs_r4;
            ELSE
               next_state <= i2cs_r3;
            END IF;
         WHEN i2cs_r4 => 
            IF (stop = '1') THEN 
               next_state <= i2cs_stop;
            ELSIF (sclq = '0' and
                     sdaq = '0') THEN 
               next_state <= i2cs_r;
            ELSIF (sclq = '0' and
                     sdaq = '1') THEN 
               next_state <= i2cs_r5;
            ELSE
               next_state <= i2cs_r4;
            END IF;
         WHEN i2cs_r5 => 
            IF (start = '1') THEN 
               next_state <= i2cs_addr0;
            ELSE
               next_state <= i2cs_r5;
            END IF;
         WHEN i2cs_addr4 => 
            IF (sclq = '1') THEN 
               next_state <= i2cs_addr5;
            ELSE
               next_state <= i2cs_addr4;
            END IF;
         WHEN i2cs_addr5 => 
            IF (sclq = '0') THEN 
               next_state <= i2cs_w;
            ELSE
               next_state <= i2cs_addr5;
            END IF;
         WHEN i2cs_w4 => 
            IF (sclq = '1') THEN 
               next_state <= i2cs_w5;
            ELSE
               next_state <= i2cs_w4;
            END IF;
         WHEN i2cs_w5 => 
            IF (sclq = '0') THEN 
               next_state <= i2cs_w;
            ELSIF (stop = '1') THEN 
               next_state <= i2cs_stop;
            ELSE
               next_state <= i2cs_w5;
            END IF;
         WHEN i2cs_w6 => 
            IF (sclq = '1') THEN 
               next_state <= i2cs_w3;
            ELSE
               next_state <= i2cs_w6;
            END IF;
         WHEN OTHERS =>
            next_state <= i2cs_stop;
      END CASE;
   END PROCESS nextstate_proc;
 
   -----------------------------------------------------------------
   output_proc : PROCESS ( 
      current_state,
      scl,
      sda,
      sr
   )
   -----------------------------------------------------------------
   BEGIN
      -- Default Assignment
      RE <= 'L';
      sda <= 'Z';
      -- Default Assignment To Internals
      sclq <= To_X01(scl);
      sdaq <= To_X01(sda);

      -- Combined Actions
      IF (en = '1') THEN
        CASE current_state IS
           WHEN i2cs_addr2 => 
              sda <= '0';
           WHEN i2cs_addr3 => 
              sda <= '0';
           WHEN i2cs_w2 => 
              sda <= '0';
           WHEN i2cs_w3 => 
              sda <= '0';
           WHEN i2cs_r1 => 
              sda <= sr(7);
           WHEN i2cs_r2 => 
              sda <= sr(7);
           WHEN i2cs_w6 => 
              sda <= '0';
           WHEN OTHERS =>
              NULL;
        END CASE;
      END IF;
   END PROCESS output_proc;
 
   -- Concurrent Statements
   -- Clocked output assignments
   WE <= WE_cld;
   wdata <= wdata_cld;
END fsm;
