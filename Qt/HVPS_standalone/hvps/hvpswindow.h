#ifndef HVPSWINDOW_H
#define HVPSWINDOW_H
#include <QObject>
#include <QTimer>
#include <QWidget>
#include <QGridLayout>
#include "hvps_channel.h"

class hvpsWindow : public QObject {
  Q_OBJECT
public:
  hvpsWindow();
  ~hvpsWindow();
public slots:
  void acquire();
private:
  QWidget *window;
  QGridLayout *layout;
  hvps_channel *chans[14];
  QTimer poll;
  QLabel *status;
};

#endif // HVPSWINDOW_H
