#include <QApplication>
#include <QGridLayout>
#include <QSettings>
#include "hvps_channel.h"
#include "hvpsWindow.h"

int main(int argc, char **argv) {
  QApplication app(argc, argv);

  QFile styleFile( ":/style/HVPS.qss" );
  styleFile.open( QFile::ReadOnly );
  QString style( styleFile.readAll() );
  app.setStyleSheet( style );

  QSettings::setDefaultFormat(QSettings::IniFormat);
  QCoreApplication::setOrganizationName("HarvardKeutschGroup");
  QCoreApplication::setApplicationName("PTR3_HVPS");

  hvpsWindow *window = new hvpsWindow();
  return app.exec();
}
