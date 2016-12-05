#ifndef HVPS_STATUS_H
#define HVPS_STATUS_H

#include <QGridLayout>
#include "tmsbvar.h"
#include "tmdispvar.h"

class hvps_status {
public:
  hvps_status(QGridLayout *grid, int row);
  ~hvps_status();
  void acquire();
private:
  dstat_tmsbvar *dstat[4];
  tmdispvar *disp[4];
  QLabel *label;
};

#endif // HVPS_STATUS_H
