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

uses uBindingProxy, uCEFv8Value, uCEFv8Types, uVVCefFunction, uVVConstants;



{ TRenderProcessHelper }
procedure TRENDER_ProcessProxy.OnContextCreated(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context);
begin
  TBindingProxy.BindJsTo(context);
end;



procedure TRENDER_ProcessProxy.OnContextReleased(const browser: ICefBrowser;
  const frame: ICefFrame; const context: ICefv8Context);
begin
  RENDER_JsCallbackList.RemoveCallbackByContext(context);
end;



procedure TRENDER_ProcessProxy.OnProcessMessageReceived(
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; var aHandled: boolean);
var
  LContextCallback: TContextCallback;
  LArguments: TCefv8ValueArray;
  i: Integer;
  LFuncResult: ICefv8Value;
  LCallbackIdxName: string;
begin
  //�����������Ϣ�Ĳ�ͬ���ƣ�ȥȫ�ֵĻص����������б��в�����صĻص�������Ȼ�����������ִ�У�
  //����Ļص��������ڲ����д��ݹ����ģ��������Ծ������Ϣ����
  //��Ϣ���ƽ���������Ϊ�Ƿ��ĳ����Ϣ������ô���Ĵ������ھ���ִ���ĸ��ص������ǲ�һ����
  if message.Name = IPC_MSG_EXEC_CALLBACK then
  begin
    //��ȡ��һ����������һ�����������ص�����������
    if message.ArgumentList.GetSize = 0 then Exit;

    LCallbackIdxName := message.ArgumentList.GetString(0);

    LContextCallback := RENDER_JsCallbackList.GetCallback(browser.Identifier, LCallbackIdxName);
    if LContextCallback <> nil then
    begin
      LContextCallback.Context.Enter;
      try
        try
          SetLength(LArguments, message.ArgumentList.GetSize - 1);
          for i := 1 to Length(LArguments) do
          begin
            LArguments[i - 1] := CefValueToCefV8Value(message.ArgumentList.GetValue(i));
          end;

          LFuncResult := LContextCallback.CallbackFunc.ExecuteFunction(nil, LArguments);
          if LFuncResult.IsBool then
            aHandled := LFuncResult.GetBoolValue;
        finally
          SetLength(LArguments, 0);
        end;
      finally
        LContextCallback.Context.Exit;

        if LContextCallback.CallbackFuncType = cftFunction then
        begin
          RENDER_JsCallbackList.RemoveCallback(LContextCallback);
        end;
      end;
    end;
  end;
end;

end.
