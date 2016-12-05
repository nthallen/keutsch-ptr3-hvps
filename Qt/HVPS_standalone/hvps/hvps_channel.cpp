#include "hvps_channel.h"
#include "hvpswindow.h"
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
               QString units2) {
  channel = chan;
  QString units("V");
  uint16_t base_addr = hvps_base_addr + chan*4;
  grid->addWidget(new QLabel(name + ":"), row,
                  hvpsWindow::label_col);
  cmd = new sbcmdbox(base_addr+setpoint_offset);
  grid->addWidget(cmd->widget, row, hvpsWindow::cmd_col);

  setpoint_var = new adc_tmsbvar(base_addr+dac_offset, false, 5.0/65536, 'f', 5);
  // setpoint_var = new tmsbvar(base_addr+dac_offset);
  setpoint = new tmdispvar(setpoint_var);
  grid->addWidget(setpoint->widget, row, hvpsWindow::set_col);

  //readback_var = new tmsbvar(base_addr+adc0_offset);
  readback_var = new adc_tmsbvar(base_addr+adc0_offset, true, 6.144/32768, 'f', 4);
  readback = new tmdispvar(readback_var);
  grid->addWidget(readback->widget, row, hvpsWindow::read1_col);
  grid->addWidget(new QLabel(units),row,
                  hvpsWindow::read1_units_col);

  // readback2_var = new tmsbvar(base_addr+adc1_offset);
  readback2_var = new adc_tmsbvar(base_addr+adc1_offset, true, 6.144/32768, 'f', 4);
  readback2 = new tmdispvar(readback2_var);
  grid->addWidget(readback2->widget, row,
                  hvpsWindow::read2_col);
  grid->addWidget(new QLabel(units2), row,
                  hvpsWindow::read2_units_col);
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
