unit uDefines;

interface


uses
  uFileLogger, System.SyncObjs, uHttpServerRunner;

var
  AppLogger: TThreadFileLog;
  FileCritical: TCriticalSection;

  //Ŀǰ��������ʵ����������
  HttpServerRunner: THttpServerRunner;



const
  APP_VER: string = '1.1.1';


implementation


end.
