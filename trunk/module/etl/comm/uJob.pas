unit uJob;

interface

uses System.Classes, uThreadQueueUtil, System.JSON, System.SysUtils, uTask, uStepDefines,
    System.SyncObjs, uFileLogger, uGlobalVar;

type
  PJobRequest = ^TJobRequest;

  TJobRequest = record
    JobName: string;
    TaskConfig: TTaskCongfigRec;
  end;

  TJobHandleStatus = (jhsNone, jhsWaited, jhsRun);

  TJobConfig = class
  private
    FTaskConfigRec: TTaskCongfigRec;
    function GetTaskStepsStr: string;
    function GetTaskConfigRec: TTaskCongfigRec;
    procedure FreeTask;
  public
    JobName: string;
    TaskFile: string;

    Interval: Integer;
    LastStartTime: TDateTime;
    AllowedTimes: TStringList;
    DisallowedTimes: TStringList;
    TimeOut: Integer;
    Status: Integer;

    HandleStatus: TJobHandleStatus;

    //�̲߳���ȫ����������Ϊ��ʱ�ļ�¼
    Task: TTask;
    RunThread: TThread;
    JobRequest: PJobRequest;

    property TaskConfigRec: TTaskCongfigRec read GetTaskConfigRec;
    property TaskStepsStr: string read GetTaskStepsStr;

    constructor Create;
    destructor Destroy; override;

    procedure ParseScheduleConfig(AScheduleJsonStr: string);
    function CheckSchedule: Boolean;
    function IsTimeOut: Boolean;
  end;


  //��������ʵ������ʱ������Ĵ���͹���
  TJobMgr = class
  private
    FRunBasePath: string;
    FJobs: TStringList;

    FGlobalVar: TGlobalVar;

    FThreadPool: TThreadPool;
    FThreadCount: Integer;

    FLogLevel: TLogLevel;

    FUnHandledCount: Integer;

    Critical: TCriticalSection;

    //���߳���ʵ�ʴ���task_request�ķ���
    procedure PopJobRequest(Data: Pointer; AThread: TThread);
    //���뵽�̳߳���ִ��
    procedure PushJobRequest(AJobRequest: TJobRequest);

    function GetJob(AJobName: string): TJobConfig;
    function CheckJobTask(AJob: TJobConfig): Boolean;
    function GetDbsConfigFile: string;

    procedure StartJob(AJob: TJobConfig); overload;
    procedure StopJob(AJob: TJobConfig); overload;

  public
    CallerHandle: THandle;
    constructor Create(AJobsFileName: string; AThreadCount: Integer = 1; const ALogLevel: TLogLevel = llAll);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;

    procedure StartJob(AJobName: string); overload;
    procedure StopJob(AJobName: string); overload;

    function LoadConfigFrom(AJobsFileName: string): Boolean;

    property DbsConfigFile: string read GetDbsConfigFile;
  end;


implementation

uses uDefines, uFunctions, uTaskVar, Winapi.Windows, uFileUtil, System.DateUtils, uThreadSafeFile;

{ TJobConfig }

constructor TJobConfig.Create;
begin
  inherited;
  AllowedTimes := TStringList.Create;
  DisallowedTimes := TStringList.Create;
end;


destructor TJobConfig.Destroy;
begin
  AllowedTimes.Free;
  DisallowedTimes.Free;
  inherited;
end;


function TJobConfig.GetTaskConfigRec: TTaskCongfigRec;
begin
  if FTaskConfigRec.TaskName = '' then
  begin
    FTaskConfigRec := TTaskUtil.ReadConfigFrom(TaskFile);
  end;
  Result := FTaskConfigRec;
end;


function TJobConfig.GetTaskStepsStr: string;
begin
  if FTaskConfigRec.TaskName = '' then
  begin
    FTaskConfigRec := TTaskUtil.ReadConfigFrom(TaskFile);
  end;

  Result := FTaskConfigRec.StepsStr;
end;



procedure TJobConfig.ParseScheduleConfig(AScheduleJsonStr: string);
var
  LScheduleJson: TJSONObject;
