#include <math.h>
#include "sbcmdbox.h"

sbcmdbox::sbcmdbox(uint16_t addr, int range_in, int prec) {
  address = addr;
  dvalue = 0;
  value = 0;
  range = range_in;
  write_pending = false;
  write_queued = false;
  widget = new QDoubleSpinBox();
  widget->setAlignment(Qt::AlignRight);
  widget->setRange(0,range);
  widget->setSingleStep(pow(10.,-prec));
  widget->setValue(value);
  connect(widget, static_cast<void (QDoubleSpinBox::*)(double)>(&QDoubleSpinBox::valueChanged),
          this, &sbcmdbox::valueChanged);
}

sbcmdbox::~sbcmdbox() {
  if (widget) {
    delete(widget);
    widget = 0;
  }
}

void sbcmdbox::ready() {
  write_pending = false;
  if (write_queued) {
    write(address, value);
    write_queued = false;
    write_pending = true;
  }
}

void sbcmdbox::valueChanged(double newval) {
  dvalue = newval;
  int ivalue = 65536*dvalue/range;
  if (ivalue >= 65536) {
    ivalue = 65535;
  } else if (ivalue < 0) {
    ivalue = 0;
  }
  value = ivalue;
  if (write_pending) {
    write_queued = true;
  } else {
    write(address, value);
    write_queued = false;
    write_pending = true;
  }
}
