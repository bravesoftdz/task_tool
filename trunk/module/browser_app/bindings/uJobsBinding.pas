unit uJobsBinding;


{$I cef.inc}

interface

uses
  uCEFV8Value, uCEFv8Accessor, uCEFInterfaces, uCEFTypes, uCEFConstants,
  uCEFv8Handler, Vcl.ExtCtrls;

type
  TJobsFunctionBinding = class(TCefv8HandlerOwn)
  private
  protected
    //Js Executed in Render Progress
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  public

    //Register Js to Context
    class procedure BindJsTo(const ACefv8Value: ICefv8Value); virtual;
    class procedure ExecuteInBrowser(Sender: TObject;
      const browser: ICefBrowser; sourceProcess: TCefProcessId;
      const message: ICefProcessMessage; out Result: Boolean); static;
  end;

  TJobsBinding = class
  private
  protected
  public
    class procedure BindJsTo(const ACefv8Value: ICefv8Value); static;
  end;


implementation

uses uBaseJsBinding, uCEFValue, uBROWSER_EventJsListnerList, uCEFProcessMessage,
uRENDER_JsCallbackList, uCEFv8Context, uVVConstants, System.SysUtils;

const
  BINDING_NAMESPACE = 'JOB/';

//��context��ʼ��ʱ��js
class procedure TJobsBinding.BindJsTo(const ACefv8Value: ICefv8Value);
var
  TempAccessor : ICefV8Accessor;
  TempObject   : ICefv8Value;
begin
  TempAccessor := TCefV8AccessorOwn.Create;
  TempObject   := TCefv8ValueRef.NewObject(TempAccessor, nil);

  //�����Լ����������ĺ������߷���
  TJobsFunctionBinding.BindJsTo(TempObject);

  ACefv8Value.SetValueByKey('JSN_Job', TempObject, V8_PROPERTY_ATTRIBUTE_NONE);
end;




{ TJobsFunctionBinding }

class procedure TJobsFunctionBinding.BindJsTo(const ACefv8Value: ICefv8Value);
var
  TempHandler  : ICefv8Handler;
  TempFunction : ICefv8Value;
begin
  TempHandler  := TJobsFunctionBinding.Create;

  ACefv8Value.SetValueByKey('__NAMESPACE', TCefv8ValueRef.NewString(BINDING_NAMESPACE), V8_PROPERTY_ATTRIBUTE_NONE);

  TempFunction := TCefv8ValueRef.NewFunction('startTask', TempHandler);
  ACefv8Value.SetValueByKey('startTask', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);

  TempFunction := TCefv8ValueRef.NewFunction('stopTask', TempHandler);
  ACefv8Value.SetValueByKey('stopTask', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);
end;


function TJobsFunctionBinding.Execute(const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
var
  LMsg: ICefProcessMessage;
  LContextCallback: TContextCallbackRec;
  LMsgName, LCallbackIdxName: string;
  LResult: ICefv8Value;
  LCefV8Accessor: ICefV8Accessor;
begin
  LMsgName := BINDING_NAMESPACE + name;
  if (name = 'startTask') then
  begin
    //�������ж��Ƿ��ǺϷ��Ĵ�������
    if (Length(arguments) = 3) and (arguments[0].IsString) and (arguments[2].IsFunction) then
    begin
      LContextCallback.Context := TCefv8ContextRef.Current;
      LContextCallback.BrowserId := LContextCallback.Context.Browser.Identifier;
      LContextCallback.IdxName := BINDING_NAMESPACE + 'startTask/' + arguments[0].GetStringValue;
      LContextCallback.CallbackFuncType := cftFunction;
      LContextCallback.CallbackFunc := arguments[2];
      LCallbackIdxName := RENDER_JsCallbackList.AddCallback(LContextCallback);

      LMsg := TCefProcessMessageRef.New(LMsgName);
      LMsg.ArgumentList.SetString(0, arguments[0].GetStringValue);
      LMsg.ArgumentList.SetString(1, LContextCallback.IdxName);
      LMsg.ArgumentList.SetString(2, arguments[1].GetStringValue);

      //������Ϣ��BROWSER����
      TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);

      //ע����߸��»ص�����
      LCefV8Accessor := TCefV8AccessorOwn.Create;
      LResult := TCefv8ValueRef.NewObject(LCefV8Accessor, nil);
      LResult.SetValueByKey('stopTask', TCefv8ValueRef.NewFunction('stopTask', Self), V8_PROPERTY_ATTRIBUTE_NONE);
      LResult.SetValueByKey('task_name', arguments[0], V8_PROPERTY_ATTRIBUTE_NONE);
      retval := LResult;
    end
    else
      exception := 'startTask params error';
    Result := True;
  end
  else if (name = 'stopTask') then
  begin
    if obj.IsObject then
    begin
      //������Ϣ��browser���Ͽ���ĳ���˿ڵļ���
      LMsg := TCefProcessMessageRef.New(LMsgName);
      LMsg.ArgumentList.SetString(0, obj.GetValueByKey('task_name').GetStringValue);

      TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);

      retval := TCefv8ValueRef.NewBool(True);
    end
    else
      exception := 'no task to stop!';

    Result := True;
  end
  else
    Result := False;
end;


//����Ĵ�����browser������ִ��
class procedure TJobsFunctionBinding.ExecuteInBrowser(Sender: TObject;
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; out Result: Boolean);
var
  LMsg: ICefProcessMessage;
  LParams: ICefValue;
  LJsListnerRec: TEventJsListnerRec;
begin
  if message.Name = BINDING_NAMESPACE + 'startTask' then
  begin
    //ͨ��jobdispatcher����һ�����񣬲��ҷ��ͻص���Ϣ

    //��ӵ�BROWSER�Ĵ����б���ȥ
//    LSerialPortConnectRec.CommName := message.ArgumentList.GetString(0);
//    LSerialPortConnectRec.Browser := browser;
//    LSerialPortConnectRec.CallbackIdxName := message.ArgumentList.GetString(1);
//    BROWSER_SerialPortMgr.ConnectTo(LSerialPortConnectRec);

    Result := True;
  end
  else if message.Name = BINDING_NAMESPACE + 'stopTask' then
  begin
    //��Browser_mgr�����Ƴ������Ǹ��Ķ˿ڼ���
    //BROWSER_SerialPortMgr.DisconnectFrom(message.ArgumentList.GetString(0));

    Result := True;
  end
  else
    Result := False;
end;


end.

