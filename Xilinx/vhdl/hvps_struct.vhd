-- VHDL Entity PTR3_HVPS_lib.HVPS.symbol
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 12:58:01 11/29/16
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2013.1b (Build 2)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY HVPS IS
   GENERIC( 
      N_CHANNELS : integer                       := 14;
      BASE_ADDR  : std_logic_vector(15 DOWNTO 0) := X"0030";
      ADDR_WIDTH : integer                       := 16
   );
   PORT( 
      ExpAddr : IN     std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
      ExpRd   : IN     std_ulogic;
      ExpWr   : IN     std_ulogic;
      clk     : IN     std_ulogic;
      rst     : IN     std_ulogic;
      wData   : IN     std_logic_vector (15 DOWNTO 0);
      ExpAck  : OUT    std_ulogic;
      rData   : OUT    std_logic_vector (15 DOWNTO 0);
      scl     : INOUT  std_logic;
      sda     : INOUT  std_logic
   );

-- Declarations

END HVPS ;

--
-- VHDL Architecture PTR3_HVPS_lib.HVPS.struct
--
-- Created:
--          by - nort.UNKNOWN (NORT-XPS14)
--          at - 21:00:08 12/06/16
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2013.1b (Build 2)
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

-- LIBRARY PTR3_HVPS_lib;

