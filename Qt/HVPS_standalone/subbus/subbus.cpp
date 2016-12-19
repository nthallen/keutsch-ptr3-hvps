#include <QSettings>
// #include <QMessageBox>
#include <QInputDialog>
#include <string.h>
#include <ctype.h>
#include "subbus.h"
#include "nortlib.h"
#include "nl_assert.h"

char Subbus::subbus_name[Subbus::SUBBUS_NAME_MAX];
uint16_t Subbus::subbus_version;
uint16_t Subbus::subbus_features;
uint16_t Subbus::subbus_subfunction;

Subbus::Subbus() {
  port = 0;
  cur_req = 0;
  nc = 0;
  IntClt = new Internal_Subbus_client;
  timer = new QTimer(this);
  timer->setSingleShot(true);
  connect(timer, &QTimer::timeout, this, &Subbus::ProcessTimeout);
  // portName = 0;
}

Subbus::~Subbus() {
  if (port) {
    delete(port);
    port = 0;
  }
  if (IntClt) {
    delete(IntClt);
    IntClt = 0;
  }
}

enum response_status {
  RESP_OK,
  RESP_UNREC, /* Unrecognized code */
  RESP_UNEXP, /* Unexpected code */
  RESP_INV,   /* Invalid response syntax */
  RESP_INTR,  /* Interrupt code */
  RESP_ERR    /* Error from serusb */
};

/**
 * @brief Subbus::ProcessData
 * Slot to handle data ready signal from QSerialPort
 */
void Subbus::ProcessData() {
  // Read from the serial port, appending to rbuf.
  // If a newline is encountered, call process_response()
  int nr = port->read(&rbuf[nc],SB_SERUSB_MAX_RESPONSE-nc);
  if (nr < 0)
    nl_error(3, "Error reading from serusb");
  while (nr > 0) {
    if (rbuf[nc] == '\n') {
      rbuf[nc] = '\0';
      process_response(rbuf);
      nc = 0;
      return;
    }
    ++nc;
    --nr;
  }
}

/** process_response() reviews the response in
   the buffer to determine if it is a suitable
   response to the current request. If so, it
   is returned to the requester.
   process_response() is not responsible for
   advancing to the next request, but it is
   responsible for dequeuing the current
   request if it has been completed.

   The string in resp is guaranteed to have had
   a newline at the end, which was replaced with
   a NUL, so we are guaranteed to have a NUL-
   terminated string.
 */
void Subbus::process_response( char *buf ) {
  response_status status = RESP_OK;
  sbd_cmd_status sbs_ok_status = SBS_OK;
  unsigned short arg0, arg1;
  int n_args = 0;
  char *s = buf;
  char resp_code = *s++;
  char exp_req = '\0';
  int exp_args = 0;
  if ( resp_code == 'M' || resp_code == 'm' )  {
    if ( cur_req != NULL && cur_req->request[0] == 'M' ) {
      // We have to push the parsing into dequeue_request() because we need
      // direct access to the reply structure.
      dequeue_request(SBS_OK, 4, 0, 0, buf);
      return;
    } else {
      status = RESP_UNEXP;
    }
  } else {
    if ( resp_code != '\0' ) {
      // We can process args in the general case
      if (read_hex( &s, &arg0 )) {
        ++n_args;
        if (*s == ':') {
          ++s;
          if ( read_hex( &s, &arg1 ) ) {
            ++n_args;
            if ( *s == ':' ) {
              ++s; // points to name
              ++n_args;
            } else {
              status = RESP_INV;
            }
          } else status = RESP_INV;
        } else if ( *s != '\0' ) {
          status = RESP_INV;
        }
      } else if ( *s != '\0' ) {
        status = RESP_INV;
      }
    }
    // Check response for self-consistency
    // Check that response is appropriate for request
    switch (resp_code) {
      case 'R':
        exp_req = 'R';
        exp_args = 1;
        sbs_ok_status = SBS_ACK;
        break;
      case 'r':
        exp_req = 'R';
        exp_args = 1;
        sbs_ok_status = SBS_NOACK;
        break;
      case 'W':
        exp_req = 'W';
        exp_args = 0;
        sbs_ok_status = SBS_ACK;
        break;
      case 'w':
        exp_req = 'W';
        exp_args = 0;
        sbs_ok_status = SBS_NOACK;
        break;
      case 'V':
        exp_req = 'V';
        exp_args = 3;
        break;
      case 'I':
        status = RESP_INTR;
        exp_req = '\0';
        exp_args = 1;
        break;
      case 'A':
      case 'B':
      case 'S':
      case 'C':
      case 'F':
        exp_req = resp_code;
        exp_args = 0;
        break;
      case '0':
        exp_req = '\n';
        exp_args = 0;
        break;
      case 'D':
      case 'f':
      case 'i':
      case 'u':
        exp_req = resp_code;
        exp_args = 1;
        break;
      case 'E':
        status = RESP_ERR;
        exp_req = '\0';
        exp_args = 1;
        break;
      default:
        status = RESP_UNREC;
        break;
    }
    switch (status) {
      case RESP_OK:
        if ( cur_req == NULL || cur_req->request[0] != exp_req) {
          status = RESP_UNEXP;
          break;
        } // fall through
      case RESP_INTR:
      case RESP_ERR:
        if (n_args != exp_args)
          status = RESP_INV;
        break;
    }
  }
  switch (status) {
    case RESP_OK:
      dequeue_request(sbs_ok_status, n_args, arg0, arg1, s);
      break;
#ifdef SUBBUS_INTERRUPTS
    case RESP_INTR:
      process_interrupt(arg0);
      break;
#endif
    case RESP_UNREC:
      nl_error( 2, "Unrecognized response: '%s'", ascii_escape(buf) );
      break;
    case RESP_UNEXP:
      nl_error( 2, "Unexpected response: '%s'", ascii_escape(buf) );
      break;
    case RESP_INV:
      nl_error( 2, "Invalid response: '%s'", ascii_escape(buf) );
      break;
    case RESP_ERR:
      nl_error( 2, "Error code %s from DACS", ascii_escape(buf) );
      break;
    default:
      nl_error( 4, "Invalid status: %d", status );
  }
  switch (status) {
    case RESP_OK:
    case RESP_INTR: break;
    default:
      if ( cur_req )
        nl_error( 2, "Current request was: '%s'",
            ascii_escape(cur_req->request) );
      else
        nl_error( 2, "No current request" );
  }
  // we won't dequeue on error: wait for timeout to handle that
  // that's because we don't know the invalid response was
  // to the current request. It could be noise, or an invalid
  // interrupt response for something.
}

