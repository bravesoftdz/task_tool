unit uJobAsyncHandlerForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBasicForm, uFileLogger;


const
  VV_MSG_HANDLE_ASYNC_JOB = WM_USER + 2000;

type
  TJobAsyncHandlerForm = class(TBasicForm)
  private
    { Private declarations }
    procedure MSGHandleAsyncJob(var AMsg: TMessage); message VV_MSG_HANDLE_ASYNC_JOB;
  public
    { Public declarations }
  end;

var
  JobAsyncHandlerForm: TJobAsyncHandlerForm;

implementation

uses uJobDispatcher, uDefines;

{$R *.dfm}

{ TJobAsyncHandlerForm }

procedure TJobAsyncHandlerForm.MSGHandleAsyncJob(var AMsg: TMessage);
var
  LJobDispatcher: TJobDispatcher;
  LJobDispatcherRec: PJobDispatcherRec;
begin
  if AMsg.Msg <> VV_MSG_HANDLE_ASYNC_JOB then Exit;

  LJobDispatcherRec := PJobDispatcherRec(AMsg.WParam);
  if LJobDispatcher = nil then
  begin
    AppLogger.Error('�յ��յ�ַ�ַ�ָ��');
    Exit;
  end;

  //��������jobdispatcher��ֱ�ӵ���
  LJobDispatcher := TJobDispatcher.Create;
  try
    LJobDispatcher.StartProjectJob(LJobDispatcherRec);

    //�������������κν�����������ִ��ָ��ʽ�����񣬺�������ͨ�������첽��ʽ֪ͨ���÷�
  finally
    LJobDispatcher.Free;
  end;
end;

end.
