#ifndef SBCMDBOX_H
#define SBCMDBOX_H
#include <QDoubleSpinBox>
#include "subbus.h"

class sbcmdbox : public QObject, public Subbus_client {
  Q_OBJECT

public:
  sbcmdbox(uint16_t addr);
  ~sbcmdbox();
  QDoubleSpinBox *widget;
  void ready();

public slots:
  void valueChanged(double);

private:
  uint16_t address;
  uint16_t value;
  double dvalue;
  bool write_pending;
  bool write_queued;
};

#endif // SBCMDBOX_H
