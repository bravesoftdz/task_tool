//������render�����У�����jsv8�ĺ������������ļ�Ҫô�ǵ����ܹ��ṩ����Ҫô����
//browser���̷�����Ϣ
//�����̻��ṩһ�����ڽ�������browser���̵ķ�����������render�����е�jsv8��context���лص�
//����������context���յ���Ϣ��������chromiumʵ������Ķ����ˣ�Ҳ����jsv8��context��Ӧ��cefbrowser
//���⣬����һ����Ҫ�ѻص������Ķ�������������������ж��ڲ�ͬ�����¼��Ļص���������Щ�ص������ǿ����ڻص�
//���֮��ͽ����ͷŵģ�����Щ�������ĳ���¼��ļ�������ֱ������context���ͷţ��Ų���Ҫ����
//���������������render��ִ�еģ�ͬ����������Ҫһ����Ӧ��ʵ����������Щjs����������
//�����Ӧ�ķ���������Ӧ����browser�Ľ����д��ڵ�


unit uBaseJsBinding;

{$I cef.inc}

interface

uses
  uCEFTypes, uCEFInterfaces, uCEFv8Value, uCEFv8Handler, uCEFv8Context;

type
  TBasicJsBinding = class(TCefv8HandlerOwn)
  protected
    //Js Executed in Render Progress
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  public
    //Register Js to Context
    class procedure BindJsTo(const ACefv8Value: ICefv8Value); virtual;

    //Js Executed in Browser Progress
    class procedure ExecuteInBrowser(Sender: TObject;
                      const browser: ICefBrowser; sourceProcess: TCefProcessId;
                      const message: ICefProcessMessage; out Result: Boolean; const AFormHandle: THandle); virtual;

    class procedure OpenNativeWindow(AWindowParams: string); static;
  end;


implementation

uses Winapi.Windows, Vcl.Dialogs, System.SysUtils, Vcl.Forms, uCEFProcessMessage,
  uRENDER_JsCallbackList, uCEFValue, uCEFConstants, uBROWSER_EventJsListnerList, uVVConstants,
  System.JSON, uAppDefines, uFunctions,
  uBasicChromeForm, uDefines, uJobDispatcher, uFileLogger;


const
  BINDING_NAMESPACE = 'BASIC/';


//��context��ʼ��ʱ��js
class procedure TBasicJsBinding.BindJsTo(const ACefv8Value: ICefv8Value);
var
  TempHandler  : ICefv8Handler;
  TempFunction : ICefv8Value;
begin
  TempHandler  := TBasicJsBinding.Create;

  ACefv8Value.SetValueByKey('__BROWSER_APP_VERSION', TCefv8ValueRef.NewString('1.0.0'), V8_PROPERTY_ATTRIBUTE_NONE);

  TempFunction := TCefv8ValueRef.NewFunction('openNativeWindow', TempHandler);
  ACefv8Value.SetValueByKey('openNativeWindow', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);

  TempFunction := TCefv8ValueRef.NewFunction('startJob', TempHandler);
  ACefv8Value.SetValueByKey('startJob', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);

  TempFunction := TCefv8ValueRef.NewFunction('registerEventListner', TempHandler);
  ACefv8Value.SetValueByKey('registerEventListner', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);
end;



//���������render������ִ��
function TBasicJsBinding.Execute(const name      : ustring;
                              const obj       : ICefv8Value;
                              const arguments : TCefv8ValueArray;
                              var   retval    : ICefv8Value;
                              var   exception : ustring): Boolean;
var
  LMsg: ICefProcessMessage;
  LContextCallback: TContextCallbackRec;
  LMsgName, LCallbackIdxName: string;
begin
  LMsgName := BINDING_NAMESPACE + name;
  if (name = 'openNativeWindow') then
  begin
    LMsg := TCefProcessMessageRef.New(LMsgName);
    LMsg.ArgumentList.SetString(0, arguments[0].GetStringValue);
    TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);
    Result := True;
  end
  else if (name = 'startJob') then
  begin
    if (Length(arguments) = 3) and (arguments[0].IsString) and (arguments[2].IsFunction) then
    begin
      //��ӵ��ص������б���ȥ������һ������Ե��ַ�����������Ӧ���η�����õĻص�����
      LContextCallback.Context := TCefv8ContextRef.Current;
      LContextCallback.BrowserId := LContextCallback.Context.Browser.Identifier;
      LContextCallback.CallbackFunc := arguments[2];
      LCallbackIdxName := RENDER_JsCallbackList.AddCallback(LContextCallback);

      if LCallbackIdxName <> '' then
      begin
        //������Ϣ��browser����
        LMsg := TCefProcessMessageRef.New(LMsgName);
        LMsg.ArgumentList.SetString(0, arguments[0].GetStringValue);
        LMsg.ArgumentList.SetString(1, arguments[1].GetStringValue);

        //�ڶ�������Ϊ�ص�����
        LMsg.ArgumentList.SetString(2, LCallbackIdxName);

        TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);
      end
      else
        exception := 'callback function register error on ' + name;
    end;
    Result := True;
  end
  else if (name = 'registerEventListner') then
  begin
    if (Length(arguments) = 2) and (arguments[0].IsString) and (arguments[1].IsFunction) then
    begin
      //������Ҫ���б����Ӧ���¼�
      //��һ������Ϊ�������¼������ƣ��ڶ�������Ϊ�¼�����ʱ�Ļص�����
      //��ӵ��ص������б���ȥ��������Ϊ�������ɵĶ��󣬿����Ѿ����ڣ����ڻص���ֱ���ͷţ��ص��б������һ��
      LContextCallback.Context := TCefv8ContextRef.Current;
      LContextCallback.BrowserId := LContextCallback.Context.Browser.Identifier;
      LContextCallback.IdxName := LMsgName + '/' + arguments[0].GetStringValue;
      LContextCallback.CallbackFunc := arguments[1];
      LCallbackIdxName := RENDER_JsCallbackList.AddCallback(LContextCallback);

      if LCallbackIdxName <> '' then
      begin
        //������Ϣ��browser����
        LMsg := TCefProcessMessageRef.New(LMsgName);
        LMsg.ArgumentList.SetString(0, arguments[0].GetStringValue); //�¼�����
        //LMsg.ArgumentList.SetString(1, )  //�ڻص������е��������ƣ�������Ϊ��Ϣ

        TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);
      end
      else
        exception := 'callback function register error on ' + LContextCallback.IdxName;
    end;
    Result := True;
  end
  else
    Result := False;
