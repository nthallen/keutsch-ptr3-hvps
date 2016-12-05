#ifndef HVPS_CHANNEL_H
#define HVPS_CHANNEL_H
#include <QGridLayout>
#include <QString>
#include "tmdispvar.h"
#include "tmsbvar.h"
#include "sbcmdbox.h"

class hvps_channel {
public:
  hvps_channel(int chan, QString name, QGridLayout *grid, int row,
               QString units2);
  ~hvps_channel();
  void acquire();
  static const uint16_t hvps_base_addr = 0x50;
  static const uint16_t setpoint_offset = 0;
  static const uint16_t dac_offset = 1;
  static const uint16_t adc0_offset = 2;
  static const uint16_t adc1_offset = 3;
private:
  int channel;
  sbcmdbox *cmd;
  tmdispvar *setpoint;
  tmdispvar *readback;
  tmdispvar *readback2;
  tmsbvar *setpoint_var;
  tmsbvar *readback_var;
  tmsbvar *readback2_var;
};

#endif // HVPS_CHANNEL_H
