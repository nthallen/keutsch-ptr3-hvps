#include "tmdispvar.h"

tmdispvar::tmdispvar(tmsbvar *sbvar) {
  var = sbvar;
  widget = new QLabel(var->convertedText());
  widget->setObjectName("tmdispvar");
  widget->setAlignment(Qt::AlignRight);
  widget->setText(var->convertedText());
  widget->setStyleSheet("border:1px solid red");
  flagged_stale = true;
  connect(sbvar, &tmsbvar::valueUpdated, this, &tmdispvar::valueUpdated);
}

tmdispvar::~tmdispvar() {
  if (widget) {
    delete(widget);
    widget = 0;
  }
}

void tmdispvar::acquire() {
  var->acquire();
}

void tmdispvar::valueUpdated(bool success) {
  if (success) {
    widget->setText(var->convertedText());
    if (flagged_stale) {
      widget->setStyleSheet("border:1px solid black");
      flagged_stale = false;
    }
  } else if (!flagged_stale) {
    widget->setStyleSheet("border:1px solid red");
    flagged_stale = true;
  }
}
