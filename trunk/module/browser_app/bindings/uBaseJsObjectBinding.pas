unit uBaseJsObjectBinding;

{$I cef.inc}

interface

uses
  uCEFV8Value, uCEFv8Accessor, uCEFInterfaces, uCEFTypes, uCEFConstants;

type
  TBasicJsObjectBinding = class(TCefV8AccessorOwn)
  private

  protected
    FTestVal: ustring;

    function Get(const name: ustring; const obj: ICefv8Value;
      out retval: ICefv8Value; var exception: ustring): Boolean; override;
    function Put(const name: ustring; const obj, value: ICefv8Value;
      var exception: ustring): Boolean; override;

  public
    class procedure BindJsTo(const ACefv8Value: ICefv8Value); static;
    class procedure ExecuteInBrowser(Sender: TObject;
      const browser: ICefBrowser; sourceProcess: TCefProcessId;
      const message: ICefProcessMessage; out Result: Boolean; const AFormHandle: THandle); static;
  end;

implementation

uses uBaseJsBinding, uCEFValue, uBROWSER_EventJsListnerList, uCEFProcessMessage, uXpFunctions;


//��context��ʼ��ʱ��js
class procedure TBasicJsObjectBinding.BindJsTo(const ACefv8Value: ICefv8Value);
var
  TempAccessor : ICefV8Accessor;
  TempObject   : ICefv8Value;
begin
  TempAccessor := TBasicJsObjectBinding.Create;


  TempObject   := TXpFunction.TCefv8ValueRef_NewObject(TempAccessor, nil);

  //�����Լ����������ĺ������߷���
  TBasicJsBinding.BindJsTo(TempObject);

  ACefv8Value.SetValueByKey('JSN_Base', TempObject, V8_PROPERTY_ATTRIBUTE_NONE);
end;


//����Ĵ�����browser������ִ��
class procedure TBasicJsObjectBinding.ExecuteInBrowser(Sender: TObject;
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; out Result: Boolean; const AFormHandle: THandle);
begin
  //Ҫ�����BasicJsBinding�����ζ�����ķ������д�����
  TBasicJsBinding.ExecuteInBrowser(Sender, browser, sourceProcess, message, Result, AFormHandle);
end;





//��������������Render��ִ��
function TBasicJsObjectBinding.Get(const name: ustring; const obj: ICefv8Value;
  out retval: ICefv8Value; var exception: ustring): Boolean;
begin
  Result := False;
end;


function TBasicJsObjectBinding.Put(const name: ustring; const obj: ICefv8Value;
  const value: ICefv8Value; var exception: ustring): Boolean;
begin
  Result := False;
end;



end.