end;



//����Ĵ�����browser������ִ��
class procedure TBasicJsBinding.ExecuteInBrowser(Sender: TObject;
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; out Result: Boolean; const AFormHandle: THandle);
var
  LMsg: ICefProcessMessage;
  LParams: ICefValue;
  LJsListnerRec: TEventJsListnerRec;
  LParamIdx: Integer;


  LSyncJobDispatcher: TJobDispatcher;
  LOutResult: TOutResult;
  LJobDispatcherRec: PJobDispatcherRec;
  LSplitterPos: Integer;
  LDispatch: string;
  LProjectName, LJobName: string;
begin
  if message.Name = BINDING_NAMESPACE + 'openNativeWindow' then
  begin
    LParamIdx := BROWSER_GlobalVar.AddParam(message.ArgumentList.GetString(0));
    PostMessage(Application.MainForm.Handle, VVMSG_OPEN_NATIVE_WINDOW, LParamIdx, 0);
    Result := True;
  end
  else if message.Name = BINDING_NAMESPACE + 'startJob' then
  begin
    //ִ��task���ڽ������ʱ���Ѷ�Ӧ��ִ�н������lmsg�У���Ϊrsp�����render��jsִ�л���
    //�ظ�һ���ص���������Ϣ��render�У�ͬʱɾ����Ӧ�ļ����ص�
    //�������������ʱ��������
    LDispatch := message.ArgumentList.GetString(0);
    LSplitterPos := Pos('/', LDispatch);
    LProjectName := Copy(LDispatch, 1, LSplitterPos - 1);
    LJobName := Copy(LDispatch, LSplitterPos + 1, Length(LDispatch) - LSplitterPos);

    New(LJobDispatcherRec);
    if LJobDispatcherRec <> nil then
    try
      LJobDispatcherRec^.ProjectFile := ExePath + 'projects\' + LProjectName + '\project.jobs';
      LJobDispatcherRec^.JobName := LJobName;
      LJobDispatcherRec^.InParams := message.ArgumentList.GetString(1);
      LJobDispatcherRec^.LogLevel := llDebug;
      LJobDispatcherRec^.LogNoticeHandle := AFormHandle;
    finally

    end;

    LSyncJobDispatcher := BROWSER_JobDispatcherMgr.NewDispatcher;
    try
      LSyncJobDispatcher.StartProjectJob(LJobDispatcherRec, True);

      if LSyncJobDispatcher <> nil then
        LOutResult := LSyncJobDispatcher.OutResult;
    finally
      BROWSER_JobDispatcherMgr.FreeDispatcher(LSyncJobDispatcher);
    end;

    LMsg := TCefProcessMessageRef.New(IPC_MSG_EXEC_CALLBACK);
    LMsg.ArgumentList.SetValue(0, message.ArgumentList.GetValue(2)); //callback_idxname

    //���ò������
    LMsg.ArgumentList.SetInt(1, LOutResult.Code);
    LMsg.ArgumentList.SetString(2, LOutResult.Msg);
    LMsg.ArgumentList.SetString(3, LOutResult.Data);

    //TODO ���Ը���render��ִ����Ϻ󣬿����Ƴ�����ص�����
    browser.SendProcessMessage(PID_RENDERER, LMsg);

    Result := True;
  end
  else if message.Name = BINDING_NAMESPACE + 'registerEventListner' then
  begin
    //��BROWSER_EventJsListner��Ӽ�����

    //��ϵͳ��¼������ĸ��¼����������¼�Ҫ�ܺ����׽��д���
    //����, browser_eventlist.eventnotify('event_name')
    //�����event_nameҪ�ǳ���ȷ������basic.timer, basic.weighter_change��Ȼ����Դ��Ͼ����browser_id


    //��һ������Ϊ�¼������ƣ��ڶ�������Ϊ��Ӧ�Ļص�������render�����е�����
    LJsListnerRec.EventName := message.ArgumentList.GetString(0);
    LJsListnerRec.BrowserId := browser.Identifier;
    LJsListnerRec.Browser := browser;
    LJsListnerRec.ListnerMsgName := '';

    BROWSER_EventJsListnerList.AddEventListner(LJsListnerRec);

    Result := True;
  end
  else
    Result := False;
end;


//
class procedure TBasicJsBinding.OpenNativeWindow(AWindowParams: string);
var
  LWindowParamsJson: TJSONObject;
begin
  LWindowParamsJson := TJSONObject.ParseJSONValue(AWindowParams) as TJSONObject;
  if LWindowParamsJson = nil then Exit;

  //���������������ṩ�����Զ�����صĲ�ͬ�������������ṩ��ͬ��ԭ�����ڽ���
  try
    with TBasicChromeForm.Create(nil, 'file:///' + ExePath + 'app/html/index.html') do
    try
      Caption := GetJsonObjectValue(LWindowParamsJson, 'caption');
      ShowModal;
    finally
      Free;
    end;
  finally
    LWindowParamsJson.Free;
  end;

end;

end.
