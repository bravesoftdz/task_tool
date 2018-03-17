{
 ������������js����ʱ����Ҫ�ص��������б�
 ע�᣺�ڵ���ʱ����ע��
 �ͷţ�a) ���ں����Ļص���������ִ����֮����������
       b) �����¼��Ļص��������ڱ�context�ͷ�ʱͳһ�������
 ��mgr�й��������Բ�ͬ��context�еĻص�������render����ͨ��
}
unit uRENDER_JsCallbackList;

interface

uses
  uCEFInterfaces, System.Generics.Collections;

type
  TCallerFuncType = (cftEvent, cftFunction);

  TContextCallbackRec = record
    BrowserId: Integer;

    IdxName: string;
    CallbackFuncType: TCallerFuncType;
    CallbackFunc: ICefv8Value;
    Context: ICefv8Context;
  end;

  TContextCallback = class
    BrowserId: Integer;
    IdxName: string;
    CallbackFuncType: TCallerFuncType;
    CallbackFunc: ICefv8Value;
    Context: ICefV8Context;
  end;


  TRENDER_JsCallbackList = class
  private
    FCallbacks: TObjectList<TContextCallback>;
    function AddCallback(ACb: TContextCallback): Integer; overload;
    function RemoveCallbackByBrowserId(ABrowserId: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    //ִ���ҵ���ӦBrowser�Ĳ�������ִ��
    function AddCallback(ACb: TContextCallbackRec): string; overload;
    function RemoveCallback(ACb: TContextCallback): Boolean;
    function RemoveCallbackByContext(AContext: ICefV8Context): Boolean;
    function GetCallback(ABrowserId: Integer; AIdxName: string): TContextCallback;

    function MakeCallbackIdxName: string;
  end;

var
  RENDER_JsCallbackList: TRENDER_JsCallbackList;

implementation

uses System.SysUtils;

{ TRenderJsCallbackMgr }


//����һ��Ψһ�����Ļص�����idxname
function TRENDER_JsCallbackList.AddCallback(ACb: TContextCallbackRec): string;
var
  LContextCallback: TContextCallback;
begin
  Result := '';
  if ACb.IdxName <> '' then
  begin
    ACb.CallbackFuncType := cftEvent;
    LContextCallback := GetCallback(Acb.BrowserId, ACb.IdxName);
    if LContextCallback <> nil then
    begin
      Result := LContextCallback.IdxName;
      Exit;
    end;
  end
  else
  begin
    ACb.CallbackFuncType := cftFunction;
    Acb.IdxName := MakeCallbackIdxName;
  end;

  //������
  LContextCallback := TContextCallback.Create;
  try
    LContextCallback.BrowserId := ACb.BrowserId;
    LContextCallback.IdxName := ACb.IdxName;
    LContextCallback.CallbackFuncType := ACb.CallbackFuncType;
    LContextCallback.CallbackFunc := ACb.CallbackFunc;
    LContextCAllback.Context := ACb.Context;

    if AddCallback(LContextCallback) < 0 then
      LContextCallback.Free
    else
      Result := ACb.IdxName;
  except
    on E: Exception do
    begin
      if LContextCallback <> nil then
        LContextCallback.Free;
    end;
  end;
end;


function TRENDER_JsCallbackList.AddCallback(ACb: TContextCallback): Integer;
var
  i: Integer;
begin
  //���ݶ�Ӧ��id��msg_name����ƥ�䣬����msg_type�������Ӧcontext�Ļص����Ѿ�
  //���������ֵ����ֱ�ӽ��ж����������ͷ����Acb
  Result := -1;
  if GetCallback(ACb.BrowserId, ACb.IdxName) = nil then
    Result := FCallbacks.Add(ACb);
end;


constructor TRENDER_JsCallbackList.Create;
begin
  inherited;
  FCallbacks := TObjectList<TContextCallback>.Create(False);
end;


destructor TRENDER_JsCallbackList.Destroy;
var
  i: Integer;
begin
  for i := FCallbacks.Count - 1 downto 0 do
  begin
    if FCallbacks.Items[i] <> nil then
    begin
      FCallbacks.Items[i].Free;
    end;
  end;
  FCallbacks.Free;
  inherited;
end;


function TRENDER_JsCallbackList.GetCallback(ABrowserId: Integer;
  AIdxName: string): TContextCallback;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to FCallbacks.Count - 1 do
  begin
    if FCallbacks.Items[i] <> nil then
    begin
      if (FCallbacks.Items[i].BrowserId = ABrowserId)
        and (FCallbacks.Items[i].IdxName = AIdxName) then
      begin
        Result := FCallbacks.Items[i];
        Break;
      end;
    end;
  end;
end;


function TRENDER_JsCallbackList.MakeCallbackIdxName: string;
begin
  Result := IntToStr(FCallbacks.Count) + '_' + FormatDateTime('yymmddhhnnsszzz', Now);
end;

function TRENDER_JsCallbackList.RemoveCallback(ACb: TContextCallback): Boolean;
begin
  if ACb <> nil then
  begin
    FCallbacks.Remove(ACb);
    ACb.Free;
  end;
end;

function TRENDER_JsCallbackList.RemoveCallbackByBrowserId(
  ABrowserId: Integer): Boolean;
var
  i: Integer;
begin
  for i := FCallbacks.Count - 1 downto 0 do
  begin
    if FCallbacks.Items[i] <> nil then
    begin
      if FCallbacks.Items[i].BrowserId = ABrowserId then
      begin
        FCallbacks.Items[i].Free;
        FCallbacks.Delete(i);
      end;
    end;
  end;
end;


function TRENDER_JsCallbackList.RemoveCallbackByContext(
  AContext: ICefV8Context): Boolean;
var
  i: Integer;
begin
  for i := FCallbacks.Count - 1 downto 0 do
  begin
    if FCallbacks.Items[i] <> nil then
    begin
      if FCallbacks.Items[i].Context.IsSame(AContext) then
      begin
        FCallbacks.Items[i].Free;
        FCallbacks.Delete(i);
      end;
    end;
  end;
end;

end.
