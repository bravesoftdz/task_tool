{
1.render���̵ĸ�������������������Ϣ��
  1.1 context��ʼ��ʱע����Ӧjs������Ӧ��handler
  1.2 ӵ�б�����������context�е����лص�������һ���б�
  1.3 ��������browser����Ϣ�Ӷ��ڻص������б��в��Ҳ���������Ӧ��js�ص�������
  1.4 context�ͷ��¼�ʱ����js�������ʱ�����js�ص����������ͷ�

  ���⣬�ص������б�Ĺ�����Ҫ��¼browser_id, ��Ӧbrowser����Ϣ����˵ĳ����Ϣ/�¼��Ļص���
  ����ص���������¼����Ǻ������¼��ص���Ҫ����֪�����Browser��Ӧ��context�ͷţ�������
  �ص����ڵ���ִ�к�ֱ���ͷţ�����Ӧ�ص�ִ�е�context������ִ��ʱ����Ҫcontext.enterΪ
  render�еĵ�ǰcontext�������Ҫִ�еĺ�������Ҳ����context����handlerʱע�ᵽ�ص�����
  �б��е�js�ص���������
}

unit uRENDER_ProcessProxy;

interface

uses
  uRENDER_JsCallbackList, uCEFInterfaces, uCEFConstants, uCEFTypes;

type
  TRENDER_ProcessProxy = class
  private

  public
    procedure OnContextCreated(const browser: ICefBrowser;
      const frame: ICefFrame; const context: ICefv8Context);

    procedure OnProcessMessageReceived(const browser: ICefBrowser; sourceProcess: TCefProcessId;
      const message: ICefProcessMessage; var aHandled : boolean);

    procedure OnContextReleased(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context);
  end;





implementation

uses uBasicJsBridge, uCEFv8Value, uCEFv8Types, uVVCefFunction;



{ TRenderProcessHelper }
procedure TRENDER_ProcessProxy.OnContextCreated(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context);
begin
  TBasicJsBridge.BindJsToContext(context);
end;



procedure TRENDER_ProcessProxy.OnContextReleased(const browser: ICefBrowser;
  const frame: ICefFrame; const context: ICefv8Context);
begin
  PRENDER_JsCallbackMgr.RemoveCallbackByContext(context);
end;



procedure TRENDER_ProcessProxy.OnProcessMessageReceived(
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; var aHandled: boolean);
var
  LContextCallback: TContextCallback;
  LArguments: TCefv8ValueArray;
  i: Integer;
  LFuncResult: ICefv8Value;
begin
  //�����������Ϣ�Ĳ�ͬ���ƣ�ȥȫ�ֵĻص����������б��в�����صĻص�������Ȼ�����������ִ�У�
  //����Ļص��������ڲ����д��ݹ����ģ��������Ծ������Ϣ����
  //��Ϣ���ƽ���������Ϊ�Ƿ��ĳ����Ϣ������ô���Ĵ������ھ���ִ���ĸ��ص������ǲ�һ����

  LContextCallback := PRENDER_JsCallbackMgr.GetCallback(browser.Identifier, message.Name);
  if LContextCallback <> nil then
  begin
    LContextCallback.Context.Enter;
    try
      try
        SetLength(LArguments, message.ArgumentList.GetSize);
        for i := 0 to message.ArgumentList.GetSize - 1 do
        begin
          LArguments[i] := CefValueToCefV8Value(message.ArgumentList.GetValue(i));
        end;

        LFuncResult := LContextCallback.CallbackFunc.ExecuteFunction(nil, LArguments);
        if LFuncResult.IsBool then
          aHandled := LFuncResult.GetBoolValue;
      finally
        SetLength(LArguments, 0);
      end;
    finally
      LContextCallback.Context.Exit;
    end;
  end;
end;

end.
