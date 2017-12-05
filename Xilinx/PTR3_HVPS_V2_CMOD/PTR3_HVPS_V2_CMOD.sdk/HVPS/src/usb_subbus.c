/******************************************************************************
*
* @file usb_subbus
* 
* Listens for commands from USB port (using EPC) 
* and controls the SUBBUS interface
* 
* MODIFICATION HISTORY:
*
* Ver   Who	 Date	 Changes
* ----- --- -------- -----------------------------------------------
* 0.00	mr	11/2/09  Initial release
* 1.00  nta 9/8/10   Full implementation
*
*******************************************************************************/

/***************************** Include Files **********************************/
#include <ctype.h>
#include <stdlib.h>
#include "xil_types.h"
#include "xgpio.h"
#include "xio.h"
#include "string.h"
#include "usb_subbus.h"
//extern void print(char*);


typedef struct {
  unsigned short address;
  unsigned short bitmask;
} board_intr_t;

static const board_intr_t bd_intrs[] = {
};

#define N_INTERRUPTS (sizeof(bd_intrs)/sizeof(board_intr_t))

typedef struct {
  unsigned short intr_id;
  int active;
} interrupt_t;

static interrupt_t interrupts[N_INTERRUPTS];

static void SendUSB(char *);			// Send String Back to Host via USB
static void SendUSB0(char code);
static void SendUSB1(char, unsigned short);
static void SendError(char *code);
static void init_interrupts(void);
static int subbus_read( unsigned short addr, unsigned short *rv );
static int subbus_write( unsigned short addr, unsigned short data);

XGpio Subbus_Addr, Subbus_Data_i, Subbus_Data_o;
XGpio Subbus_Ctrl, Subbus_Status;
#ifdef SUBBUS_FAIL_DEVICE_ID
  XGpio Subbus_Fail;
#endif
#ifdef SUBBUS_FAIL_DEVICE_ID
  XGpio Subbus_Switches;
#endif
static unsigned short subb_ctrl = 0;
static unsigned short fail_reg = 0;

static void init_gpios(void) {
  // Initialize all GPIO's
  XGpio_Initialize(&Subbus_Addr, SUBBUS_ADDR_DEVICE_ID);
  XGpio_Initialize(&Subbus_Data_i, SUBBUS_DATA_I_DEVICE_ID);
  XGpio_Initialize(&Subbus_Data_o, SUBBUS_DATA_O_DEVICE_ID);
  XGpio_Initialize(&Subbus_Status, SUBBUS_STATUS_DEVICE_ID);
  XGpio_Initialize(&Subbus_Ctrl, SUBBUS_CTRL_DEVICE_ID);
#ifdef SUBBUS_FAIL_DEVICE_ID
  XGpio_Initialize(&Subbus_Fail, SUBBUS_FAIL_DEVICE_ID);
#endif
#ifdef SUBBUS_SWITCHES_DEVICE_ID
  XGpio_Initialize(&Subbus_Switches, SUBBUS_SWITCHES_DEVICE_ID);
#endif
}

static void subbus_reset(void) {
  subb_ctrl = 0;
  XGpio_DiscreteWrite(&Subbus_Ctrl, 1, subb_ctrl | SBCTRL_RST);
  XGpio_DiscreteWrite(&Subbus_Ctrl, 1, subb_ctrl);
}

static void init_interrupts(void) {
  int i;
  for ( i = 0; i < N_INTERRUPTS; i++) {
    interrupts[i].active = 0;
  }
}

/**
 * Associates the interrupt at the specified base address with the
 * specified interrupt ID. Does not check to see if the interrupt
 * is already active, since that should be handled in the driver.
 * The only possible error is that the specified address is not
 * in our defined list, so ENOENT.
 * @return non-zero on success. Will return zero if board not listed in table,
 * or no acknowledge detected.
 */
static int intr_attach( int id, unsigned short addr ) {
  int i;
  for ( i = 0; i < N_INTERRUPTS; i++ ) {
    if ( bd_intrs[i].address == addr ) {
      interrupts[i].active = 1;
      interrupts[i].intr_id = id;
      return subbus_write( addr, 0x20 );
    }
  }
  return 0;
}

