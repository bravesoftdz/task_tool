unit uAppDefines;

interface

uses Winapi.Messages, uRENDER_ProcessProxy, System.SyncObjs, uFileLogger, uBROWSER_GlobalVar,
uJobDispatcher;

var
  //������ֻ����Render�����е���
  RENDER_RenderHelper: TRENDER_ProcessProxy;

  //browser���̵�ȫ�ֱ�����Ҳ��������render��ȫ�ֱ������ڵ����������̷߳��ʰ�ȫ
  BROWSER_GlobalVar: TBROWSER_GlobalVar;
  BROWSER_JobDispatcherMgr: TJobDispatcherList;



implementation



end.
