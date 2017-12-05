/*
 * usb_subbus.h
 *
 *  Created on: Sep 20, 2016
 *      Author: nort
 */

#ifndef USB_SUBBUS_H_
#define USB_SUBBUS_H_
#include "xparameters.h"
#include "xuartlite.h"

/* BOARD_REV includes the SUBBUS_SUBFUNCTION code (7 for PTR3 HVPS) and the
 * SUBBUS_FEATURES bitmap (in hex). Values are defined in subbus.h
 */
#define BOARD_REV                   "V7:178:PTR3 HVPS Rev A V2.0"
#define CPU_FREQ                    XPAR_CPU_M_AXI_DP_FREQ_HZ
#define SUBBUS_CTRL_DEVICE_ID       XPAR_SUBBUS_CTRL_DEVICE_ID
#define SUBBUS_STATUS_DEVICE_ID     XPAR_SUBBUS_STATUS_DEVICE_ID
#define SUBBUS_ADDR_DEVICE_ID       XPAR_SUBBUS_ADDR_DEVICE_ID
#define SUBBUS_DATA_I_DEVICE_ID     XPAR_SUBBUS_DATA_I_DEVICE_ID
#define SUBBUS_DATA_O_DEVICE_ID     XPAR_SUBBUS_DATA_O_DEVICE_ID
#define UART_DEVICE_ID              XPAR_UARTLITE_0_DEVICE_ID

#define SBCTRL_RD                   0x1
#define SBCTRL_WR                   0x2
#define SBCTRL_CS                   0x4
#define SBCTRL_CE                   0x8
#define SBCTRL_RST                  0x10
#define SBCTRL_TICK                 0x20
#define SBCTRL_ARM                  0x40
#define SBSTAT_DONE                 0x1
#define SBSTAT_ACK                  0x2
#define SBSTAT_INTR                 0x4
#define SBSTAT_TWOSECTO             0x8
#define SUBBUS_FAIL_RESERVED        0xF000
#define SUBBUS_INTA_ADDR            0x0001
#define SUBBUS_BDID_ADDR            0x0002
#define SUBBUS_FAIL_ADDR            0x0004
#define SUBBUS_SWITCHES_ADDR        0x0005

#define EXPRD_NS          1000
#define EXPWR_NS          1000
#define CMDSTRB_NS          500
// #define CMD_RCV_TIMEOUT   (CPU_FREQ/10)
#define ALL_OUT           0x0000
#define ALL_IN            0xFFFF
#define EXPRD_PAD         10
#define EXPWR_PAD         10

void set_fail(unsigned short arg);
void set_fail_reserved(unsigned short arg);
void uart_init(void);
int uart_recv(char *buf, int nbytes);
void uart_send_char(u8 c);
void uart_flush_input(void);
void uart_flush_output(void);


#endif /* USB_SUBBUS_H_ */