/**
 * @return non-zero on success. Will return zero if board is not listed in the table
 * or no acknowledge is detected.
 */
static int intr_detach( unsigned short addr ) {
  int i;
  for ( i = 0; i < N_INTERRUPTS; i++ ) {
    if ( bd_intrs[i].address == addr ) {
      interrupts[i].active = 0;
      return subbus_write(addr, 0);
      return 1;
    }
  }
  return 0;
}

static void intr_service(void) {
  unsigned short ivec;
  if ( subbus_read(SUBBUS_INTA_ADDR, &ivec) ) {
    int i;
    for ( i = 0; i < N_INTERRUPTS; i++ ) {
      if (ivec & bd_intrs[i].bitmask) {
        if (interrupts[i].active) {
          SendUSB1('I', interrupts[i].intr_id);
          return;
        } // ### else could send an error, attempt to disable...
      }
    }
  } else SendError("11"); // No ack on INTA
}

/**
 * Reads hex string and sets return value and updates the
 * string pointer to point to the next character after the
 * hex string.
 * @param pointer to pointer to start of hex string
 * @param pointer to return value
 * @return non-zero on error (no number)
 */
static int read_hex( char **sp, unsigned short *rvp) {
  unsigned char *s = (unsigned char *)*sp;
  unsigned short rv = 0;
  if (! isxdigit(*s)) return 1;
  while ( isxdigit(*s)) {
    rv *= 16;
    if (isdigit(*s)) rv += *s - '0';
    else rv += tolower(*s) - 'a' + 10;
    ++s;
  }
  *rvp = rv;
  *sp = (char *)s;
  return 0;
}

static void hex_out(unsigned short data) {
  static char hex[] = { '0', '1', '2', '3', '4', '5', '6', '7',
                    '8','9', 'A', 'B', 'C', 'D', 'E', 'F' };
  if (data & 0xFFF0) {
    if (data & 0xFF00) {
      if (data & 0xF000)
        uart_send_char(hex[(data>>12)&0xF]);
      uart_send_char(hex[(data>>8)&0xF]);
    }
    uart_send_char(hex[(data>>4)&0xF]);
  }
  uart_send_char(hex[data&0xF]);
}

static int pulse_rdwr(uint8_t subb_ctrl) {
  uint8_t subb_status;
  XGpio_DiscreteWrite(&Subbus_Ctrl,1,subb_ctrl);		// Issue EXPRD
  for (;;) {
    subb_status = XGpio_DiscreteRead(&Subbus_Status,1);
    if (subb_status & SBSTAT_DONE) break;
  }
  return (subb_status & SBSTAT_ACK) ? 1 : 0;
}

/**
 * @return non-zero if EXPACK is detected.
 */
static int subbus_read( unsigned short addr, unsigned short *rv ) {
  int expack;
  XGpio_DiscreteWrite(&Subbus_Addr,1,addr);  // put it on ADDR bus
  expack = pulse_rdwr(subb_ctrl | SBCTRL_RD);
  *rv = XGpio_DiscreteRead(&Subbus_Data_i,1); // Read SUBBUS Data
  XGpio_DiscreteWrite(&Subbus_Ctrl,1,subb_ctrl);
  return expack;
}

static int subbus_write( unsigned short addr, unsigned short data) {
  int expack;
  XGpio_DiscreteWrite(&Subbus_Addr,1,addr);  // put it on ADDR bus
  XGpio_DiscreteWrite(&Subbus_Data_o,1,data);  // put it on DATA bus
  expack = pulse_rdwr(subb_ctrl | SBCTRL_WR);
  XGpio_DiscreteWrite(&Subbus_Ctrl,1,subb_ctrl);
  return expack;
}

