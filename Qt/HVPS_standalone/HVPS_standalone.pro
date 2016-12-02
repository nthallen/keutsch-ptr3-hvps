QT += widgets serialport

TARGET = HVPS_standalone

HEADERS += \
    nortlib/nortlib.h \
    hvps/tmsbvar.h \
    hvps/tmdispvar.h \
    hvps/sbcmdbox.h \
    hvps/hvps_channel.h \
    subbus/subbus.h \
    hvps/hvpswindow.h
SOURCES += \
    main.cpp \
    nortlib/nl_error.cpp nortlib/nl_verr.cpp \
    nortlib/nldbg.cpp \
    nortlib/snprintf.cpp \
    hvps/tmsbvar.cpp \
    hvps/tmdispvar.cpp \
    hvps/sbcmdbox.cpp \
    hvps/hvps_channel.cpp \
    subbus/subbus.cpp \
    nortlib/ascii_esc.cpp \
    hvps/hvpswindow.cpp
INCLUDEPATH = nortlib subbus hvps

RESOURCES += \
    hvps_standalone.qrc