begin
  LScheduleJson := TJSONObject.ParseJSONValue(AScheduleJsonStr) as TJSONObject;
  LastStartTime := 0;
  if LScheduleJson = nil then
  begin
    Interval := 3600;
    TimeOut := 7200;
  end
  else
  begin
    try
      Interval := GetJsonObjectValue(LScheduleJson, 'interval', '3600', 'int');
      TimeOut := GetJsonObjectValue(LScheduleJson, 'time_out', '7200', 'int');
      AllowedTimes.NameValueSeparator := '-';
      AllowedTimes.Text := GetJsonObjectValue(LScheduleJson, 'allowed_time');
      DisallowedTimes.NameValueSeparator := '-';
      DisallowedTimes.Text := GetJsonObjectValue(LScheduleJson, 'disallowed_time');
    finally
      LScheduleJson.Free;
    end;
  end;
end;


function TJobConfig.CheckSchedule: Boolean;
var
  LNow: TDateTime;
  LNowStr: string;

  function IsAllowed: Boolean;
  var
    i: Integer;
  begin
    Result := False;
    if AllowedTimes.Count = 0 then
    begin
      Result := True;
      Exit;
    end;

    for i := 0 to AllowedTimes.Count - 1 do
    begin
      if (LNowStr >= AllowedTimes.Names[i])
        and (LNowStr <= AllowedTimes.ValueFromIndex[i]) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;

  function IsDisallowed: Boolean;
  var
    i: Integer;
  begin
    Result := False;
    if DisallowedTimes.Count = 0 then
    begin
      Exit;
    end;

    for i := 0 to DisallowedTimes.Count - 1 do
    begin
      if (LNowStr >= DisallowedTimes.Names[i])
        and (LNowStr <= DisallowedTimes.ValueFromIndex[i]) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
begin
  Result := True;
  if Status = 0 then
  begin
    Result := False;
    Exit;
  end;

  LNow := Now;
  if SecondsBetween(LNow, LastStartTime) < Interval then
  begin
    AppLogger.Debug(JobName + '��δ����ִ��ʱ��:' + FormatDateTime('yyyy-mm-dd hh:nn:ss', LastStartTime));
    Result := False;
    Exit;
  end;

  LNowStr := FormatDateTime('hh:nn:ss', LNow);
  if not IsAllowed then
  begin
    AppLogger.Debug(JobName + '���������ִ��ʱ��');
    Result := False;
    Exit;
  end;

  if IsDisallowed then
  begin
    AppLogger.Debug(JobName + 'ʱ��ν�ִֹ��');
    Result := False;
    Exit;
  end;
end;


function TJobConfig.IsTimeOut: Boolean;
begin
  Result := False;
  if TimeOut < 1  then Exit;

  if (LastStartTime = 0) or (Task = nil) then Exit; //δ���й���δ���У������м��

  if (SecondsBetween(Now, LastStartTime) >= TimeOut) and (Task <> nil) then
    Result := True;
end;


procedure TJobConfig.FreeTask;
begin
  if Task <> nil then
    FreeAndNil(Task);
  RunThread := nil;
  HandleStatus := jhsNone;
end;


{ TJobMgr }

constructor TJobMgr.Create(AJobsFileName: string; AThreadCount: Integer = 1; const ALogLevel: TLogLevel = llAll);
begin
  CallerHandle := 0;
  FLogLevel := ALogLevel;

  Critical := TCriticalSection.Create;
  FJobs := TStringList.Create;
  FUnHandledCount := 0;
  FThreadCount := AThreadCount;
  FThreadPool := TThreadPool.Create(PopJobRequest, FThreadCount);

  LoadConfigFrom(AJobsFileName);

  FGlobalVar := TGlobalVar.Create;
  FGlobalVar.LoadFromFile((FRunBasePath + 'project.global'));
end;

destructor TJobMgr.Destroy;
var
  i: Integer;
begin
  Stop;

  FThreadPool.Free;
 
  //ѭ�������ͷ�task�е�������
  for i := 0 to FJobs.Count - 1 do
  begin
    if FJobs.Objects[i] <> nil then
      TJobConfig(FJobs.Objects[i]).Free;
  end;
  FreeAndNil(FJobs);
  FreeAndNil(FGlobalVar);
  FreeAndNil(Critical);
  inherited;
end;

function TJobMgr.GetDbsConfigFile: string;
begin
  Result := FRunBasePath + 'project.dbs';
end;


function TJobMgr.GetJob(AJobName: string): TJobConfig;
var
  i: Integer;
begin
  Result := nil;
  i := FJobs.IndexOf(AJobName);
  if i > -1 then
  begin
    Result := TJobConfig(FJobs.Objects[i]);
  end;