/**
 * Syntax: M<count>#<addr_range>[,<addr_range>...]
 *   <addr_range>
 *     : <addr>
 *     : <addr>:<incr>:<addr>
 *     : <count>@<addr>
 *     : <addr>|<count>@<addr>
 *        Read count2 from first addr. Read count2 or count words from
 *        second addr, whichever is less.
 * Output string: [Mm]<data>...[E\d+]
 * The output string reports acknowledge for each input address. If there is
 * no acknowledge, a zero value (i.e. 'm0') will be reported. If there is an
 * acknowledge, the hex value read will be returned preceeded by 'M'
 * (e.g. M32B5). If at any point in parsing the command string a syntax error
 * is encountered, and error code is returned to terminate the output.
 * (e.g. M32B5m0M32B6E3)
 */
static void read_multi(char *cmd) {
  unsigned short addr, start, incr, end, count, rep;
  unsigned short result;
  ++cmd;
  if ( read_hex( &cmd, &count ) || count > 500 || *cmd != '#' ) {
    SendError("3");
    return;
  }
  ++cmd; // skip over the '#'
  for (;;) {
    if ( read_hex( &cmd, &addr ) ) {
      SendError("3");
      return;
    }
    if (*cmd == ':' ) {
      ++cmd;
      if ( read_hex( &cmd, &incr) ||
           *cmd++ != ':' ||
           read_hex( &cmd, &end) ||
           incr >= 0x8000 ) {
        SendError("3");
        return;
      }
      rep = count;
    } else if ( *cmd == '@' ) {
      rep = addr;
      incr = 0;
      ++cmd;
      if ( rep > count || read_hex( &cmd, &addr ) ) {
        SendError("3");
        return;
      }
      end = addr;
    } else if (*cmd == '|') {
      if ( subbus_read( addr, &result ) ) {
        uart_send_char('M');
        hex_out(result);
      } else {
        uart_send_char('m');
        uart_send_char('0');
        result = 0;
      }
      ++cmd;
      if ( read_hex( &cmd, &rep ) ) {
        SendError("3");
        return;
      }
      if (result < rep) {
        rep = result;
      }
      if (*cmd != '@') {
        SendError("3");
        return;
      }
      ++cmd;
      if (read_hex(&cmd, &addr)) {
        SendError("3");
        return;
      }
      incr = 0;
      end = addr;
    } else {
      incr = 0;
      rep = 1;
      end = addr;
    }
    for ( start = addr; addr >= start && addr <= end && rep > 0; addr += incr, --rep, --count ) {
      if ( count == 0 ) {
        SendError("3");
        return;
      }
      if ( subbus_read( addr, &result ) ) {
        uart_send_char('M');
        hex_out(result);
      } else {
        uart_send_char('m');
        uart_send_char('0');
      }
    }
    if (*cmd == '\n' || *cmd == '\r') {
      SendUSB("");
      return;
    } else if (*cmd++ != ',') {
      SendError("3");
      return;
    }
  }
}

void set_fail(unsigned short arg) {
  fail_reg = (fail_reg & SUBBUS_FAIL_RESERVED) |
	  (arg & ~SUBBUS_FAIL_RESERVED);
#ifdef SUBBUS_FAIL_DEVICE_ID
  XGpio_DiscreteWrite(&Subbus_Fail,1,fail_reg);
#elif defined(SUBBUS_FAIL_ADDR)
  subbus_write(SUBBUS_FAIL_ADDR, fail_reg);
#endif
}

void set_fail_reserved(unsigned short arg) {
  fail_reg = (fail_reg & ~SUBBUS_FAIL_RESERVED) |
	  (arg & SUBBUS_FAIL_RESERVED);
#ifdef SUBBUS_FAIL_DEVICE_ID
  XGpio_DiscreteWrite(&Subbus_Fail,1,fail_reg);
#elif defined(SUBBUS_FAIL_ADDR)
  subbus_write(SUBBUS_FAIL_ADDR, fail_reg);
#endif
}

