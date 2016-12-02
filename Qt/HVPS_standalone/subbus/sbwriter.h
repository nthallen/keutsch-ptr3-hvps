#ifndef SBWRITER_H
#define SBWRITER_H
#include "subbus.h"

class sbwriter : public Subbus_client {
public:
  sbwriter(uint16_t addr = 0);
  ~sbwriter();
  void sbwrite(uint16_t data);
  void sbwrite(uint16_t addr, uint16_t data);
  void ready();
private:
  uint16_t address;
};

#endif // SBWRITER_H
