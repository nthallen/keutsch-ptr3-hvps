#include "hvps_status.h"
#include "hvps_channel.h"

hvps_status::hvps_status(QGridLayout *grid, int row) {
  label = new QLabel("Status:");
  grid->addWidget(label, row, 0);
  for (int i=0; i < 4; ++i) {
    int col = i + (i<3 ? 1 : 2);
    dstat[i] = new dstat_tmsbvar(hvps_channel::hvps_base_addr + i);
    disp[i] = new tmdispvar(dstat[i]);
    grid->addWidget(disp[i]->widget, row, col);
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
