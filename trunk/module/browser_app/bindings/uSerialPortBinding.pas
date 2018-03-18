unit uSerialPortBinding;

{$I cef.inc}

interface

uses
  uCEFV8Value, uCEFv8Accessor, uCEFInterfaces, uCEFTypes, uCEFConstants,
  uCEFv8Handler;

type
  TSerialPortFunctionBinding = class(TCefv8HandlerOwn)
  protected
    //Js Executed in Render Progress
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  public

    //Register Js to Context
    class procedure BindJsTo(const ACefv8Value: ICefv8Value); virtual;

    //Js Executed in Browser Progress
    class procedure ExecuteInBrowser(Sender: TObject;
                      const browser: ICefBrowser; sourceProcess: TCefProcessId;
                      const message: ICefProcessMessage; out Result: Boolean); virtual;
  end;

  TSerialPortBinding = class(TCefV8AccessorOwn)
  private
  protected

    function Get(const name: ustring; const obj: ICefv8Value;
      out retval: ICefv8Value; var exception: ustring): Boolean; override;
    function Put(const name: ustring; const obj, value: ICefv8Value;
      var exception: ustring): Boolean; override;

  public
    class procedure BindJsTo(const ACefv8Value: ICefv8Value); static;
    class procedure ExecuteInBrowser(Sender: TObject;
      const browser: ICefBrowser; sourceProcess: TCefProcessId;
      const message: ICefProcessMessage; out Result: Boolean); static;
  end;


implementation

uses uBaseJsBinding, uCEFValue, uBROWSER_EventJsListnerList, uCEFProcessMessage,
uRENDER_JsCallbackList, uCEFv8Context, uVVConstants;

const
  BINDING_NAMESPACE = 'SERIAL_PORT/';

//��context��ʼ��ʱ��js
class procedure TSerialPortBinding.BindJsTo(const ACefv8Value: ICefv8Value);
var
  TempAccessor : ICefV8Accessor;
  TempObject   : ICefv8Value;
begin
  TempAccessor := TSerialPortBinding.Create;
  TempObject   := TCefv8ValueRef.NewObject(TempAccessor, nil);

  //�����Լ����������ĺ������߷���
  TSerialPortFunctionBinding.BindJsTo(TempObject);

  ACefv8Value.SetValueByKey('JSN_SerialPort', TempObject, V8_PROPERTY_ATTRIBUTE_NONE);
end;


//����Ĵ�����browser������ִ��
class procedure TSerialPortBinding.ExecuteInBrowser(Sender: TObject;
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; out Result: Boolean);
begin
  //Ҫ�����BasicJsBinding�����ζ�����ķ������д�����
  TBasicJsBinding.ExecuteInBrowser(Sender, browser, sourceProcess, message, Result);
end;





//��������������Render��ִ��
function TSerialPortBinding.Get(const name: ustring; const obj: ICefv8Value;
  out retval: ICefv8Value; var exception: ustring): Boolean;
begin
  Result := False;
end;


function TSerialPortBinding.Put(const name: ustring; const obj: ICefv8Value;
  const value: ICefv8Value; var exception: ustring): Boolean;
begin
  Result := False;
end;



{ TSerialPortFunctionBinding }

class procedure TSerialPortFunctionBinding.BindJsTo(const ACefv8Value: ICefv8Value);
var
  TempHandler  : ICefv8Handler;
  TempFunction : ICefv8Value;
begin
  TempHandler  := TSerialPortFunctionBinding.Create;

  ACefv8Value.SetValueByKey('__NAMESPACE', TCefv8ValueRef.NewString(BINDING_NAMESPACE), V8_PROPERTY_ATTRIBUTE_NONE);

  TempFunction := TCefv8ValueRef.NewFunction('connect', TempHandler);
  ACefv8Value.SetValueByKey('connect', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);

  TempFunction := TCefv8ValueRef.NewFunction('disconnect', TempHandler);
  ACefv8Value.SetValueByKey('disconnect', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);

  TempFunction := TCefv8ValueRef.NewFunction('write', TempHandler);
  ACefv8Value.SetValueByKey('write', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);
