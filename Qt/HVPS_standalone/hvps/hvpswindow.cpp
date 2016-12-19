#include <QMessageBox>
#include <QApplication>
#include "hvpswindow.h"
#include "subbus.h"

hvpsWindow::hvpsWindow() {
  state = ws_init;
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
  chans[0] = new hvps_channel(1, "Uql", layout, ++row, 200, 2, "V", 200, 2, "V");
  chans[1] = new hvps_channel(2, "Udrift", layout, ++row, 200, 2, "V", 200, 2, "V");
  chans[2] = new hvps_channel(3, "UTEx", layout, ++row, 400, 2, "V", 400, 2, "V");
  chans[3] = new hvps_channel(4, "USref", layout, ++row, -800, 2, "V", -800, 2, "V");
  chans[4] = new hvps_channel(5, "USDefA", layout, ++row, 2000, 1, "V", 2, 3, "mA");
  chans[5] = new hvps_channel(6, "USDA", layout, ++row, 2000, 1, "V", 2, 3, "mA");
  chans[6] = new hvps_channel(7, "USA", layout, ++row, 3000, 1, "V", 1.3, 3, "mA");
  chans[7] = new hvps_channel(8, "USDefB", layout, ++row, 2000, 1, "V", 2, 3, "mA");
  chans[8] = new hvps_channel(9, "USDB", layout, ++row, 2000, 1, "V", 2, 3, "mA");
  chans[9] = new hvps_channel(14, "UDefI", layout, ++row, 2000, 1, "V", 2, 3, "mA");

  tmstat = new hvps_status(layout, ++row);
  layout->addWidget(status,++row,0,3,hvpsWindow::n_cols);
  status->setStyleSheet("border: 1px solid black");
  connect(&Subbus_client::SB, &Subbus::statusChanged,
          status, &QLabel::setText);
  connect(&Subbus_client::SB, &Subbus::subbus_initialized,
          this, &hvpsWindow::start_acquisition);
  connect(&Subbus_client::SB, &Subbus::subbus_closed,
          this, &hvpsWindow::suspend_acquisition);
  window->setLayout(layout);
  window->show();
  init();
  state = ws_looping;
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

void hvpsWindow::init() {
  Subbus_client::SB.init();
  if (state != ws_slow_poll) {
    state = ws_slow_poll;
  }
}

void hvpsWindow::start_acquisition() {
  poll.stop();
  if (state == ws_slow_poll) {
    disconnect(&poll, &QTimer::timeout, this, &hvpsWindow::init);
  }
  if (state != ws_acquire) {
    connect(&poll, &QTimer::timeout, this, &hvpsWindow::acquire);
    state = ws_acquire;
  }
  poll.setSingleShot(false);
  poll.start(500);
}

void hvpsWindow::suspend_acquisition() {
  poll.stop();
  if (state == ws_acquire) {
    disconnect(&poll, &QTimer::timeout, this, &hvpsWindow::acquire);
  }
  if (state != ws_slow_poll) {
    state = ws_slow_poll;
  }
  QMessageBox::StandardButton response =
    QMessageBox::warning(0, "Serial Connection",
                         "Serial Port Initialization Failed",
                       QMessageBox::Abort|QMessageBox::Retry);
  if (response == QMessageBox::Abort) {
    if (state == ws_looping) {
      QApplication::quit();
    } else {
      exit(0);
    }
  } else {
    init();
  }
}
