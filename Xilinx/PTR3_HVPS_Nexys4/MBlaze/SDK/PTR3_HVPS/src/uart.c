/*
 * uart.c
 *
 *  Created on: Sep 20, 2016
 *      Author: nort
 */
#include "usb_subbus.h"

static XUartLite IUART;

void uart_init(void) {
  int rv = XUartLite_Initialize(&IUART, UART_DEVICE_ID);
  if (rv != XST_SUCCESS) {
    set_fail_reserved(0x4000); // IBD RS232 Init Failure
  } else {
    uart_flush_input();
    uart_flush_output();
  }
}

int uart_recv(char *buf, int nbytes) {
  return XUartLite_Recv(&IUART, buf, nbytes);
}

void uart_send_char(u8 c) {
  while (XUartLite_Send(&IUART, &c, 1) == 0) {
    while (XUartLite_IsSending(&IUART));
  }
}

void uart_flush_input(void) {
  char buf[10];
  while (uart_recv(buf, 10) > 0);
}

void uart_flush_output(void) {
  while (XUartLite_IsSending(&IUART));
}
