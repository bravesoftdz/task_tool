unit uDefines;

interface

uses Winapi.Messages, uRENDER_ProcessProxy, System.SyncObjs, uFileLogger;

var
  ExePath: string;
  AppLogger: TThreadFileLog;
  FileCritical: TCriticalSection;


  //������ֻ����Render�����е���
  PRENDER_RenderHelper: TRENDER_ProcessProxy;



implementation



end.