ARCHITECTURE struct OF HVPS IS

   -- Architecture declarations

   -- Internal signal declarations
   SIGNAL BdEn      : std_ulogic;
   SIGNAL BdWrEn    : std_ulogic;
   SIGNAL ChanAddr2 : std_logic_vector(3 DOWNTO 0);
   SIGNAL Done      : std_logic;
   SIGNAL Err       : std_logic;
   SIGNAL Rd        : std_logic;
   SIGNAL RdAddr    : std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
   SIGNAL RdEn      : std_ulogic;
   SIGNAL RdStat    : std_logic;
   SIGNAL Start     : std_logic;
   SIGNAL Stop      : std_logic;
   SIGNAL Timeout   : std_logic;
   SIGNAL Wr        : std_logic;
   SIGNAL WrAck2    : std_logic;
   SIGNAL WrAddr1   : std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
   SIGNAL WrEn      : std_ulogic;
   SIGNAL WrEn1     : std_logic;
   SIGNAL WrEn2     : std_logic;
   SIGNAL WrRdy1    : std_logic;
   SIGNAL dpRdEn    : std_logic;
   SIGNAL i2c_rdata : std_logic_vector(7 DOWNTO 0);
   SIGNAL i2c_wdata : std_logic_vector(7 DOWNTO 0);
   SIGNAL wData1    : std_logic_vector(15 DOWNTO 0);
   SIGNAL wData2    : std_logic_vector(15 DOWNTO 0);
   SIGNAL wb_ack_o  : std_logic;
   SIGNAL wb_adr_i  : std_logic_vector(2 DOWNTO 0);
   SIGNAL wb_cyc_i  : std_logic;
   SIGNAL wb_dat_i  : std_logic_vector(7 DOWNTO 0);
   SIGNAL wb_dat_o  : std_logic_vector(7 DOWNTO 0);
   SIGNAL wb_inta_o : std_logic;
   SIGNAL wb_stb_i  : std_logic;
   SIGNAL wb_we_i   : std_logic;


   -- Component Declarations
   COMPONENT HVPS_I2C
   PORT (
      rst       : IN     std_ulogic ;
      wb_adr_i  : IN     std_logic_vector (2 DOWNTO 0);
      wb_cyc_i  : IN     std_logic ;
      wb_dat_i  : IN     std_logic_vector (7 DOWNTO 0);
      wb_stb_i  : IN     std_logic ;
      wb_we_i   : IN     std_logic ;
      scl       : INOUT  std_logic ;
      sda       : INOUT  std_logic ;
      wb_ack_o  : OUT    std_logic ;
      wb_dat_o  : OUT    std_logic_vector (7 DOWNTO 0);
      wb_inta_o : OUT    std_logic ;
      clk       : IN     std_ulogic 
   );
   END COMPONENT;
   COMPONENT HVPS_acq
   GENERIC (
      ADDR_WIDTH : integer range 16 downto 8 := 16;
      WORD_SIZE  : integer                   := 16;
      N_CHANNELS : integer                   := 14
      --CHANCFGBITS : integer                  := 9
   );
   PORT (
      ChanAddr2 : IN     std_logic_vector (3 DOWNTO 0);
      Done      : IN     std_logic ;
      Err       : IN     std_logic ;
      WrEn2     : IN     std_logic ;
      WrRdy1    : IN     std_logic ;
      clk       : IN     std_ulogic ;
      i2c_rdata : IN     std_logic_vector (7 DOWNTO 0);
      rst       : IN     std_ulogic ;
      wData2    : IN     std_logic_vector (15 DOWNTO 0);
      Rd        : OUT    std_logic ;
      Start     : OUT    std_logic ;
      Stop      : OUT    std_logic ;
      Wr        : OUT    std_logic ;
      WrAck2    : OUT    std_logic ;
      WrAddr1   : OUT    std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
      WrEn1     : OUT    std_logic ;
      i2c_wdata : OUT    std_logic_vector (7 DOWNTO 0);
      wData1    : OUT    std_logic_vector (15 DOWNTO 0);
      RdStat    : IN     std_logic ;
      Timeout   : IN     std_logic 
   );
   END COMPONENT;
   COMPONENT HVPS_addr
   GENERIC (
      BASE_ADDR  : std_logic_vector(15 DOWNTO 0) := X"0010";
      ADDR_WIDTH : integer range 16 downto 8     := 16;
      N_CHANNELS : integer                       := 14;
      WORD_SIZE  : integer                       := 16
   );
   PORT (
      ExpAddr   : IN     std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
      RdEn      : IN     std_ulogic ;
      WrAck2    : IN     std_logic ;
      WrEn      : IN     std_ulogic ;
      clk       : IN     std_ulogic ;
      wData     : IN     std_logic_vector (15 DOWNTO 0);
      BdEn      : OUT    std_ulogic ;
      BdWrEn    : OUT    std_ulogic ;
      ChanAddr2 : OUT    std_logic_vector (3 DOWNTO 0);
      RdAddr    : OUT    std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
      WrEn2     : OUT    std_logic ;
      dpRdEn    : OUT    std_logic ;
      wData2    : OUT    std_logic_vector (15 DOWNTO 0);
      RdStat    : OUT    std_logic ;
      rst       : IN     std_ulogic 
   );
   END COMPONENT;
   COMPONENT HVPS_txn
   GENERIC (
      I2C_CLK_PRESCALE : std_logic_vector (15 DOWNTO 0) := X"000E"
   );
   PORT (
      Rd        : IN     std_logic ;
      Start     : IN     std_logic ;
      Stop      : IN     std_logic ;
      Wr        : IN     std_logic ;
      clk       : IN     std_ulogic ;
      i2c_wdata : IN     std_logic_vector (7 DOWNTO 0);
      rst       : IN     std_ulogic ;
      wb_ack_o  : IN     std_logic ;
      wb_dat_o  : IN     std_logic_vector (7 DOWNTO 0);
      wb_inta_o : IN     std_logic ;
      Done      : OUT    std_logic ;
      Err       : OUT    std_logic ;
      Timeout   : OUT    std_logic ;
      i2c_rdata : OUT    std_logic_vector (7 DOWNTO 0);
      wb_adr_i  : OUT    std_logic_vector (2 DOWNTO 0);
      wb_cyc_i  : OUT    std_logic ;
      wb_dat_i  : OUT    std_logic_vector (7 DOWNTO 0);
      wb_stb_i  : OUT    std_logic ;
      wb_we_i   : OUT    std_logic 
   );
   END COMPONENT;
   COMPONENT dpram
   GENERIC (
      ADDR_WIDTH : integer range 16 downto 8 := 16;
      MEM_SIZE   : integer                   := 16;
      WORD_SIZE  : integer                   := 16
   );
   PORT (
      RdAddr : IN     std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
      RdEn   : IN     std_logic ;
      WrAddr : IN     std_logic_vector (ADDR_WIDTH-1 DOWNTO 0);
      WrEn   : IN     std_logic ;
      clk    : IN     std_ulogic ;
      rst    : IN     std_ulogic ;
      wData  : IN     std_logic_vector (WORD_SIZE-1 DOWNTO 0);
      WrRdy  : OUT    std_logic ;
      rData  : OUT    std_logic_vector (WORD_SIZE-1 DOWNTO 0)
   );
   END COMPONENT;
   COMPONENT subbus_io
   GENERIC (
      USE_BD_WR_EN : std_logic := '0'
   );
   PORT (
      BdEn   : IN     std_ulogic;
      BdWrEn : IN     std_ulogic;
      ExpRd  : IN     std_ulogic;
      ExpWr  : IN     std_ulogic;
      F8M    : IN     std_ulogic;
      ExpAck : OUT    std_ulogic;
      RdEn   : OUT    std_ulogic;
      WrEn   : OUT    std_ulogic
   );
   END COMPONENT;

   -- Optional embedded configurations
   -- pragma synthesis_off
