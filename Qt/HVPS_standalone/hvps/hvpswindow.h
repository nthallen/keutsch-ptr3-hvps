#ifndef HVPSWINDOW_H
#define HVPSWINDOW_H
#include <QObject>
#include <QTimer>
#include <QWidget>
#include <QGridLayout>
#include "hvps_channel.h"
#include "hvps_status.h"

enum hvpsWindowState { ws_init, ws_looping, ws_acquire, ws_slow_poll };

class hvpsWindow : public QObject {
  Q_OBJECT
public:
  hvpsWindow();
  ~hvpsWindow();
  static const int label_col = 0;
  static const int cmd_col = 1;
  static const int set_col = 2;
  static const int read1_col = 3;
  static const int read1_units_col = 4;
  static const int read2_col = 5;
  static const int read2_units_col = 6;
  static const int n_cols = 7;
public slots:
  void acquire();
  void init();
  void start_acquisition();
  void suspend_acquisition();
private:
  QWidget *window;
  QGridLayout *layout;
  hvps_channel *chans[14];
  hvps_status *tmstat;
  QTimer poll;
  QLabel *status;
  hvpsWindowState state;
};

#endif // HVPSWINDOW_H
