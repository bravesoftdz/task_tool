unit uBROWSER_EventJsListnerList;

interface

uses System.Generics.Collections, uCEFInterfaces;

type
  TEventJsListnerRec = record
    EventName: string;

    BrowserId: Integer;
    Browser: ICefBrowser;
    ListnerMsgName: string;
  end;

  TEventJsListner = class
    EventName: string;

    BrowserId: Integer;
    Browser: ICefBrowser;
    ListnerMsgName: string;
  end;

  TBROWSER_EventJsListnerList = class
  private
    FListnerList: TObjectList<TEventJsListner>;
  public
    constructor Create;
    destructor Destroy; override;

    function AddEventListner(AEventJsListnerRec: TEventJsListnerRec): Integer;
    procedure EventNotify(ABrowser: ICefBrowser; AEventName: string; AArgs: ICefValue = nil);
    procedure RemoveListners(AEventName: string); overload;
    procedure RemoveListners(ABrowser: ICefBrowser); overload;
    procedure RemoveListners(ABrowser: ICefBrowser; AEventName: string); overload;
  end;

var
  BROWSER_EventJsListnerList: TBROWSER_EventJsListnerList;

implementation

uses uCEFTypes, uCEFProcessMessage;

{ TBROWSER_EventListnerList }

constructor TBROWSER_EventJsListnerList.Create;
begin
  inherited;
  FListnerList := TObjectList<TEventJsListner>.Create(False);
end;


destructor TBROWSER_EventJsListnerList.Destroy;
var
  i: Integer;
begin
  for i := FListnerList.Count - 1 downto 0 do
  begin
    if FListnerList.Items[i] <> nil then
      FListnerList.Items[i].Free;
  end;
  FListnerList.Free;
  inherited;
end;


procedure TBROWSER_EventJsListnerList.EventNotify(ABrowser: ICefBrowser; AEventName: string; AArgs: ICefValue);
var
  LProcessMsg: ICefProcessMessage;
begin
  //�����б��ҳ���Ӧ��listner��Ӧ��func�������µ�event_name
  LProcessMsg := TCefProcessMessageRef.New(AEventName);
  LProcessMsg.ArgumentList.SetValue(0, AArgs);
  ABrowser.SendProcessMessage(PID_RENDERER, LProcessMsg);
end;



function TBROWSER_EventJsListnerList.AddEventListner(AEventJsListnerRec: TEventJsListnerRec): Integer;
begin
  //����¼����������б��У��¼�����ʱ���ӱ��¼��������б��л�ȡ�ص�
  //ע�⣬��ôҲ�����ṩһ����������ĳ��ʱ��ִ�У��¼��е�listner������browser�ͷŵ�ʱ������ͷ�


end;


procedure TBROWSER_EventJsListnerList.RemoveListners(AEventName: string);
begin

end;


procedure TBROWSER_EventJsListnerList.RemoveListners(ABrowser: ICefBrowser);
begin

end;


procedure TBROWSER_EventJsListnerList.RemoveListners(ABrowser: ICefBrowser; AEventName: string);
begin

end;


end.