/**
 * Sends the response to the client (if any) and
 * removes it from the queue. Initiates
 * processing of the next command if one is waiting.
 * Current assumption:
 *    n_args maps 1:1 onto SBRT_ codes
 *    n_args == 3 is only for 'V' request/response
 *    n_args == 4 is only for 'M' request/response
 * We need to parse the 'M' response here rather than in process_response()
 * because we need direct access to the reply structure.
 */
void Subbus::dequeue_request(enum sbd_cmd_status status, int n_args,
  uint16_t arg0, uint16_t arg1, char *s ) {

  nl_assert( cur_req != NULL);
  timer->stop();
  // set_timeout(0);
  cur_req->cmd_status = status;
  switch (n_args) {
    case 0:
      // rep.hdr.ret_type = SBRT_NONE;
      // rsize = sizeof(subbusd_rep_hdr_t);
      break;
    case 1:
      // rep.hdr.ret_type = SBRT_US;
      // rep.data.value = arg0;
      cur_req->reply_data.read_data = arg0;
      // rsize = sizeof(subbusd_rep_hdr_t)+sizeof(unsigned short);
      break;
    case 3:
      nl_assert( cur_req->request[0] == 'V' );
      subbus_subfunction = arg0;
      subbus_features = arg1;
      strncpy(subbus_name, s, SUBBUS_NAME_MAX);
      break;
    case 4:
    #ifdef SUBBUS_MREAD_SUPPORT
      // 'M' response and request (tested before calling)
      rep.hdr.ret_type = SBRT_MREAD;
      nl_assert(cur_req->request[0] == 'M' && cur_req->n_reads != 0);
      // Look at req n_reads, then parse responses. Don't parse more
      // than n_reads values. If we encounter 'm', switch status to
      // SBS_NOACK. If we encounter 'E', switch status to
      // SBS_RESP_ERROR, report the error code, and return with no
      // data. If we get the wrong number of responses, report
      // SBS_RESP_SYNTAX, complain and return with no data
      { int n_reads = cur_req->n_reads;
        int i = 0;
        char *p = s;
        unsigned short errval;

        nl_assert( n_reads > 0 && n_reads <= 50 );
        while ( i < n_reads && rsize == 0 ) {
          switch ( *p ) {
            case 'm':
              rep.hdr.status = SBS_NOACK; // No acknowledge on at least one read
              // fall through
            case 'M':
              ++p;
              if ( ! read_hex( &p, &rep.data.mread.rvals[i++] ) ) {
                nl_error(2,"DACS response syntax error: '%s'",
                  ascii_escape(s));
                rep.hdr.status = SBS_RESP_SYNTAX; // DACS reply syntax error
                rsize = sizeof(subbusd_rep_hdr_t);
                rep.hdr.ret_type = SBRT_NONE;
                break;
              }
              continue;
            case 'E':
              ++p;
              if ( ! read_hex( &p, &errval ) ) {
                nl_error(2,"Invalid error in mread response: '%s'",
                  ascii_escape(s));
                rep.hdr.status = SBS_RESP_SYNTAX;
              } else {
                nl_error(2, "DACS reported error %d on mread", errval );
                rep.hdr.status = SBS_RESP_ERROR;
              }
              rsize = sizeof(subbusd_rep_hdr_t);
              rep.hdr.ret_type = SBRT_NONE;
              break;
            default:
              break;
          }
          break;
        }
        if ( rsize == 0 ) {
          if ( i != n_reads || *p != '\0' ) {
            // Wrong number of read values returned
            nl_error(2, "Expected %d, read %d: '%s'",
              n_reads, i, ascii_escape(s));
            rep.hdr.status = SBS_RESP_SYNTAX;
            rsize = sizeof(subbusd_rep_hdr_t);
            rep.hdr.ret_type = SBRT_NONE;
          } else {
            rep.data.mread.n_reads = n_reads;
            rsize = sizeof(subbusd_rep_hdr_t) +
                    (n_reads+1) * sizeof(unsigned short);
          }
        }
      }
      break;
    #endif
    case 2:
      nl_error( 4, "Invalid n_args in dequeue_request" );
  }
  ReqQ.pop_front(); // Remove cur_req from the queue, but don't clear yet.
  // That allows the client's ready() to enqueue another request.
  cur_req->req_status = SBDR_IDLE;
  cur_req->ready();
  cur_req = 0;
  process_request(); // if one is pending...
}

