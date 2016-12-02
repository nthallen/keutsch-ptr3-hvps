#include <QApplication>
#include <QGridLayout>
#include "hvps_channel.h"
#include "hvpsWindow.h"

int main(int argc, char **argv) {
  QApplication app(argc, argv);

  QFile styleFile( ":/style/HVPS.qss" );
  styleFile.open( QFile::ReadOnly );
  QString style( styleFile.readAll() );
  app.setStyleSheet( style );

  hvpsWindow *window = new hvpsWindow();
  return app.exec();
}
