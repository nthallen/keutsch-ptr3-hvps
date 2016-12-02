#include "sbcmdbox.h"

sbcmdbox::sbcmdbox(uint16_t addr) {
  address = addr;
  value = 0;
  write_pending = false;
  write_queued = false;
  widget = new QSpinBox();
  widget->setAlignment(Qt::AlignRight);
  widget->setMinimum(0);
  widget->setMaximum(65535);
  widget->setSingleStep(1);
  widget->setValue(value);
  connect(widget, static_cast<void (QSpinBox::*)(int)>(&QSpinBox::valueChanged),
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

void sbcmdbox::valueChanged(int newval) {
  value = newval;
  if (write_pending) {
    write_queued = true;
  } else {
    write(address, value);
    write_queued = false;
    write_pending = true;
  }
}