end;


//���һ��load��ɣ��������ٴα�����ã���ˣ����鱾�����ڱ��ഴ��ʱ���д������������п��Ÿ��ⲿ
function TJobMgr.LoadConfigFrom(AJobsFileName: string): Boolean;
var
  LJobConfigs: TJSONArray;
  LJobConfigJson: TJSONObject;
  LJobConfig: TJobConfig;
  i: Integer;
begin
  Result := False;
  //���ֱ�ߵ��������У���Ҫ�����ͷ�ֹͣ�����Ը���״̬����������˵���ݴ����е��߳�����������
  if FUnHandledCount > 0 then
  begin
    AppLogger.Error('�����ļ�����ʧ�ܣ�����' + IntToStr(FUnHandledCount) + '����������ִ��');
    Exit;
  end;

  //��ʼ��FTasks
  if not FileExists(AJobsFileName) then Exit;

  LJobConfigs := TJSONObject.ParseJSONValue(TThreadSafeFile.ReadContentFrom(AJobsFileName, '[]')) as TJSONArray;

  FRunBasePath := ExtractFilePath(AJobsFileName);

  //���Tjobconfig
  for i := 0 to FJobs.Count - 1 do
  begin
    TJobConfig(FJobs.Objects[i]).Free;
  end;
  FJobs.Clear;

  if LJobConfigs = nil then Exit;
  try
    for i := 0 to LJobConfigs.Count - 1 do
    begin
      LJobConfigJson := LJobConfigs.Items[i] as TJSONObject;
      if LJobConfigJson <> nil then
      begin
        LJobConfig := TJobConfig.Create;
        LJobConfig.JobName := GetJsonObjectValue(LJobConfigJson, 'job_name', '');
        LJobConfig.TaskFile := TFileUtil.GetAbsolutePathEx(
                                      FRunBasePath,
                                      GetJsonObjectValue(LJobConfigJson, 'task_file', ''));
        LJobConfig.Status := StrToIntDef(GetJsonObjectValue(LJobConfigJson, 'status', '0'), 0);
        LJobConfig.ParseScheduleConfig(GetJsonObjectValue(LJobConfigJson, 'schedule'));
        LJobConfig.HandleStatus := jhsNone;

        FJobs.AddObject(LJobConfig.JobName, LJobConfig);
      end
      else
      begin
        AppLogger.Error('TJobMgr.LoadConfigFrom��������ʧ��');
      end;
    end;
    Result := True;
  finally
    LJobConfigs.Free;
  end;
end;


function TJobMgr.CheckJobTask(AJob: TJobConfig): Boolean;
begin
  Result := False;
  Critical.Enter;
  try
    if AJob = nil then
    begin
      AppLogger.Error('TJobMgr.FJobs��δƥ���������ã��߳��˳�');
    end
    else if AJob.Task <> nil then
    begin
      AppLogger.Error('TJobMgr�и���������ִ�У����ι���ִ���˳���' + AJob.JobName);
    end
    else
      Result := True;
  finally
    Critical.Leave;
  end;
end;


//��������̰߳�ȫ����Ϊ��������ɵ��߳�������ͬһ�δ��룬Ҫô���Ǿֲ�����
//Ҫô���̰߳�ȫ�ı���
procedure TJobMgr.PopJobRequest(Data: Pointer; AThread: TThread);
var
  LRequest: PJobRequest;
  LJob: TJobConfig;
begin
  //�ܿ�����Ҫ����critical��
  LRequest := Data;
  LJob := GetJob(LRequest.JobName);

  if not CheckJobTask(LJob) then
  begin
    if LJob.Task = nil then
    begin
      LJob.HandleStatus := jhsNone;
    end;
    Exit;
  end;

  //��������task��ִ��
  LJob.Task := TTask.Create(LRequest.TaskConfig);
  try
    LJob.HandleStatus := jhsRun;
    LJob.Task.TaskVar.GlobalVar := FGlobalVar;
    LJob.Task.TaskVar.Logger.LogLevel := FLogLevel;
    {$IFDEF PROJECT_DESIGN_MODE}
    LJob.Task.TaskVar.Logger.NoticeHandle := CallerHandle;
    {$ENDIF}
    try
      LJob.Task.TaskConfigRec := LRequest.TaskConfig;
      LJob.LastStartTime := Now;
      LJob.RunThread := AThread;
      LJob.JobRequest := Data;

      LJob.Task.TaskVar.Logger.Force('����ʼ'+ LRequest.JobName);
      AppLogger.Force('��ʼִ�й�����' + LRequest.JobName);
      LJob.Task.Start;
      AppLogger.Force('����ִ�й�����' + LRequest.JobName);
      LJob.Task.TaskVar.Logger.Force('�������'+ LRequest.JobName);
    except
      on E: Exception do
      begin
        LJob.LastStartTime := 0;
        AppLogger.Fatal('ִ�й����쳣�˳���' + LRequest.JobName + '��ԭ��' + E.Message);
      end;
    end;
  finally
    Dispose(LRequest);
    InterlockedDecrement(FUnHandledCount);
    LJob.FreeTask;
  end;
