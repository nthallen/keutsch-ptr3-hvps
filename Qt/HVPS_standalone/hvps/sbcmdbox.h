#ifndef SBCMDBOX_H
#define SBCMDBOX_H
#include <QSpinBox>
#include "subbus.h"

class sbcmdbox : public QObject, public Subbus_client {
  Q_OBJECT

public:
  sbcmdbox(uint16_t addr);
  ~sbcmdbox();
  QSpinBox *widget;
  void ready();

public slots:
  void valueChanged(int);

private:
  uint16_t address;
  uint16_t value;
  bool write_pending;
  bool write_queued;
};

#endif // SBCMDBOX_H