static void parse_command(char *cmd) {
  int nargs = 0;
  char cmd_code;
  unsigned short arg1, arg2;
  unsigned short rv;
  int expack;

  switch(*cmd) {
    case 'B':
    case 'f':
    case 'D':
    case 'T':
    case 'A':
    case 'V': nargs = 0; break;
    case 'M': read_multi(cmd); return;
    case 'R':
    case 'C':
    case 'S':
    case 'u':
    case 'F': nargs = 1; break;
    case 'i':
    case 'W': nargs = 2; break;
    case '\r':
    case '\n': SendUSB("0"); return; // special case: NOP
    default: SendError("1"); return; // Code 1: Unrecognized command
  }
  cmd_code = *cmd++;
  if (nargs > 0) {
    if (read_hex(&cmd,&arg1)) {
      SendError("3");
      return;
    }
    if (nargs > 1) {
      if (*cmd++ != ':' || read_hex(&cmd,&arg2)) {
        SendError("3");
        return;
      }
    }
  }
  if (*cmd != '\n' && *cmd != '\r') {
    SendError("3");
    return;
  }
  switch(cmd_code) {
    case 'R':                         // READ with ACK 'R'
      expack = subbus_read(arg1, &rv);
      SendUSB1(expack ? 'R' : 'r', rv);
      break;
    case 'W':                         // WRITE with ACK 'W'
      expack = subbus_write(arg1, arg2);
      SendUSB(expack ? "W" : "w");
      break;
    case 'F':
      set_fail(arg1);
      SendUSB( "F" );
      break;
    case 'f':
#ifdef SUBBUS_FAIL_DEVICE_ID
      arg1 = XGpio_DiscreteRead(&Subbus_Fail,2);
#elif defined(SUBBUS_FAIL_ADDR)
      subbus_read(SUBBUS_FAIL_ADDR, &arg1);
#endif
      SendUSB1('f', arg1);
      break;
    case 'C':
    case 'S':
      { unsigned short bit = (cmd_code == 'C') ? SBCTRL_CE : SBCTRL_CS;
        if (arg1) subb_ctrl |= bit;
        else subb_ctrl &= ~bit;
        XGpio_DiscreteWrite(&Subbus_Ctrl,1,subb_ctrl);
		// xil_printf("ctrl(4): %02X\n", subb_ctrl);
      }
      SendUSB0(cmd_code);
      break;
    case 'B':
      subbus_reset();
      init_interrupts();
      SendUSB("B");
      break;
    case 'V':                         // Board Rev.
      SendUSB(BOARD_REV);             // Respond with Board Rev info
      break;
    case 'D': // Read Switches
#ifdef SUBBUS_SWITCHES_DEVICE_ID
      arg1 = XGpio_DiscreteRead(&Subbus_Switches,1);
#elif defined(SUBBUS_SWITCHES_ADDR)
      subbus_read(SUBBUS_SWITCHES_ADDR, &arg1);
#endif
      SendUSB1('D', arg1);
      break;
    case 'T': // Tick
      subb_ctrl ^= SBCTRL_TICK;
      if ((subb_ctrl & SBCTRL_ARM) == 0) {
        // If we aren't already armed, we need to read the status
        // after arming to make sure the two second timeout
        // is cleared. It can take up to 250ns to clear, which
        // is 17 clock cycles on a 66 MHz uBlaze.
        int i;
        subb_ctrl |= SBCTRL_ARM;
        // xil_printf("ctrl(0): %02X\n", subb_ctrl);
        XGpio_DiscreteWrite(&Subbus_Ctrl,1,subb_ctrl);
        for ( i = 0; i < 20; i++ ) {
          uint8_t subb_status;
          subb_status = XGpio_DiscreteRead(&Subbus_Status,1);
          if ((subb_status & SBSTAT_TWOSECTO) == 0)
            break;
        }
        if (i == 20) { // #### Diagnostic code: temporary
          set_fail_reserved(0x1000);
        }
      } else {
		XGpio_DiscreteWrite(&Subbus_Ctrl,1,subb_ctrl);
		// xil_printf("ctrl(1): %02X\n", subb_ctrl);
      }
      // No return output
      break;
    case 'A': // Disarm 2-second reboot
      subb_ctrl &= ~(SBCTRL_ARM | SBCTRL_CE);
      XGpio_DiscreteWrite(&Subbus_Ctrl,1,subb_ctrl);
	  // xil_printf("ctrl(2): %02X\n", subb_ctrl);
      SendUSB("A");
      break;
    case 'i':
      if ( intr_attach(arg1, arg2))
        SendUSB1('i', arg1);
      else SendError("4");
      break;
    case 'u':
      if ( intr_detach(arg1) )
        SendUSB1('u', arg1);
      else SendError("4");
      break;
    default:                          // Not a command
      SendError("10");       // Should not happen
      break;
  }
}

