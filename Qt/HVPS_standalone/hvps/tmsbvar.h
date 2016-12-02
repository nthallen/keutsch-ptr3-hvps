#ifndef TMSBVAR_H
#define TMSBVAR_H

#include <QObject>
#include <QString>
#include "subbus.h"

/**
 * @brief The tmsbvar class
 * acquire() enqueues a read request. If no read has completed
 * valueUpdated(false) is emitted. When a read is completed,
 * valueUpdated(true) is emitted.
 */
class tmsbvar : public QObject, public Subbus_client {
  Q_OBJECT
public:
  tmsbvar(uint16_t addr);
  ~tmsbvar();
  void acquire();
  void ready();
  uint16_t rawValue();
  double convertedValue();
  QString convertedText();

signals:
  void valueUpdated(bool);

private:
  uint16_t address;
  uint16_t value;
  bool fresh;
  bool read_pending;
};

#endif // TMSBVAR_H
