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

  TOutResult = record
    Code: Integer;
    Msg: string;
    Data: string;
  end;


  //��֧�ֵ��߳�ģʽ��֧�ֶԽ���������֧����Σ�������ʵ��֧������һ������
  TJobDispatcher = class(TJobMgr)
  private
    FInParams: string;
    FOutResult: TOutResult;
  protected
    procedure StartJob(AJob: TJobConfig); override;
  public
    constructor Create(const ALogLevel: TLogLevel = llAll); overload;

    procedure StartProjectJob(const AJobDispatcherRec: PJobDispatcherRec);

    property OutResult: TOutResult read FOutResult;
  end;

implementation

uses
  uTaskDefine, uDefines, uTask, System.SysUtils, uStepDefines;

{ TJobDispatcher }

constructor TJobDispatcher.Create(const ALogLevel: TLogLevel);
begin
  inherited Create(0, ALogLevel);
  FOutResult.Code := -1;
  FOutResult.Msg := '����ʧ��';
end;



procedure TJobDispatcher.StartJob(AJob: TJobConfig);
var
  LTaskConfigRec: TTaskConfigRec;
  LTaskInitParams: PStepData;
begin
  if not CheckJobTask(AJob) then
  begin
    AppLogger.Debug('Pop Job �����쳣��' + AJob.ToString);
    Exit;
  end;

  //��������task��ִ��
  LTaskConfigRec := AJob.TaskConfigRec;
  LTaskConfigRec.RunBasePath := FRunBasePath;
  LTaskConfigRec.DBsConfigFile := DbsConfigFile;

  //����Task�����
  New(LTaskInitParams);
  LTaskInitParams^.DataType := sdtText;
  LTaskInitParams^.Data := FInParams;

  AJob.Task := TTask.Create(LTaskConfigRec);
  try
    AJob.HandleStatus := jhsRun;
    AJob.LastStartTime := Now;
    AJob.RunThread := nil;
    AJob.JobRequest := nil;
    AJob.Task.TaskVar.GlobalVar := FGlobalVar;
    AJob.Task.TaskVar.Logger.LogLevel := FLogLevel;
    AJob.Task.TaskVar.Logger.NoticeHandle := LogNoticeHandle;

    try
      AJob.Task.TaskVar.Logger.Force('����ʼ'+ AJob.JobName);
      AppLogger.Force('��ʼִ�й�����' + AJob.JobName);

      AJob.Task.Start(LTaskInitParams);

      //��Task��ȡִ�н��
      FOutResult.Code := AJob.Task.TaskVar.TaskResult.Code;
      FOutResult.Msg := AJob.Task.TaskVar.TaskResult.Msg;
      FOutResult.Data := AJob.Task.TaskVar.TaskResult.Data;

      AppLogger.Force('����ִ�й�����' + AJob.JobName);
      AJob.Task.TaskVar.Logger.Force('�������'+ AJob.JobName);
    except
      on E: Exception do
      begin
        FOutResult.Msg := 'ִ�й����쳣�˳���' + AJob.JobName + '��ԭ��' + E.Message;

        AJob.LastStartTime := 0;
        AppLogger.Fatal(FOutResult.Msg);
      end;
    end;
  finally
    //�ͷ����
    Dispose(LTaskInitParams);
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
      FOutResult.Msg := '����Project�ļ�ʧ�ܣ�' + AJobDispatcherRec.ProjectFile
                        + '; Job: ' + AJobDispatcherRec.JobName
                        + '; InParams: ' + AJobDispatcherRec.InParams;
      AppLogger.Fatal(FOutResult.Msg);
    end;
  finally
    if AJobDispatcherRec <> nil then
      Dispose(AJobDispatcherRec);
  end;
end;

end.
