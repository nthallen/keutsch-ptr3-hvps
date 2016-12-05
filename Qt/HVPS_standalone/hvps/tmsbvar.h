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
  virtual QString convertedText();

signals:
  void valueUpdated(bool);

protected:
  uint16_t value;
private:
  uint16_t address;
  bool fresh;
  bool read_pending;
};

class adc_tmsbvar : public tmsbvar {
public:
  adc_tmsbvar(uint16_t addr, bool bipolar, double gain, char fmt, int prec);
  ~adc_tmsbvar();
  QString convertedText();
private:
  bool is_bipolar;
  double gain;
  char format;
  int precision;
};

class dstat_tmsbvar : public tmsbvar {
public:
  dstat_tmsbvar(uint16_t addr);
  ~dstat_tmsbvar();
  QString convertedText();
};

#endif // TMSBVAR_H