end;


procedure TJobMgr.PushJobRequest(AJobRequest: TJobRequest);
var
  LRequest: PJobRequest;
begin
  New(LRequest);
  LRequest^.JobName := AJobRequest.JobName;
  LRequest^.TaskConfig := AJobRequest.TaskConfig;
  FThreadPool.Add(LRequest);
  InterlockedIncrement(FUnHandledCount);
end;


procedure TJobMgr.Start;
var
  i: Integer;
  LJob: TJobConfig;
begin
  for i := 0 to FJobs.Count - 1 do
  begin
    LJob := TJobConfig(FJobs.Objects[i]);
    if LJob = nil then
    begin
      AppLogger.Error('TJobMgr.List��δ�ҵ���Ӧ��Job����');
      Continue;
    end;

    //����Ƿ�ʱ�������ʱ�أ��ȳ���stop��Ȼ��ȴ������stopʧ�ܣ�֤������Task�Ѿ��쳣��
    //���ʱ����Գ���ֱ��free�����task����Ȼ��������߳��ڲ����쳣
    //���������̱߳�����Ⱦ��������أ�����terminate��
    //���ڳ�ʱ�����񣬱�����ǰ���м�飬�Ӷ���ǰ��ֹ��������񣬱�����������
    if LJob.IsTimeOut then
    try
      LJob.LastStartTime := 0;
      StopJob(LJob);

      //�ͷ��ڴ�ռ�
//      Dispose(LJob.JobRequest);
//      InterlockedDecrement(FUnHandledCount);
//      LJob.FreeTask;
//      FThreadPool.EndThread(LJob.RunThread);

      AppLogger.Error('����ִ�г�ʱ��' + Ljob.JobName);
    except

    end;

    if not LJob.CheckSchedule then
    begin
      Continue;
    end;

    StartJob(LJob);
  end;
end;


//PushToJobRequest�ĵ��ñ���
procedure TJobMgr.StartJob(AJobName: string);
var
  LJob: TJobConfig;
begin
  LJob := GetJob(AJobName);
  if not CheckJobTask(LJob) then Exit;

  StartJob(LJob);
end;


procedure TJobMgr.StartJob(AJob: TJobConfig);
var
  LRequest: TJobRequest;
begin
  if not CheckJobTask(AJob) then Exit;
  if AJob.HandleStatus = jhsNone then
  begin


    LRequest.JobName := AJob.JobName;
    LRequest.TaskConfig := AJob.TaskConfigRec;
    LRequest.TaskConfig.RunBasePath := FRunBasePath;
    LRequest.TaskConfig.DBsConfigFile := DbsConfigFile;

    PushJobRequest(LRequest);
    AJob.HandleStatus := jhsWaited;
  end;
end;


procedure TJobMgr.Stop;
var
  i: Integer;
begin
  for i := 0 to FJobs.Count - 1 do
  begin
    StopJob(TJobConfig(FJobs.Objects[i]));
  end;
end;



procedure TJobMgr.StopJob(AJob: TJobConfig);
begin
  try
    //��Ϊtask���ͷźͱ������ǹ����ڲ�ͬ���߳��У��п��������߳���task�Ѿ��ͷ�
    //�����߳���Ȼ�ڲ���
    if (AJob <> nil) and (AJob.Task <> nil) then
    begin
      AJob.Task.TaskVar.TaskStatus := trsStop;
    end;
  finally

  end;
end;


procedure TJobMgr.StopJob(AJobName: string);
var
  LJob: TJobConfig;
begin
  LJob := GetJob(AJobName);
  StopJob(LJob);
end;

end.
