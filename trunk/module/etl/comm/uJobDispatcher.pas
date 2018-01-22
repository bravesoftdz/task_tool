unit uJobDispatcher;

interface

uses uJobMgr, uJob, uFileLogger;

type
  PJobDispatcherRec = ^TJobdispatcherRec;

  TJobDispatcherRec = record
    ProjectFile: string;
    JobName: string;
    InParams: string;
  end;

  //��֧�ֵ��߳�ģʽ��֧�ֶԽ���������֧����Σ�������ʵ��֧������һ������
  TJobDispatcher = class(TJobMgr)
  private
    FInParams: string;
    FOutResult: string;
  protected
    procedure StartJob(AJob: TJobConfig); override;
  public
    constructor Create(const ALogLevel: TLogLevel = llAll); overload;

    procedure StartProjectJob(const AJobDispatcherRec: PJobDispatcherRec);
  end;

implementation

uses
  uTaskDefine, uDefines, uTask, System.SysUtils;

{ TJobDispatcher }

constructor TJobDispatcher.Create(const ALogLevel: TLogLevel);
begin
  inherited Create(0, ALogLevel);
end;
//
//
procedure TJobDispatcher.StartJob(AJob: TJobConfig);
var
  LTaskConfigRec: TTaskConfigRec;
begin
  if not CheckJobTask(AJob) then
  begin
    AppLogger.Debug('Pop Job �����쳣��' + AJob.JobName);
    Exit;
  end;

  //��������task��ִ��
  LTaskConfigRec := AJob.TaskConfigRec;
  LTaskConfigRec.RunBasePath := FRunBasePath;
  LTaskConfigRec.DBsConfigFile := DbsConfigFile;
  AJob.Task := TTask.Create(LTaskConfigRec);
  try
    AJob.HandleStatus := jhsRun;
    AJob.Task.TaskVar.GlobalVar := FGlobalVar;
    AJob.Task.TaskVar.Logger.LogLevel := FLogLevel;
    AJob.Task.TaskVar.Logger.NoticeHandle := CallerHandle;
    try
      AJob.LastStartTime := Now;
      AJob.RunThread := nil;
      AJob.JobRequest := nil;

      AJob.Task.TaskVar.Logger.Force('����ʼ'+ AJob.JobName);
      AppLogger.Force('��ʼִ�й�����' + AJob.JobName);
      AJob.Task.Start;
      AppLogger.Force('����ִ�й�����' + AJob.JobName);
      AJob.Task.TaskVar.Logger.Force('�������'+ AJob.JobName);
    except
      on E: Exception do
      begin
        AJob.LastStartTime := 0;
        AppLogger.Fatal('ִ�й����쳣�˳���' + AJob.JobName + '��ԭ��' + E.Message);
      end;
    end;
  finally
    AJob.FreeTask;
  end;
end;



procedure TJobDispatcher.StartProjectJob(const AJobDispatcherRec: PJobDispatcherRec);
begin
  //����������ͷ�
  try
    if LoadConfigFrom(AJobDispatcherRec.ProjectFile, AJobDispatcherRec.JobName) then
    begin
      StartJob(AJobDispatcherRec.JobName);
    end
    else
    begin
      AppLogger.Fatal('����Project�ļ�ʧ��');
      Exit;
    end;
  finally
    if AJobDispatcherRec <> nil then
      Dispose(AJobDispatcherRec);
  end;
end;

end.
