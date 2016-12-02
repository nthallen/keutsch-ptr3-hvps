#include "sbwriter.h"
#include "nortlib.h"

sbwriter::sbwriter(uint16_t addr) {
  address = addr;
}

sbwriter::~sbwriter() {}

void sbwriter::sbwrite(uint16_t data) {
  write(address, data);
}

void sbwriter::sbwrite(uint16_t addr, uint16_t data) {
  write(addr, data);
}

void sbwriter::ready() {
  if (cmd_status != SBS_ACK) {
    nl_error(1, "Write from sbwriter returned no-ack status");
  }
}
