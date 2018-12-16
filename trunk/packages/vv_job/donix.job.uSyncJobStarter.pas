unit donix.job.uSyncJobStarter;

interface

uses uJobStarter, uJob, uFileLogger, System.Classes, uStepDefines, System.Contnrs, System.SyncObjs;



type
  PJobStarterRec = ^TJobStarterRec;

  TJobStarterRec = record
    ProjectFile: string;
    JobName: string;
    InParams: string;

    LogLevel: TLogLevel;
    LogNoticeHandle: THandle;
  end;

  TOutResult = record
    Code: Integer;
    Msg: string;
    Data: string;
  end;


  //��֧�ֵ��߳�ģʽ��֧�ֶԽ���������֧����Σ�������ʵ��֧������һ������
  TSyncJobStarter = class(TJobStarter)
  private
    FInParams: string;
    FOutResult: TOutResult;

    procedure StartJobWithResult(AJobName: string);

  protected
    function GetTaskInitParams: PStepData; override;
  public
    constructor Create(const ALogLevel: TLogLevel = llAll); overload;

    procedure StartProjectJob(const AJobStarterRec: PJobStarterRec; const AWithResult: Boolean = True);

    property OutResult: TOutResult read FOutResult;
  end;

  TSyncJobStarterList = class
  private
    FCritical: TCriticalSection;
    FList: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;
    function NewStarter: TSyncJobStarter;
    procedure FreeStarter(AStarter: TSyncJobStarter);
    procedure Clear;
  end;

implementation

uses
  uTaskDefine, uDefines, uTask, System.SysUtils, Winapi.Windows;

{ TJobDispatcher }

constructor TSyncJobStarter.Create(const ALogLevel: TLogLevel = llAll);
begin
  inherited Create(0, ALogLevel);
  FOutResult.Code := -1;
  FOutResult.Msg := '����ʧ��';
end;


function TSyncJobStarter.GetTaskInitParams: PStepData;
begin
  FCritical.Enter;
  try
    New(Result);
    Result^.DataType := sdtText;
    Result^.Data := FInParams;
  finally
    FCritical.Leave;
  end;
end;


procedure TSyncJobStarter.StartJobWithResult(AJobName: string);
var
  LTaskConfigRec: TTaskConfigRec;
  LJob: TJobConfig;
begin
  LJob := GetJob(AJobName);
  if not CheckJobTask(LJob) then
  begin
    AppLogger.Debug('Pop Job �����쳣');
    Exit;
  end;

  TInterlocked.Increment(FUnHandledCount);

  //��������task��ִ��
  LTaskConfigRec := LJob.TaskConfigRec;
  LTaskConfigRec.RunBasePath := FRunBasePath;
  LTaskConfigRec.DBsConfigFile := DbsConfigFile;

  LJob.Task := TTask.Create(LTaskConfigRec, AJobName);
  try
    LJob.HandleStatus := jhsRun;
    LJob.LastStartTime := Now;
    LJob.RunThread := nil;
    LJob.JobRequest := nil;
    LJob.Task.TaskVar.Interactive := 0;     //ǿ�Ʋ��ܽ��н�������ĵ���
    LJob.Task.TaskVar.GlobalVar := FGlobalVar;
    LJob.Task.TaskVar.Logger.LogLevel := FLogLevel;
    LJob.Task.TaskVar.Logger.NoticeHandle := LogNoticeHandle;

    try
      AppLogger.Force('[' + AJobName + ']��ʼִ��');

      LJob.Task.TaskVar.Logger.Force('[' + AJobName + ']����ʼ');
      LJob.Task.Start(GetTaskInitParams);

      //��Task��ȡִ�н��
      LJob := GetJob(AJobName);
      if LJob = nil then
      begin
        AppLogger.Error('[' + AJobName + ']Dispatcher Job In Start�˳�');
      end
      else if LJob.Task <> nil then
      begin
        FOutResult.Code := LJob.Task.TaskVar.TaskResult.Code;
        FOutResult.Msg := LJob.Task.TaskVar.TaskResult.Msg;
        FOutResult.Data := LJob.Task.TaskVar.TaskResult.DataStr;
        LJob.Task.TaskVar.Logger.Force('[' + AJobName + ']�������');
      end;

      AppLogger.Force('[' + AJobName + ']����ִ��');
    except
      on E: Exception do
      begin
        FOutResult.Msg := '[' + AJobName + ']ִ�й����쳣�˳���ԭ��' + E.Message;
        AppLogger.Fatal(FOutResult.Msg);
      end;
    end;
  finally
    TInterlocked.Decrement(FUnHandledCount);
    LJob := GetJob(AJobName);
    if LJob <> nil then
      LJob.FreeTask;
  end;
end;



procedure TSyncJobStarter.StartProjectJob(const AJobStarterRec: PJobStarterRec; const AWithResult: Boolean = True);
begin
  //����������ͷ�
  try
    if LoadConfigFrom(AJobStarterRec.ProjectFile, AJobStarterRec.JobName) then
    begin
      FInParams := AJobStarterRec.InParams;
      FLogLevel := AJobStarterRec.LogLevel;
      LogNoticeHandle := AJobStarterRec.LogNoticeHandle;

      //TODO ���������blockui���Ե����ã�����Ԥ����ƺõ����ԣ��߲�ͬ�ĵ��÷���

      if AWithResult then
      begin
        StartJobWithResult(AJobStarterRec.JobName);
      end
      else
        StartJob(AJobStarterRec.JobName);
    end
    else
    begin
      FOutResult.Msg := 'LoadJobConfig�����ļ�δ�ɹ�';
      AppLogger.Fatal(FOutResult.Msg);
    end;
  finally
    if AJobStarterRec <> nil then
      Dispose(AJobStarterRec);
  end;
end;

{ TJobDispatcherList }

constructor TSyncJobStarterList.Create;
begin
  inherited;
  FCritical := TCriticalSection.Create;
  FList := TObjectList.Create(False);
end;


function TSyncJobStarterList.NewStarter: TSyncJobStarter;
begin
  FCritical.Enter;
  try
    Result := TSyncJobStarter.Create;
    if Result <> nil then
    FList.Add(Result);
  finally
    FCritical.Leave;
  end;
end;


procedure TSyncJobStarterList.FreeStarter(AStarter: TSyncJobStarter);
var
  idx: Integer;
begin
  FCritical.Enter;
  try
    if AStarter = nil then Exit;

    idx := FList.IndexOf(AStarter);
    FList.Delete(idx);

    if AStarter <> nil then
    begin
//      ADispatcher.ClearNotificationForms;
//      ADispatcher.ClearTaskStacks;
//
//      Sleep(200);

      AStarter.Free;
    end;
  finally
    FCritical.Leave;
  end;
end;


procedure TSyncJobStarterList.Clear;
var
  i: Integer;
begin
  for i := FList.Count - 1 downto 0 do
  begin
    if FList.Items[i] is TSyncJobStarter then
      FreeStarter(TSyncJobStarter(FList.Items[i]));
  end;
end;


destructor TSyncJobStarterList.Destroy;
begin
  Clear;
  FList.Free;
  FCritical.Free;
  inherited;
end;

end.
