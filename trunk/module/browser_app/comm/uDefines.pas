unit uDefines;

interface

uses Winapi.Messages, uRENDER_ProcessProxy, System.SyncObjs, uFileLogger, uGlobalVar;

var
  ExePath: string;
  AppLogger: TThreadFileLog;
  FileCritical: TCriticalSection;


  //������ֻ����Render�����е���
  RENDER_RenderHelper: TRENDER_ProcessProxy;

  //browser���̵�ȫ�ֱ�����Ҳ��������render��ȫ�ֱ������ڵ����������̷߳��ʰ�ȫ
  BROWSER_GlobalVar: TGlobalVar;



implementation



end.
