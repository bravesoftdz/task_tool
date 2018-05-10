unit uSerialPortBinding;

{$I cef.inc}

interface

uses
  uCEFV8Value, uCEFv8Accessor, uCEFInterfaces, uCEFTypes, uCEFConstants,
  uCEFv8Handler, System.Generics.Collections, SPComm, Vcl.ExtCtrls;

type
  TSerialPortConnectRec = record
    CommName: string;
    CallbackIdxName: string;
    Browser: ICefBrowser;
  end;

  //��������Ӧ��comm����comm���ƣ��Լ���Ӧ�Ļص�����
  TSerialPort = class
  private
    //��sp�Ļ������ò����ı���
    FTimer: TTimer;

    //ʵ�ʵ�����ʵ��
    FComm: TComm;
    procedure OnTestTimer(Sender: TObject);
  public
    CommName: string;
    ConnectRec: TSerialPortConnectRec;


    constructor Create;
    destructor Destroy; override;

    procedure Connect(AConnectRec: TSerialPortConnectRec);

    //ά��һ���������������ݣ����Ҹ������Ƶ����ɹ����ڻص��������ҵ���Ӧ�ķ��������ҷ���ص���
    //�����ȡ���Ļص��б�Ϊ�գ��򱾺������Զ��ͷű�ʵ�������ٽ��м���
    procedure OnCommReceiveData(Sender: TObject; Buffer: Pointer; BufferLength: Word);

    //ά��һ����������Ӧdisconnect����ʱ�ڻص������в����Ƿ��л��������ص����������û�У���ֱ�����ٱ�ʵ��
    procedure Disconnect;
  end;


  TSerialPortMgr = class
  private
    FCommList: TObjectList<TSerialPort>;
    function GetCommSerialPort(AComm: string): TSerialPort;
  public
    constructor Create;
    destructor Destroy; override;
    function ConnectTo(ARec: TSerialPortConnectRec): Boolean;
    procedure DisconnectFrom(AComm: string);
  end;

  TSerialPortFunctionBinding = class(TCefv8HandlerOwn)
  private
  protected
    //Js Executed in Render Progress
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  public

    //Register Js to Context
    class procedure BindJsTo(const ACefv8Value: ICefv8Value); virtual;
    class procedure ExecuteInBrowser(Sender: TObject;
      const browser: ICefBrowser; sourceProcess: TCefProcessId;
      const message: ICefProcessMessage; out Result: Boolean; const AFormHandle: THandle); static;
  end;

  TSerialPortBinding = class
  private
  protected
  public
    class procedure BindJsTo(const ACefv8Value: ICefv8Value); static;
  end;

var
  BROWSER_SerialPortMgr: TSerialPortMgr;


implementation

uses uBaseJsBinding, uCEFValue, uBROWSER_EventJsListnerList, uCEFProcessMessage,
uRENDER_JsCallbackList, uCEFv8Context, uVVConstants, System.SysUtils;

const
  BINDING_NAMESPACE = 'SERIAL_PORT/';

//��context��ʼ��ʱ��js
class procedure TSerialPortBinding.BindJsTo(const ACefv8Value: ICefv8Value);
var
  TempAccessor : ICefV8Accessor;
  TempObject   : ICefv8Value;
begin
  TempAccessor := TCefV8AccessorOwn.Create;
  TempObject   := TCefv8ValueRef.NewObject(TempAccessor, nil);

  //�����Լ����������ĺ������߷���
  TSerialPortFunctionBinding.BindJsTo(TempObject);

  ACefv8Value.SetValueByKey('JSN_SerialPort', TempObject, V8_PROPERTY_ATTRIBUTE_NONE);
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
  LResult: ICefv8Value;
  LCefV8Accessor: ICefV8Accessor;
  LSerialPortConnectRec: TSerialPortConnectRec;
begin
  LMsgName := BINDING_NAMESPACE + name;
  if (name = 'connect') then
  begin
    //�������ж��Ƿ��ǺϷ��Ĵ�������
    if (Length(arguments) = 2) and (arguments[0].IsString) and (arguments[1].IsFunction) then
    begin
      LContextCallback.Context := TCefv8ContextRef.Current;
      LContextCallback.BrowserId := LContextCallback.Context.Browser.Identifier;
      LContextCallback.IdxName := BINDING_NAMESPACE + 'connect/' + arguments[0].GetStringValue;
      LContextCallback.CallbackFuncType := cftEvent;
      LContextCallback.CallbackFunc := arguments[1];
      LCallbackIdxName := RENDER_JsCallbackList.AddCallback(LContextCallback);

      LMsg := TCefProcessMessageRef.New(LMsgName);
      LMsg.ArgumentList.SetString(0, arguments[0].GetStringValue);
      LMsg.ArgumentList.SetString(1, LContextCallback.IdxName);

      //������Ϣ��BROWSER����
      TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);

      //ע����߸��»ص�����
      LCefV8Accessor := TCefV8AccessorOwn.Create;
      LResult := TCefv8ValueRef.NewObject(LCefV8Accessor, nil);
      LResult.SetValueByKey('disconnect', TCefv8ValueRef.NewFunction('disconnect', Self), V8_PROPERTY_ATTRIBUTE_NONE);
      LResult.SetValueByKey('port_name', arguments[0], V8_PROPERTY_ATTRIBUTE_NONE);
      retval := LResult;
    end
    else
      exception := 'connect params error';
    Result := True;
  end
  else if (name = 'disconnect') then
  begin
    if obj.IsObject then
    begin
      //������Ϣ��browser���Ͽ���ĳ���˿ڵļ���
      LMsg := TCefProcessMessageRef.New(LMsgName);
      LMsg.ArgumentList.SetString(0, obj.GetValueByKey('port_name').GetStringValue);

      TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);

      retval := TCefv8ValueRef.NewBool(True);
    end
    else
      exception := 'no serial port to disconnected!';

    Result := True;
  end
  else if (name = 'write') then
  begin
    if obj.IsObject then
    begin
      //֪ͨmgr�ĸ�context��sp���ĸ��˿���Ҫ�Ͽ�����
      retval := obj.GetValueByKey('port_name');
    end
    else
      retval := TCefv8ValueRef.NewString('no object');

    Result := True;
  end
  else
    Result := False;