-- FOR ALL : HVPS_I2C USE ENTITY PTR3_HVPS_lib.HVPS_I2C;
-- FOR ALL : HVPS_acq USE ENTITY PTR3_HVPS_lib.HVPS_acq;
-- FOR ALL : HVPS_addr USE ENTITY PTR3_HVPS_lib.HVPS_addr;
-- FOR ALL : HVPS_txn USE ENTITY PTR3_HVPS_lib.HVPS_txn;
-- FOR ALL : dpram USE ENTITY PTR3_HVPS_lib.dpram;
-- FOR ALL : subbus_io USE ENTITY PTR3_HVPS_lib.subbus_io;
   -- pragma synthesis_on


BEGIN

   -- Instance port mappings.
   U_0 : HVPS_I2C
      PORT MAP (
         rst       => rst,
         wb_adr_i  => wb_adr_i,
         wb_cyc_i  => wb_cyc_i,
         wb_dat_i  => wb_dat_i,
         wb_stb_i  => wb_stb_i,
         wb_we_i   => wb_we_i,
         scl       => scl,
         sda       => sda,
         wb_ack_o  => wb_ack_o,
         wb_dat_o  => wb_dat_o,
         wb_inta_o => wb_inta_o,
         clk       => clk
      );
   U_2 : HVPS_acq
      GENERIC MAP (
         ADDR_WIDTH => ADDR_WIDTH,
         WORD_SIZE  => 16,
         N_CHANNELS => N_CHANNELS
         --CHANCFGBITS : integer                  := 9
      )
      PORT MAP (
         ChanAddr2 => ChanAddr2,
         Done      => Done,
         Err       => Err,
         WrEn2     => WrEn2,
         WrRdy1    => WrRdy1,
         clk       => clk,
         i2c_rdata => i2c_rdata,
         rst       => rst,
         wData2    => wData2,
         Rd        => Rd,
         Start     => Start,
         Stop      => Stop,
         Wr        => Wr,
         WrAck2    => WrAck2,
         WrAddr1   => WrAddr1,
         WrEn1     => WrEn1,
         i2c_wdata => i2c_wdata,
         wData1    => wData1,
         RdStat    => RdStat,
         Timeout   => Timeout
      );
   U_6 : HVPS_addr
      GENERIC MAP (
         BASE_ADDR  => BASE_ADDR,
         ADDR_WIDTH => ADDR_WIDTH,
         N_CHANNELS => N_CHANNELS,
         WORD_SIZE  => 16
      )
      PORT MAP (
         ExpAddr   => ExpAddr,
         RdEn      => RdEn,
         WrAck2    => WrAck2,
         WrEn      => WrEn,
         clk       => clk,
         wData     => wData,
         BdEn      => BdEn,
         BdWrEn    => BdWrEn,
         ChanAddr2 => ChanAddr2,
         RdAddr    => RdAddr,
         WrEn2     => WrEn2,
         dpRdEn    => dpRdEn,
         wData2    => wData2,
         RdStat    => RdStat,
         rst       => rst
      );
   U_1 : HVPS_txn
      GENERIC MAP (
         I2C_CLK_PRESCALE => X"00BC"
      )
      PORT MAP (
         Rd        => Rd,
         Start     => Start,
         Stop      => Stop,
         Wr        => Wr,
         clk       => clk,
         i2c_wdata => i2c_wdata,
         rst       => rst,
         wb_ack_o  => wb_ack_o,
         wb_dat_o  => wb_dat_o,
         wb_inta_o => wb_inta_o,
         Done      => Done,
         Err       => Err,
         Timeout   => Timeout,
         i2c_rdata => i2c_rdata,
         wb_adr_i  => wb_adr_i,
         wb_cyc_i  => wb_cyc_i,
         wb_dat_i  => wb_dat_i,
         wb_stb_i  => wb_stb_i,
         wb_we_i   => wb_we_i
      );
   U_3 : dpram
      GENERIC MAP (
         ADDR_WIDTH => ADDR_WIDTH,
         MEM_SIZE   => 4*N_CHANNELS+4,
         WORD_SIZE  => 16
      )
      PORT MAP (
         RdAddr => RdAddr,
         RdEn   => dpRdEn,
         WrAddr => WrAddr1,
         WrEn   => WrEn1,
         clk    => clk,
         rst    => rst,
         wData  => wData1,
         WrRdy  => WrRdy1,
         rData  => rData
      );
   U_5 : subbus_io
      GENERIC MAP (
         USE_BD_WR_EN => '1'
      )
      PORT MAP (
         ExpRd  => ExpRd,
         ExpWr  => ExpWr,
         ExpAck => ExpAck,
         F8M    => clk,
         RdEn   => RdEn,
         WrEn   => WrEn,
         BdEn   => BdEn,
         BdWrEn => BdWrEn
      );

END struct;
