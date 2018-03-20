program BrowserApp;

uses
  Vcl.Forms,
  Winapi.Windows,
  System.SysUtils,
  System.SyncObjs,
  uCEFApplication,
  uBasicForm in '..\..\core\basic\uBasicForm.pas' {BasicForm},
  uBasicDlgForm in '..\..\core\basic\uBasicDlgForm.pas' {BasicDlgForm},
  uFileLogger in '..\..\core\lib\uFileLogger.pas',
  uFileUtil in '..\..\core\lib\uFileUtil.pas',
  uNetUtil in '..\..\core\lib\uNetUtil.pas',
  uThreadQueueUtil in '..\..\core\lib\uThreadQueueUtil.pas',
  uFunctions in '..\..\common\uFunctions.pas',
  uSelectFolderForm in '..\..\common\uSelectFolderForm.pas' {SelectFolderForm},
  uRENDER_JsCallbackList in 'comm\uRENDER_JsCallbackList.pas',
  uRENDER_ProcessProxy in 'comm\uRENDER_ProcessProxy.pas',
  uBasicChromeForm in 'basic\uBasicChromeForm.pas' {BasicChromeForm},
  uBaseJsBinding in 'bindings\uBaseJsBinding.pas',
  uDefines in 'comm\uDefines.pas',
  uVVCefFunction in 'comm\uVVCefFunction.pas',
  uAppForm in 'forms\uAppForm.pas' {AppForm},
  uBROWSER_EventJsListnerList in 'comm\uBROWSER_EventJsListnerList.pas',
  uBaseJsObjectBinding in 'bindings\uBaseJsObjectBinding.pas',
  uVVConstants in 'comm\uVVConstants.pas',
  uSerialPortBinding in 'bindings\uSerialPortBinding.pas',
  uBindingProxy in 'bindings\uBindingProxy.pas',
  uGlobalVar in 'comm\uGlobalVar.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;

  ExePath := ExtractFilePath(Application.ExeName);
  AppLogger := TThreadFileLog.Create(1,  ExePath + 'log\app\', 'yyyymmdd\hh');
  FileCritical := TCriticalSection.Create;

  BROWSER_GlobalVar := TGlobalVar.Create;
  BROWSER_EventJsListnerList := TBROWSER_EventJsListnerList.Create;
  BROWSER_SerialPortMgr := TSerialPortMgr.Create;

  RENDER_JsCallbackList := TRENDER_JsCallbackList.Create;
  RENDER_RenderHelper := TRENDER_ProcessProxy.Create;


  GlobalCEFApp                  := TCefApplication.Create;
  GlobalCEFApp.OnContextCreated := RENDER_RenderHelper.OnContextCreated;
  GlobalCEFApp.OnContextReleased := RENDER_RenderHelper.OnContextReleased;
  GlobalCEFApp.OnProcessMessageReceived := RENDER_RenderHelper.OnProcessMessageReceived;
  GlobalCEFApp.SingleProcess := False;

  if GlobalCEFApp.StartMainProcess then
  begin
    Application.Initialize;
    Application.MainFormOnTaskbar := True;

    Application.CreateForm(TAppForm, AppForm);
  AppForm.WindowState := wsMaximized;
    Application.Run;
  end;


  RENDER_RenderHelper.Free;
  RENDER_JsCallbackList.Free;

  BROWSER_SerialPortMgr.Free;
  BROWSER_EventJsListnerList.Free;
  BROWSER_GlobalVar.Free;

  FileCritical.Free;
  AppLogger.Free;

  GlobalCEFApp.Free;
end.
