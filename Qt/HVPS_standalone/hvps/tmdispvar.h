#ifndef TMDISPVAR_H
#define TMDISPVAR_H
#include <QLabel>
#include "tmsbvar.h"

class tmdispvar : public QObject {
  Q_OBJECT
public:
  tmdispvar(tmsbvar *sbvar);
  ~tmdispvar();
  void acquire();
  QLabel *widget;

public slots:
  void valueUpdated(bool);
private:
  tmsbvar *var;
  bool flagged_stale;
};

#endif // TMDISPVAR_H
