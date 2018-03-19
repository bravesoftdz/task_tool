unit uSerialPortBinding;

{$I cef.inc}

interface

uses
  uCEFV8Value, uCEFv8Accessor, uCEFInterfaces, uCEFTypes, uCEFConstants,
  uCEFv8Handler, System.Generics.Collections, SPComm;

type
  //��������Ӧ��comm����comm���ƣ��Լ���Ӧ�Ļص�����
  TSerialPort = class
  private
        //��sp�Ļ������ò����ı���
    FCommName: string;

    //ʵ�ʵ�����ʵ��
    FComm: TComm;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Connect;

    //ά��һ���������������ݣ����Ҹ������Ƶ����ɹ����ڻص��������ҵ���Ӧ�ķ��������ҷ���ص���
    //�����ȡ���Ļص��б�Ϊ�գ��򱾺������Զ��ͷű�ʵ�������ٽ��м���
    procedure OnCommDataReceived;

    //ά��һ����������Ӧdisconnect����ʱ�ڻص������в����Ƿ��л��������ص����������û�У���ֱ�����ٱ�ʵ��
    procedure Disconnect;
  end;


  TSerialPortMgr = class
  private
    FCommList: TObjectList<TSerialPort>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ConnectTo(AParams: string);
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


implementation

uses uBaseJsBinding, uCEFValue, uBROWSER_EventJsListnerList, uCEFProcessMessage,
uRENDER_JsCallbackList, uCEFv8Context, uVVConstants;

const
  BINDING_NAMESPACE = 'SERIAL_PORT/';

var
  RENDER_SerialPortMgr: TSerialPortMgr;

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
begin
  LMsgName := BINDING_NAMESPACE + name;
  if (name = 'connect') then
  begin
    LCefV8Accessor := TCefV8AccessorOwn.Create;
    LResult := TCefv8ValueRef.NewObject(LCefV8Accessor, nil);
    LResult.SetValueByKey('disconnect', TCefv8ValueRef.NewFunction('disconnect', Self), V8_PROPERTY_ATTRIBUTE_NONE);
    LResult.SetValueByKey('port_name', TCefv8ValueRef.NewString('COMMMMMM1'), V8_PROPERTY_ATTRIBUTE_NONE);

    //֪ͨmgr��Ҫ���ĸ�comm����ӶԵ�ǰcontext�Ļ��������ļ������ص�����������ӵ�callbacks�У��������������
    //���Ǳ�������Ǽ������ĸ�comm�ڵĻص����������idxname

    //mgr���𴴽�comm�ڣ����Ҷ����comm�ڸ�������Լ��¼��Ĵ����������յ�����ʱ�����callbacks�б���
    //�ҳ���Ӧ�Ļص���������ִ��


    retval := LResult;
    Result := True;
  end
  else if (name = 'disconnect') then
  begin
    if obj.IsObject then
    begin
      //֪ͨmgr�ĸ�context��sp���ĸ��˿���Ҫ�Ͽ�����
      retval := obj.GetValueByKey('port_name');
    end
    else
      retval := TCefv8ValueRef.NewString('no object');

    //������֪����ǰ��context���Ӷ�������comport�ļ����б����Ƴ���Ӧ�Ļص�����
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

procedure TSerialPortMgr.ConnectTo(AParams: string);
begin
  //��list�в����Ƿ��ж�Ӧcomm�ڵļ�����������У���ֱ��

end;


constructor TSerialPortMgr.Create;
begin
  inherited;

end;


destructor TSerialPortMgr.Destroy;
begin

  inherited;
end;


procedure TSerialPortMgr.DisconnectFrom(AComm: string);
begin

end;

{ TSerialPort }

procedure TSerialPort.Connect;
begin

end;

constructor TSerialPort.Create;
begin
  inherited;

end;

destructor TSerialPort.Destroy;
begin

  inherited;
end;

procedure TSerialPort.Disconnect;
begin

end;

procedure TSerialPort.OnCommDataReceived;
begin

end;

end.