/**
 Parses the input string for a hexadecimal integer.
 @return zero on failure.
 */
int Subbus::read_hex( char **sp, unsigned short *arg ) {
  char *s = *sp;
  unsigned short val = 0;
  if ( ! isxdigit(*s) )
    return 0;
  while ( isxdigit(*s) ) {
    val *= 16;
    if ( isdigit(*s) )
      val += *s - '0';
    else
      val += tolower(*s) - 'a' + 10;
    ++s;
  }
  *arg = val;
  *sp = s;
  return 1;
}

enum port_status { PORT_NOT_FOUND, PORT_BUSY, PORT_OK };

void Subbus::init() {
  if (port) {
    emit statusChanged("Serial port already opened");
    return;
  }
  const auto infos = QSerialPortInfo::availablePorts();
  QSettings settings;
  QString selected_port = settings.value("SerialPort").toString();
  port_status selected_port_status = PORT_NOT_FOUND;
  QStringList ports;
  QString s;
  for (const auto info : infos) {
    QString curPort = info.portName();
//    QString desc = info.description();
//    QString mfg = info.manufacturer();
//    QString sn = info.serialNumber();
//    QString s = curPort + ": " + desc + " Mfg: " + mfg + " sn: " + sn;
//    nl_error(0, "%s", s.toLatin1().constData());
    if (info.isBusy()) {
      if (selected_port == curPort) {
        selected_port_status = PORT_BUSY;
      }
    } else {
      if (selected_port == curPort)
        selected_port_status = PORT_OK;
      ports << curPort;
    }
  }

  if (selected_port_status == PORT_OK){
    portName = selected_port;
  } else {
    QString msg;
    if (!selected_port.isEmpty()) {
       QString reason = selected_port_status == PORT_BUSY ?
            "BUSY" : "not found";
       msg = "Previously selected port '" + selected_port + "' " +
           reason + "\n";
    }
    if (ports.isEmpty()) {
      msg += "No free serial port located";
      emit statusChanged("No serial port");
      emit subbus_closed();
      return;
    } else if (ports.length() > 1 || !msg.isEmpty()) {
      bool OK = false;
      msg += "Select a port from the list: ";
      selected_port = QInputDialog::getItem(0,
          "Select COM Port", msg, ports, 0, false, &OK);
      if (OK) {
        portName = selected_port;
      } else {
        emit subbus_closed();
        return;
      }
    } else {
      nl_assert(ports.length() == 1);
      portName = ports[0];
    }
  }
  settings.setValue("SerialPort", portName);
  port = new QSerialPort(portName);
  connect(port,
    static_cast<void(QSerialPort::*)(QSerialPort::SerialPortError)>(&QSerialPort::error),
    this, &Subbus::SerialError, Qt::QueuedConnection);
  if (port->open(QIODevice::ReadWrite)) {
    int nflush = 0;
    while (port->bytesAvailable()) {
      char buf[80];
      int nb = port->bytesAvailable();
      if (nb > 79) nb = 79;
      nflush += port->read(buf, nb);
    }
    connect(port, &QSerialPort::readyRead,
            this, &Subbus::ProcessData);
    IntClt->identify_board();
  }
  nl_error(0, "%s", s.toLatin1().constData());
  emit statusChanged(s);
}