end;


function TSerialPortFunctionBinding.Execute(const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
var
  LMsg: ICefProcessMessage;
  LContextCallback: TContextCallbackRec;
  LMsgName, LCallbackIdxName: string;
begin
  LMsgName := BINDING_NAMESPACE + name;
  if (name = 'connect') then
  begin
    //���ô��ڹ����࣬��ȡ��Ӧ���ڵ�ʵ�������ҽ��з��أ����ǿ��Խ��лص���
    LMsg := TCefProcessMessageRef.New(LMsgName);
    LMsg.ArgumentList.SetString(0, arguments[0].GetStringValue);
    TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);
    Result := True;
  end
  else if (name = 'disconnect') then
  begin
    if (Length(arguments) = 3) and (arguments[0].IsString) and (arguments[2].IsFunction) then
    begin
      arguments[2].ExecuteFunction(nil, arguments);
      retval := TCefv8ValueRef.NewString('return ok');
      //��ӵ��ص������б���ȥ������һ������Ե��ַ�����������Ӧ���η�����õĻص�����
//      LContextCallback.Context := TCefv8ContextRef.Current;
//      LContextCallback.BrowserId := LContextCallback.Context.Browser.Identifier;
//      LContextCallback.CallbackFunc := arguments[2];
//      LCallbackIdxName := RENDER_JsCallbackList.AddCallback(LContextCallback);
//
//      if LCallbackIdxName <> '' then
//      begin
//        //������Ϣ��browser����
//        LMsg := TCefProcessMessageRef.New(LMsgName);
//        LMsg.ArgumentList.SetString(0, arguments[0].GetStringValue);
//        LMsg.ArgumentList.SetString(1, arguments[1].GetStringValue);
//        LMsg.ArgumentList.SetString(2, LCallbackIdxName);
//
//        TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);
//      end
//      else
//        exception := 'callback function register error on ' + name;
    end;
    Result := True;
  end
  else if (name = 'write') then
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
class procedure TSerialPortFunctionBinding.ExecuteInBrowser(Sender: TObject;
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; out Result: Boolean);
var
  LMsg: ICefProcessMessage;
  LParams: ICefValue;
  LJsListnerRec: TEventJsListnerRec;
begin
  if message.Name = BINDING_NAMESPACE + 'connect' then
  begin
    //������Ϣ��mainform.handle����mainform.handleʵ��openNativeWindow����Ϣ��Ӧ
    //�ظ�һ���ص���������Ϣ��render�У�ͬʱɾ����Ӧ�ļ����ص�
    LMsg := TCefProcessMessageRef.New(message.Name);
    LMsg.ArgumentList.SetValue(0, message.ArgumentList.GetValue(0));

    LParams := TCefValueRef.New;
    LParams.SetString('hello, ���ǲ����ַ���');
    LMsg.ArgumentList.SetValue(0, LParams);

    //TODO ���Ը���render��ִ����Ϻ󣬿����Ƴ�����ص�����
    browser.SendProcessMessage(PID_RENDERER, LMsg);

    Result := True;
  end
  else if message.Name = BINDING_NAMESPACE + 'disconnect' then
  begin
    //ִ��task���ڽ������ʱ���Ѷ�Ӧ��ִ�н������lmsg�У���Ϊrsp�����render��jsִ�л���
    //�ظ�һ���ص���������Ϣ��render�У�ͬʱɾ����Ӧ�ļ����ص�
    LMsg := TCefProcessMessageRef.New(IPC_MSG_EXEC_CALLBACK);
    LMsg.ArgumentList.SetValue(0, message.ArgumentList.GetValue(2)); //callback_idxname
    LMsg.ArgumentList.SetValue(1, message.ArgumentList.GetValue(0));
    LMsg.ArgumentList.SetValue(2, message.ArgumentList.GetValue(1));

    //TODO ���Ը���render��ִ����Ϻ󣬿����Ƴ�����ص�����
    browser.SendProcessMessage(PID_RENDERER, LMsg);

    Result := True;
  end
  else if message.Name = BINDING_NAMESPACE + 'write' then
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


end.
