QT += widgets serialport

TARGET = HVPS_standalone

HEADERS += \
    nortlib/nortlib.h \
    hvps/tmsbvar.h \
    hvps/tmdispvar.h \
    hvps/sbcmdbox.h \
    hvps/hvps_channel.h \
    subbus/subbus.h \
    hvps/hvpswindow.h \
    hvps/hvps_status.h
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
    hvps/hvpswindow.cpp \
    hvps/hvps_status.cpp
INCLUDEPATH = nortlib subbus hvps

RESOURCES += \
    hvps_standalone.qrc
#==========Deploy
win32: {
    TARGET_CUSTOM_EXT = .exe

    CONFIG( debug, debug|release ) {
        # debug
        DEPLOY_TARGET = $$shell_quote($$shell_path($${OUT_PWD}/debug/$${TARGET}$${TARGET_CUSTOM_EXT}))
        DLLDESTDIR  = $$shell_quote($$shell_path($${OUT_PWD}/out/debug/))
    } else {
        # release
        DEPLOY_TARGET = $$shell_quote($$shell_path($${OUT_PWD}/release/$${TARGET}$${TARGET_CUSTOM_EXT}))
        DLLDESTDIR  = $$shell_quote($$shell_path($${OUT_PWD}/out/release/))
    }

    DEPLOY_COMMAND = windeployqt
    QMAKE_POST_LINK = $${DEPLOY_COMMAND} --dir $${DLLDESTDIR} --no-translations $${DEPLOY_TARGET}
}
#==========================================
