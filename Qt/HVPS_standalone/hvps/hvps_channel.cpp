#include "hvps_channel.h"
/**
 * @brief hvps_channel::hvps_channel
 * @param chan 1-14
 * @param name
 * @param grid
 * @param row
 * @param units
 * @param units2 optional
 */
hvps_channel::hvps_channel(int chan, QString name,
               QGridLayout *grid, int row,
               bool Chan2) {
  QString units("bits");
  QString units2("bits");
  uint16_t base_addr = hvps_base_addr + chan*4;
  grid->addWidget(new QLabel(name + ":"), row, 0);
  cmd = new sbcmdbox(base_addr+setpoint_offset);
  grid->addWidget(cmd->widget, row, 1);

  setpoint_var = new tmsbvar(base_addr+dac_offset);
  setpoint = new tmdispvar(setpoint_var);
  grid->addWidget(setpoint->widget, row, 2);

  readback_var = new tmsbvar(base_addr+adc0_offset);
  readback = new tmdispvar(readback_var);
  grid->addWidget(readback->widget, row, 3);
  grid->addWidget(new QLabel(units),row,4);

  if (Chan2) {
    readback2_var = new tmsbvar(base_addr+adc1_offset);
    readback2 = new tmdispvar(readback2_var);
    grid->addWidget(readback2->widget, row, 5);
    grid->addWidget(new QLabel(units2), row, 6);
  } else {
    readback2_var = 0;
    readback2 = 0;
  }
}

hvps_channel::~hvps_channel() {
  if (readback2_var != 0) {
    delete readback2_var;
    delete readback2;
    readback2_var = 0;
    readback2 = 0;
  }
  if (cmd != 0) {
    delete cmd;
    cmd = 0;
    delete setpoint_var;
    delete setpoint;
    delete readback_var;
    delete readback;
  }
}

void hvps_channel::acquire() {
  setpoint->acquire();
  readback->acquire();
  if (readback2 != 0) {
    readback2->acquire();
  }
}