end;


//����Ĵ�����browser������ִ��
class procedure TSerialPortFunctionBinding.ExecuteInBrowser(Sender: TObject;
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; out Result: Boolean; const AFormHandle: THandle);
var
  LMsg: ICefProcessMessage;
  LParams: ICefValue;
  LJsListnerRec: TEventJsListnerRec;
  LSerialPortConnectRec: TSerialPortConnectRec;
begin
  if message.Name = BINDING_NAMESPACE + 'connect' then
  begin
    //��ӵ�BROWSER�Ĵ����б���ȥ
    LSerialPortConnectRec.CommName := message.ArgumentList.GetString(0);
    LSerialPortConnectRec.Browser := browser;
    LSerialPortConnectRec.CallbackIdxName := message.ArgumentList.GetString(1);
    BROWSER_SerialPortMgr.ConnectTo(LSerialPortConnectRec);

    Result := True;
  end
  else if message.Name = BINDING_NAMESPACE + 'disconnect' then
  begin
    //��Browser_mgr�����Ƴ������Ǹ��Ķ˿ڼ���
    BROWSER_SerialPortMgr.DisconnectFrom(message.ArgumentList.GetString(0));

    Result := True;
  end
  else
    Result := False;
end;


{ TSerialPortMgr }

function TSerialPortMgr.ConnectTo(ARec: TSerialPortConnectRec): Boolean;
var
  LSerialPort: TSerialPort;
  LCallback: TContextCallbackRec;
begin
  //��list�в����Ƿ��ж�Ӧcomm�ڵļ�����������У���ֱ�ӷ����������Ȼ��ص��������ӵ��б���
  Result := False;
  LSerialPort := GetCommSerialPort(ARec.CommName);

  if LSerialPort = nil then
  begin
    LSerialPort := TSerialPort.Create;
    LSerialPort.CommName := ARec.CommName;
    LSerialPort.ConnectRec := ARec;
    LSerialPort.Connect(ARec);

    FCommList.Add(LSerialPort);
  end;
end;


constructor TSerialPortMgr.Create;
begin
  inherited;
  FCommList := TObjectList<TSerialPort>.Create(False);
end;


destructor TSerialPortMgr.Destroy;
var
  i: Integer;
begin
  for i := FCommList.Count - 1 downto 0 do
  begin
    //��������ص�����
    if FCommList.Items[i] is TSerialPort then
      FCommList.Items[i].Free;
  end;
  FCommList.Free;
  inherited;
end;


procedure TSerialPortMgr.DisconnectFrom(AComm: string);
var
  i: Integer;
begin
  for i := 0 to FCommList.Count - 1 do
  begin
    if (FCommList.Items[i] <> nil) and (FCommList.Items[i].ConnectRec.CommName = AComm) then
    begin
      FCommList.Items[i].Disconnect;
      FCommList.Items[i].Free;
      FCommList.Delete(i);
      Break;
    end;
  end;
end;


function TSerialPortMgr.GetCommSerialPort(AComm: string): TSerialPort;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to FCommList.Count - 1 do
  begin
    if (FCommList.Items[i] <> nil) and (FCommList.Items[i].CommName = AComm) then
    begin
      Result := FCommList.Items[i];
      Break;
    end;
  end;
end;


{ TSerialPort }

procedure TSerialPort.Connect(AConnectRec: TSerialPortConnectRec);
begin
  //���ò�����ͬʱ�������ݽ�����
  ConnectRec := AConnectRec;
  FTimer.Enabled := True;
end;

constructor TSerialPort.Create;
begin
  inherited;
  FComm := TComm.Create(nil);
  FComm.OnReceiveData := OnCommReceiveData;
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 50;
  FTimer.Enabled := False;
  FTimer.OnTimer := OnTestTimer;
end;

destructor TSerialPort.Destroy;
begin
  FTimer.Free;
  FComm.Free;
  inherited;
end;


procedure TSerialPort.Disconnect;
begin
  //�������б����û���¼������ˣ�������ͷ�
  FTimer.Enabled := False;
end;


procedure TSerialPort.OnCommReceiveData(Sender: TObject; Buffer: Pointer;
  BufferLength: Word);
begin
  //���ûص������б��еĻص�����

end;

procedure TSerialPort.OnTestTimer(Sender: TObject);
var
  LCallback: TContextCallback;
  LMsg: ICefProcessMessage;
begin
  //���ûص������б��еĻص�����
  LMsg := TCefProcessMessageRef.New(IPC_MSG_EXEC_CALLBACK);
  LMsg.ArgumentList.SetString(0, ConnectRec.CallbackIdxName);
  LMsg.ArgumentList.SetString(1, FormatDateTime('yyyymmddhhnnss.zzz', Now));
  ConnectRec.Browser.SendProcessMessage(PID_RENDERER, LMsg);
end;


end.

