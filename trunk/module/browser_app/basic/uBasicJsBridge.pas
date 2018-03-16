//������render�����У�����jsv8�ĺ������������ļ�Ҫô�ǵ����ܹ��ṩ����Ҫô����
//browser���̷�����Ϣ
//�����̻��ṩһ�����ڽ�������browser���̵ķ�����������render�����е�jsv8��context���лص�
//����������context���յ���Ϣ��������chromiumʵ������Ķ����ˣ�Ҳ����jsv8��context��Ӧ��cefbrowser
//���⣬����һ����Ҫ�ѻص������Ķ�������������������ж��ڲ�ͬ�����¼��Ļص���������Щ�ص������ǿ����ڻص�
//���֮��ͽ����ͷŵģ�����Щ�������ĳ���¼��ļ�������ֱ������context���ͷţ��Ų���Ҫ����
//���������������render��ִ�еģ�ͬ����������Ҫһ����Ӧ��ʵ����������Щjs����������
//�����Ӧ�ķ���������Ӧ����browser�Ľ����д��ڵ�


unit uBasicJsBridge;

{$I cef.inc}

interface

uses
  uCEFTypes, uCEFInterfaces, uCEFv8Value, uCEFv8Handler, uCEFv8Context;

type
  TBasicJsBridge = class(TCefv8HandlerOwn)
  protected
    //Js Executed in Render Progress
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  public
    //Register Js to Context
    class procedure BindJsToContext(const AContext: ICefv8Context); virtual;

    //Js Executed in Browser Progress
    class procedure ExecuteInBrowser(Sender: TObject;
                      const browser: ICefBrowser; sourceProcess: TCefProcessId;
                      const message: ICefProcessMessage; out Result: Boolean); virtual;
  end;


implementation

uses Winapi.Windows, Vcl.Dialogs, System.SysUtils, Vcl.Forms, uCEFProcessMessage,
  uRENDER_JsCallbackList, uCEFValue, uCEFConstants;



//��context��ʼ��ʱ��js
class procedure TBasicJsBridge.BindJsToContext(const AContext: ICefv8Context);
var
  TempHandler  : ICefv8Handler;
  TempFunction : ICefv8Value;
begin
  TempHandler  := TBasicJsBridge.Create;

  TempFunction := TCefv8ValueRef.NewFunction('test_form', TempHandler);
  AContext.Global.SetValueByKey('test_form', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);

  TempFunction := TCefv8ValueRef.NewFunction('test_on_func', TempHandler);
  AContext.Global.SetValueByKey('test_on_func', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);

  TempFunction := TCefv8ValueRef.NewFunction('test_on_event', TempHandler);
  AContext.Global.SetValueByKey('test_on_event', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);
end;



//���������render������ִ��
function TBasicJsBridge.Execute(const name      : ustring;
                              const obj       : ICefv8Value;
                              const arguments : TCefv8ValueArray;
                              var   retval    : ICefv8Value;
                              var   exception : ustring): Boolean;
var
  LMsg: ICefProcessMessage;
  LContextCallback: TContextCallbackRec;
begin
  if (name = 'test_value') then
  begin
    retval := TCefv8ValueRef.NewString('My Value');
    Result := True;
  end
  else if (name = 'test_form') then
  begin
    LMsg := TCefProcessMessageRef.New('open_form');
    LMsg.ArgumentList.SetString(0, arguments[0].GetStringValue);
    TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);
    retval := TCefv8ValueRef.NewString('After Open Form!');
    Result := True;
  end
  else if (name = 'test_func') then
  begin
    retval := TCefv8ValueRef.NewString('My Func!');
    Result := True;
  end
  else if (name = 'test_on_func') then
  begin
    if (Length(arguments) = 2) and (arguments[0].IsString) and (arguments[1].IsFunction) then
    begin
      //��ӵ��ص������б���ȥ������һ������Ե��ַ�����������Ӧ���η�����õĻص�����
      LContextCallback.Context := TCefv8ContextRef.Current;
      LContextCallback.BrowserId := LContextCallback.Context.Browser.Identifier;
      LContextCallback.CallerName := name;
      LContextCallback.CallbackFunc := arguments[1];
      PRENDER_JsCallbackMgr.AddCallback(LContextCallback);

      //������Ϣ��browser����
      LMsg := TCefProcessMessageRef.New('test_on_func');
      LMsg.ArgumentList.SetString(0, arguments[0].GetStringValue);


      TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);
    end;
    Result := True;
  end
  else if (name = 'test_on_event') then
  begin
    if (Length(arguments) = 2) and (arguments[0].IsString) and (arguments[1].IsFunction) then
    begin
      //��ӵ��ص������б���ȥ��������Ϊ�������ɵĶ��󣬿����Ѿ����ڣ����ڻص���ֱ���ͷţ��ص��б������һ��
      LContextCallback.Context := TCefv8ContextRef.Current;
      LContextCallback.BrowserId := LContextCallback.Context.Browser.Identifier;
      LContextCallback.CallerName := name;
      LContextCallback.CallbackFunc := arguments[1];
      PRENDER_JsCallbackMgr.AddCallback(LContextCallback);

      //������Ϣ��browser����
      LMsg := TCefProcessMessageRef.New('test_on_event');
      LMsg.ArgumentList.SetString(0, arguments[0].GetStringValue);


      TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, LMsg);
    end;
    Result := True;
  end
  else
    Result := False;
end;



//����Ĵ�����browser������ִ��
class procedure TBasicJsBridge.ExecuteInBrowser(Sender: TObject;
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; out Result: Boolean);
var
  LMsg: ICefProcessMessage;
  LParams: ICefValue;
begin
  if message.Name = 'test_on_func' then
  begin
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
  else if message.Name = 'test_on_event' then
  begin
    //�ظ�һ���ص���������Ϣ��render�У�ͬʱɾ����Ӧ�ļ����ص�
    LMsg := TCefProcessMessageRef.New(message.Name);

    //������δ����Ӧ��ҵ���߼�����ӵ�BROWSER�����е��¼��б���ȥ��
    //��Ӧ�¼�����ʱ���·���Ϣ����
    LMsg.ArgumentList.SetValue(0, message.ArgumentList.GetValue(0));

    LParams := TCefValueRef.New;
    LParams.SetString('hello, ���ǲ����ַ���EVENT');
    LMsg.ArgumentList.SetValue(0, LParams);

    browser.SendProcessMessage(PID_RENDERER, LMsg);

    Result := True;
  end
  else
    Result := False;
end;

end.