void Subbus::SerialError(QSerialPort::SerialPortError error) {
  if (error != QSerialPort::NoError) {
    nl_error(2, "SerialPortError %d", error);
    delete port;
    port = 0;
    emit subbus_closed();
  }
}

/* Return non-zero on error */
int Subbus::submit(Subbus_client *clt) {
  if (clt->req_status != SBDR_IDLE) return 1;
  clt->cmd_status = SBS_OK;
  clt->req_status = SBDR_STATUS_QUEUED;
  ReqQ.push_back(clt);
  process_request();
  return 0;
}

// Transmits a request if the currently queued
// request has not been transmitted.
void Subbus::process_request() {
  int cmdlen, n;
  int no_response = 0;
  if (!port) return;
  while ( cur_req == NULL && !ReqQ.empty()) {
    Subbus_client *sbr = ReqQ[0];
    nl_assert( sbr->req_status == SBDR_STATUS_QUEUED );
    switch (sbr->req_type) {
      case SBDR_TYPE_INTERNAL:
        switch (sbr->command) {
          case SBC_GETCAPS:  // Board Revision
            strcpy(sbr->request, "V\n");
            break;
          default:
            nl_error( 4, "Invalid internal request" );
        }
        break;
      case SBDR_TYPE_CLIENT:
        switch (sbr->command) {
          case SBC_READACK:
            snprintf(sbr->request, SB_SERUSB_MAX_REQUEST, "R%04X\n",
              sbr->request_data.d1.data );
            break;
          case SBC_WRITEACK:
            snprintf(sbr->request, SB_SERUSB_MAX_REQUEST, "W%04X:%04X\n",
              sbr->request_data.d0.address, sbr->request_data.d0.data );
            break;
          case SBC_SETFAIL:
            snprintf( sbr->request, SB_SERUSB_MAX_REQUEST, "F%04X\n",
              sbr->request_data.d1.data );
            break;
          case SBC_READFAIL:
            strcpy( sbr->request, "f\n" ); break;
          case SBC_SETCMDENBL:
          case SBC_SETCMDSTRB:
          case SBC_READSW:
          case SBC_TICK: // no_response = 1; break;
          case SBC_DISARM:
          case SBC_INTATT:
          case SBC_INTDET:
          case SBC_READCACHE:
          case SBC_WRITECACHE:
          case SBC_QUIT:
          case SBC_MREAD:
          default:
            nl_error( 4, "Invalid client request: %d", sbr->command );
        }
        break;
      default:
        nl_error(4, "Invalid request type" );
    }
    cmdlen = (int) strlen(sbr->request);
    nl_error(-2, "Request: '%*.*s'", cmdlen-1, cmdlen-1, sbr->request );
    nc = 0;
    n = port->write(sbr->request);
    //++n_writes;
    nl_assert( n == cmdlen );
    sbr->req_status = SBDR_STATUS_SENT;
    cur_req = sbr;
    if ( no_response )
      dequeue_request( SBS_OK, 0, 0, 0, "" );
    else timer->start(1000);
  }
}

void Subbus::ProcessTimeout() {
  if (cur_req != 0 && cur_req->req_status == SBDR_STATUS_SENT)
    dequeue_request(SBS_TIMEOUT, 0, 0, 0, "");
}

Subbus_client::Subbus_client() {
  cmd_status = SBS_OK;
  req_type = SBDR_TYPE_CLIENT;
  req_status = SBDR_IDLE;
}

Subbus_client::~Subbus_client() {}

/* Return TRUE on error:
 * Invalid command
 * Busy
 */
int Subbus_client::read(uint16_t address) {
  if (req_status != SBDR_IDLE) return 1;
  command = SBC_READACK;
  request_data.d1.data = address;
  return SB.submit(this);
}

int Subbus_client::write(uint16_t address, uint16_t data) {
  if (req_status != SBDR_IDLE) return 1;
  command = SBC_WRITEACK;
  request_data.d0.address = address;
  request_data.d0.data = data;
  return SB.submit(this);
}


Subbus Subbus_client::SB;

bool Subbus_client::timed_out = false;

int Internal_Subbus_client::identify_board() {
  if (req_status != SBDR_IDLE) return 1;
  command = SBC_GETCAPS;
  req_type = SBDR_TYPE_INTERNAL;
  return SB.submit(this);
}

void Internal_Subbus_client::ready() {
  if (cmd_status == SBS_OK) {
    SB.statusChanged(SB.subbus_name);
  } else {
    SB.statusChanged("Status: " + QString::number(cmd_status));
  }
  SB.subbus_initialized();
}
