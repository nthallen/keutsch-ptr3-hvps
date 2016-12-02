#include <QString>
#include "tmsbvar.h"
#include "nortlib.h"

tmsbvar::tmsbvar(uint16_t addr) {
  address = addr;
  value = 0;
  fresh = false;
  read_pending = false;
}

tmsbvar::~tmsbvar() {}

void tmsbvar::acquire() {
  if (read_pending || !fresh) {
    emit valueUpdated(false);
    fresh = false;
  }
  if (!read_pending) {
    read(address);
    fresh = false;
    read_pending = true;
  }
}

void tmsbvar::ready() {
  switch (command) {
    case SBC_READACK:
      switch (cmd_status) {
        case SBS_ACK:
          value = ((reply_data.read_data)>>4)*10 +
                (reply_data.read_data & 0xF);
          read_pending = false;
          fresh = true;
          emit valueUpdated(true);
          break;
        case SBS_NOACK:
          nl_error(1, "No acknowledge reading from %04X",
                   request_data.d1.data);
          read_pending = false;
          break;
        case SBS_TIMEOUT:
          nl_error(1, "Subbus timeout reading from %04X",
                   request_data.d1.data);
          read_pending = false;
          break;
        default:
          nl_error(2, "Unexpected subbus response %d reading from %04X",
                     cmd_status, request_data.d1.data);
          break;
      }
      break;
    case SBC_WRITEACK:
      switch (cmd_status) {
        case SBS_ACK:
          break;
        case SBS_NOACK:
          nl_error(1, "No acknowledge writing to %04X",
                   request_data.d0.address);
          break;
        case SBS_TIMEOUT:
          nl_error(1, "Subbus timeout writing to %04X",
                   request_data.d0.address);
          break;
        default:
          nl_error(2, "Unexpected subbus response %d writing to %04X",
                   cmd_status, request_data.d0.address);
          break;
      }
      break;
    default:
      nl_error(4,"Unexpect command value in tmsbvar::ready()");
  }
}

//  uint16_t rawValue();
//  double convertedValue();
QString tmsbvar::convertedText() {
  return QString::number(value);
}