/******************************************************************************
*
* Main function. Reads data from FTDI chip when available and places it on
* alternating address and data buses
*
* @param    None
* @return   XST_SUCCESS if successful, XST_FAILURE if unsuccessful
* @note     None
*
*******************************************************************************/
#define RECV_BUF_SIZE 256
int main(void) {
  char cmd[RECV_BUF_SIZE];							// Current Command
  int cmd_byte_num = 0;
#ifdef CMD_RCV_TIMEOUT
  int cmd_rcv_timer = 0;
#endif
  
  init_gpios();
  uart_init();
  subbus_reset();
  // print("Startup main()\r\n");
  
  while(1) {
    uint8_t subb_status;
    int nr, i;
    nr = uart_recv(&cmd[cmd_byte_num], RECV_BUF_SIZE-cmd_byte_num-1);
    if (nr > 0) {
#ifdef CMD_RCV_TIMEOUT
      if (cmd_byte_num == 0) cmd_rcv_timer = 0;
#endif
      for (i = 0; i < nr && cmd_byte_num < RECV_BUF_SIZE; ++i) {
        if (cmd[cmd_byte_num] == '\n' || cmd[cmd_byte_num] == '\r') {
          cmd[++cmd_byte_num] = '\0';
          parse_command(cmd);
          cmd_byte_num = 0;
          break;
        } else {
          ++cmd_byte_num;
        }
      }
      if (cmd_byte_num >= RECV_BUF_SIZE-1) {
        SendError("8"); // Error code 8: Too many bytes before NL
        uart_flush_input();
        cmd_byte_num = 0;
      }
#ifdef CMD_RCV_TIMEOUT
    } else if (cmd_byte_num > 0 && ++cmd_rcv_timer > CMD_RCV_TIMEOUT) {
      SendError("2"); // Code 2: Rcv Timeout
      cmd_byte_num = 0;
#endif
    }
    subb_status = XGpio_DiscreteRead(&Subbus_Status,1);
    if ( subb_status & SBSTAT_INTR)
      intr_service();
    if ( (subb_status & SBSTAT_TWOSECTO) && (subb_ctrl & SBCTRL_ARM) ) {
      subb_ctrl &= ~(SBCTRL_ARM | SBCTRL_CE);
      XGpio_DiscreteWrite(&Subbus_Ctrl,1,subb_ctrl);
      // xil_printf("ctrl(3): %02X\n", subb_ctrl);
      set_fail_reserved(0x2000);
    }
  }
  return 0;
}		

/******************************************************************************
*
* SendError(char *code) : Send Error Code Back to Host via USB
*
* @param    Error code string (w/o 'U')
* @return   None
* @note     None
*
*******************************************************************************/
static void SendError(char *code) {
  uart_send_char('U');
  SendUSB(code);
}

/**
 * Sends String Back to Host via USB, appending a newline and
 * strobing the FTDI "Send Immediate" line. Every response
 * should end by calling this function.
 *
 * @param    String to be sent back to Host via USB
 * @return   None
 *
 */
static void SendUSB(char *msg) {
  while (*msg)
    uart_send_char(*msg++);
  uart_send_char('\n');			// End with NL
  uart_flush_output();
}

static  void SendUSB1(char code, unsigned short val) {
  uart_send_char(code);
  hex_out(val);
  SendUSB("");
}

static void SendUSB0(char code) {
  uart_send_char(code);
  SendUSB("");
}
