#include "hvps_status.h"
#include "hvps_channel.h"
#include "hvpswindow.h"

hvps_status::hvps_status(QGridLayout *grid, int row) {
  label = new QLabel("Status:");
  grid->addWidget(label, row, hvpsWindow::label_col);
  for (int i=0; i < 4; ++i) {
    int cols[4] = {
      hvpsWindow::cmd_col, hvpsWindow::set_col,
      hvpsWindow::read1_col, hvpsWindow::read2_col
    };
    int spans[4] = { 1, 1, 2, 2 };
    dstat[i] = new dstat_tmsbvar(hvps_channel::hvps_base_addr + i);
    disp[i] = new tmdispvar(dstat[i]);
    grid->addWidget(disp[i]->widget, row, cols[i], 1, spans[i]);
  }
}

hvps_status::~hvps_status() {
  delete label;
  for (int i = 0; i < 4; ++i) {
    delete disp[i];
    delete dstat[i];
  }
}

void hvps_status::acquire() {
  for (int i = 0; i < 4; ++i) {
    dstat[i]->acquire();
  }
}
