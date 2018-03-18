unit uBindingProxy;

interface

uses uCEFInterfaces, uCEFTypes;

type
  TBindingProxy = class
  private
    class procedure ExecuteInBrowser(Sender: TObject;
      const browser: ICefBrowser; sourceProcess: TCefProcessId;
      const message: ICefProcessMessage; out Result: Boolean); static;
  public
    class procedure BindJsTo(const ACefV8Context: ICefv8Context); static;

  end;

implementation

uses uCEFv8Value, uCEFConstants,
uBaseJsObjectBinding,
uSerialPortBinding;


//��context��ʼ��ʱ��js
class procedure TBindingProxy.BindJsTo(const ACefV8Context: ICefv8Context);
begin
  //�󶨱�Ӧ����Ҫ�ĸ�������ͺ���
  TBasicJsObjectBinding.BindJsTo(ACefV8Context.Global);
  TSerialPortBinding.BindJsTo(ACefV8Context.Global);
end;


//����Ĵ�����browser������ִ��
class procedure TBindingProxy.ExecuteInBrowser(Sender: TObject;
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; out Result: Boolean);
begin
  //Ҫ�����BasicJsBinding�����ζ�����ķ������д�����
  TBasicJsObjectBinding.ExecuteInBrowser(Sender, browser, sourceProcess, message, Result);
  if not Result then
    TSerialPortBinding.ExecuteInBrowser(Sender, browser, sourceProcess, message, Result);
end;


end.
