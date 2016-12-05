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
          value = reply_data.read_data;
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

adc_tmsbvar::adc_tmsbvar(uint16_t addr, bool bipolar, double gain_in, char fmt, int prec) :
  tmsbvar(addr) {
  is_bipolar = bipolar;
  gain = gain_in;
  format = fmt;
  precision = prec;
}

adc_tmsbvar::~adc_tmsbvar() {}

QString adc_tmsbvar::convertedText() {
  double dval;
  if (is_bipolar) {
    int16_t svalue = (int16_t)value;
    dval = svalue * gain;
  } else {
    dval = value * gain;
  }
  return QString::number(dval, format, precision);
}

dstat_tmsbvar::dstat_tmsbvar(uint16_t addr) :
  tmsbvar(addr) {}

dstat_tmsbvar::~dstat_tmsbvar() {}

QString dstat_tmsbvar::convertedText() {
  return QString("%1").arg((uint)value,4,16,QChar('0')).toUpper();
}
