#include "hvpswindow.h"
#include "subbus.h"

hvpsWindow::hvpsWindow() {
  window = new QWidget;
  layout = new QGridLayout;
  status = new QLabel("Start");
  int row = 0;
  layout->addWidget(new QLabel("Act"),row,1);
  layout->addWidget(new QLabel("Set"),row,2);
  layout->addWidget(new QLabel("Read"),row,3);
  layout->addWidget(new QLabel("Read2"),row,5);
  for (int i = 0; i < 14; ++i) {
    chans[i] = 0;
  }
  chans[0] = new hvps_channel(1, "Uql", layout, ++row, 200, 1, "V", 200, 1, "V");
  chans[1] = new hvps_channel(2, "Udrift", layout, ++row, 200, 1, "V", 200, 1, "V");
  chans[2] = new hvps_channel(3, "UTEx", layout, ++row, 400, 1, "V", 400, 1, "V");
  chans[3] = new hvps_channel(4, "USref", layout, ++row, -500, 1, "V", -500, 1, "V");
  chans[4] = new hvps_channel(5, "USDefA", layout, ++row, 2000, 0, "V", 2, 3, "mA");
  chans[5] = new hvps_channel(6, "USDA", layout, ++row, 2000, 0, "V", 2, 3, "mA");
  chans[6] = new hvps_channel(7, "USA", layout, ++row, 3000, 0, "V", 1.3, 3, "mA");
  chans[7] = new hvps_channel(8, "USDefB", layout, ++row, 2000, 0, "V", 2, 3, "mA");
  chans[8] = new hvps_channel(9, "USDB", layout, ++row, 2000, 0, "V", 2, 3, "mA");
  chans[9] = new hvps_channel(14, "UDefI", layout, ++row, 2000, 0, "V", 2, 3, "mA");

  tmstat = new hvps_status(layout, ++row);
  layout->addWidget(status,++row,0,3,hvpsWindow::n_cols);
  status->setStyleSheet("border: 1px solid black");
  connect(&Subbus_client::SB, &Subbus::statusChanged,
          status, &QLabel::setText);
  window->setLayout(layout);
  window->show();
  Subbus_client::SB.init();

  connect(&poll, &QTimer::timeout, this, &hvpsWindow::acquire);
  poll.setSingleShot(false);
  poll.start(500);
}

hvpsWindow::~hvpsWindow() {
  for (int i = 0; i < 14; ++i) {
    if (chans[i]
        != 0) {
      delete(chans[i]);
      chans[i] = 0;
    }
  }
  delete(window);
}

void hvpsWindow::acquire() {
  for (int i = 0; i < 14; ++i) {
    if (chans[i] != 0) {
      chans[i]->acquire();
    }
  }
  tmstat->acquire();
}
