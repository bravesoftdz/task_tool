unit uSerialPortBinding;

{$I cef.inc}

interface

uses
  uCEFV8Value, uCEFv8Accessor, uCEFInterfaces, uCEFTypes, uCEFConstants,
  uCEFv8Handler, System.Generics.Collections, SPComm;

type
  TSerialPortConnectRec = record
    CommName: string;

    OnDataReceivedCallbackFunc: ICefv8Value;
    Context: ICefv8Context;
    BrowserId: Integer;
  end;

  //��������Ӧ��comm����comm���ƣ��Լ���Ӧ�Ļص�����
  TSerialPort = class
  private
    //��sp�Ļ������ò����ı���


    //ʵ�ʵ�����ʵ��
    FComm: TComm;
  public
    CommName: string;


    constructor Create;
    destructor Destroy; override;

    procedure Connect;

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
  protected
    //Js Executed in Render Progress
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  public

    //Register Js to Context
    class procedure BindJsTo(const ACefv8Value: ICefv8Value); virtual;
  end;

  TSerialPortBinding = class
  private
  protected
  public
    class procedure BindJsTo(const ACefv8Value: ICefv8Value); static;
  end;

var
  RENDER_SerialPortMgr: TSerialPortMgr;


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
    //֪ͨmgr��Ҫ���ĸ�comm����ӶԵ�ǰcontext�Ļ��������ļ������ص�����������ӵ�callbacks�У��������������
    //���Ǳ�������Ǽ������ĸ�comm�ڵĻص����������idxname
    LSerialPortConnectRec.CommName := arguments[0].GetStringValue;
    LSerialPortConnectRec.OnDataReceivedCallbackFunc := arguments[0];
    LSerialPortConnectRec.Context := TCefv8ContextRef.Current;
    LSerialPortConnectRec.BrowserId := TCefv8ContextRef.Current.Browser.Identifier;
    if RENDER_SerialPortMgr.ConnectTo(LSerialPortConnectRec) then
    begin
      //ע����߸��»ص�����
      LCefV8Accessor := TCefV8AccessorOwn.Create;
      LResult := TCefv8ValueRef.NewObject(LCefV8Accessor, nil);
      LResult.SetValueByKey('disconnect', TCefv8ValueRef.NewFunction('disconnect', Self), V8_PROPERTY_ATTRIBUTE_NONE);
      LResult.SetValueByKey('port_name', TCefv8ValueRef.NewString('COMMMMMM1'), V8_PROPERTY_ATTRIBUTE_NONE);
      retval := LResult;
    end
    else
    begin
      exception := 'connect to serial port failed!';
    end;
    Result := True;
  end
  else if (name = 'disconnect') then
  begin
    if obj.IsObject then
    begin
      //֪ͨmgr�ĸ�context��sp���ĸ��˿���Ҫ�Ͽ�����
      RENDER_SerialPortMgr.DisconnectFrom(obj.GetValueByKey('port_name').GetStringValue);
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

    //�����ص��������
    LCallback.Context := ARec.Context;
    LCallback.BrowserId := ARec.BrowserId;
    LCallback.CallbackFuncType := cftEvent;
    LCallback.IdxName := BINDING_NAMESPACE + 'connect/' + ARec.CommName;
    LCallback.CallbackFunc := ARec.OnDataReceivedCallbackFunc;
    if RENDER_JsCallbackList.AddCallback(LCallback) <> '' then
    begin
      FCommList.Add(LSerialPort);
      Result := True;
    end
    else
      LSerialPort.Free;
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
    if (FCommList.Items[i] <> nil) and (FCommList.Items[i].CommName = AComm) then
    begin
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

procedure TSerialPort.Connect;
begin
  //���ò�����ͬʱ�������ݽ����¼�

end;

constructor TSerialPort.Create;
begin
  inherited;
  FComm := TComm.Create(nil);
  FComm.OnReceiveData := OnCommReceiveData;
end;

destructor TSerialPort.Destroy;
begin
  FComm.Free;
  inherited;
end;


procedure TSerialPort.Disconnect;
begin
  //�������б����û���¼������ˣ�������ͷ�

end;


procedure TSerialPort.OnCommReceiveData(Sender: TObject; Buffer: Pointer;
  BufferLength: Word);
begin
  //���ûص������б��еĻص�����

end;


end.
