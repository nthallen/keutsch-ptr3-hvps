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
  chans[0] = new hvps_channel(1, "Uql", layout, ++row, true);
  chans[1] = new hvps_channel(2, "Udrift", layout, ++row, true);
  chans[2] = new hvps_channel(3, "UTEx", layout, ++row, true);
  chans[3] = new hvps_channel(4, "USref", layout, ++row, true);

  layout->addWidget(status,++row,0,3,7);
  connect(&Subbus_client::SB, &Subbus::statusChanged,
          status, &QLabel::setText);
  window->setLayout(layout);
  window->show();
  Subbus_client::SB.init();

  connect(&poll, &QTimer::timeout, this, &hvpsWindow::acquire);
  poll.setSingleShot(false);
  poll.start(250);
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
}
