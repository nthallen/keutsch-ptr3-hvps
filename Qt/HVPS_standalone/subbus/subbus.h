#ifndef SUBBUS_H
#define SUBBUS_H
#include <QtSerialPort/QtSerialPort>
#include <QtSerialPort/QSerialPortInfo>
#include <stdint.h>
#include <deque>

/* Subbus subfunction codes: These define the hardware that talks
   to the subbus. It does not talk about the interface between
   the library and the system controller itself.
 */
#define SB_PCICC 1
#define SB_PCICCSIC 2
#define SB_SYSCON 3
#define SB_SYSCON104 4
#define SB_SYSCONDACS 5
#define SB_SIM 6
#define SB_PTR3S 7

/* subbus_features: */
#define SBF_SIC 1		/* SIC Functions */
#define SBF_LG_RAM 2	/* Large NVRAM */
#define SBF_HW_CNTS 4	/* Hardware rst & pwr Counters */
#define SBF_WD 8		/* Watchdog functions */
#define SBF_SET_FAIL 0x10 /* Set failure lamp */
#define SBF_READ_FAIL 0x20 /* Read failure lamps */
#define SBF_READ_SW 0x40 /* Read Switches */
#define SBF_NVRAM 0x80   /* Any NVRAM at all! */
#define SBF_CMDSTROBE 0x100 /* CmdStrobe Function */

class Subbus_client;
class Internal_Subbus_client;

class Subbus : public QObject {

  Q_OBJECT

public:
  Subbus();
  ~Subbus();
  void init();
  int submit(Subbus_client *clt);
  static const int SB_SERUSB_MAX_REQUEST = 256;
  static const int SB_SERUSB_MAX_RESPONSE = 256;
  static const int SUBBUS_NAME_MAX = 80;
  static char subbus_name[SUBBUS_NAME_MAX];
  static uint16_t subbus_version;
  static uint16_t subbus_features;
  static uint16_t subbus_subfunction;

public slots:
  void ProcessData();
  void ProcessTimeout();
  void SerialError(QSerialPort::SerialPortError error);

signals:
  void statusChanged(QString);
  void subbus_initialized();
  void subbus_closed();

private:
  void process_request();
  void process_response(char *);
  void dequeue_request( enum sbd_cmd_status status, int n_args,
    uint16_t arg0, uint16_t arg1, char *s );
  int read_hex( char **sp, unsigned short *arg );
  QString portName;
  QSerialPort *port;
  std::deque<Subbus_client *> ReqQ;
  Subbus_client *cur_req;
  Internal_Subbus_client *IntClt;
  QTimer *timer;
  char rbuf[SB_SERUSB_MAX_RESPONSE];
  int nc;
};

// Used for write
typedef struct {
  uint16_t address;
  uint16_t data;
} subbusd_req_data0;

// Used for read
typedef struct {
  uint16_t data;
} subbusd_req_data1;

typedef struct {
  uint16_t req_len;
  uint16_t n_reads;
  char multread_cmd[256];
} subbus_mread_req;

/* command values */
enum sbd_command { SBC_READACK, SBC_WRITEACK, SBC_SETCMDENBL,
  SBC_SETCMDSTRB, SBC_READSW, SBC_SETFAIL, SBC_READFAIL,
  SBC_TICK, SBC_DISARM, SBC_GETCAPS, SBC_INTATT, SBC_INTDET,
  SBC_READCACHE, SBC_WRITECACHE, SBC_QUIT, SBC_MREAD };

/* status values. Status values less than zero are errors */
enum sbd_cmd_status { SBS_OK, SBS_ACK, SBS_NOACK,
  SBS_REQ_SYNTAX, SBS_RESP_SYNTAX, SBS_RESP_ERROR, SBS_TIMEOUT };
enum sbd_req_type { SBDR_TYPE_INTERNAL, SBDR_TYPE_CLIENT };
enum sbd_req_status { SBDR_IDLE, SBDR_STATUS_QUEUED, SBDR_STATUS_SENT };

class Subbus_client {
public:
  Subbus_client();
  ~Subbus_client();
  int read(uint16_t address);
  int write(uint16_t address, uint16_t data);
  const char *get_subbus_name();
  inline uint16_t subbus_version() { return SB.subbus_version; }
  inline uint16_t subbus_features() { return SB.subbus_features; }
  inline uint16_t subbus_subfunction() { return SB.subbus_subfunction; }
  virtual void ready() = 0;
  enum sbd_command command;
  enum sbd_cmd_status cmd_status;
  enum sbd_req_type req_type;
  enum sbd_req_status req_status;
  char request[Subbus::SB_SERUSB_MAX_REQUEST];
  union {
    subbusd_req_data0 d0; // write
    subbusd_req_data1 d1; // read
    // subbus_mread_req d4; // mread
  } request_data;
  union {
    uint16_t read_data;
  } reply_data;
  static Subbus SB;
  static bool timed_out;
};

class Internal_Subbus_client : Subbus_client {
public:
  int identify_board();
  void ready();
};

#endif // SUBBUS_H
