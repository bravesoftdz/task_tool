unit uJobMgr;

interface

uses
  uJob, System.SysUtils, System.SyncObjs, uThreadQueueUtil, System.Classes, uFileLogger, uGlobalVar;

type
  //��������ʵ������ʱ������Ĵ���͹���
  TJobMgr = class
  private
    FJobs: TStringList;


    FThreadPool: TThreadPool;
    FThreadCount: Integer;



    FUnHandledCount: Integer;

    Critical: TCriticalSection;

    //���߳���ʵ�ʴ���task_request�ķ���
    procedure HandleJobRequest(Data: Pointer; AThread: TThread);

    function GetJob(AJobName: string): TJobConfig;
    function GetDbsConfigFile: string;

  protected
    FLogLevel: TLogLevel;
    FRunBasePath: string;
    FGlobalVar: TGlobalVar;

    procedure StartJob(AJob: TJobConfig); overload; virtual;
    procedure StopJob(AJob: TJobConfig); overload;
    function CheckJobTask(AJob: TJobConfig): Boolean;
  public
    CallerHandle: THandle;
    constructor Create(AThreadCount: Integer = 1; const ALogLevel: TLogLevel = llAll);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;

    procedure StartJob(AJobName: string); overload;
    procedure StopJob(AJobName: string); overload;

    function LoadConfigFrom(AJobsFileName: string; AJobName: string = ''): Boolean;

    property DbsConfigFile: string read GetDbsConfigFile;
  end;

implementation

uses System.JSON, uThreadSafeFile, uFunctions, uDefines, uFileUtil, uTask, uTaskDefine, Winapi.Windows;

{ TJobMgr }

constructor TJobMgr.Create(AThreadCount: Integer = 1; const ALogLevel: TLogLevel = llAll);
begin
  CallerHandle := 0;
  FLogLevel := ALogLevel;

  Critical := TCriticalSection.Create;
  FJobs := TStringList.Create;
  FUnHandledCount := 0;
  FThreadCount := AThreadCount;
  if FThreadCount > 0 then
    FThreadPool := TThreadPool.Create(HandleJobRequest, FThreadCount);
end;


destructor TJobMgr.Destroy;
var
  i: Integer;
begin
  Stop;

  if FThreadPool <> nil then
    FreeAndNil(FThreadPool);

  //ѭ�������ͷ�task�е�������
  for i := 0 to FJobs.Count - 1 do
  begin
    if FJobs.Objects[i] <> nil then
      TJobConfig(FJobs.Objects[i]).Free;
  end;
  FreeAndNil(FJobs);

  if FGlobalVar <> nil then
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
function TJobMgr.LoadConfigFrom(AJobsFileName: string; AJobName: string = ''): Boolean;
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

  if FGlobalVar <> nil then
    FreeAndNil(FGlobalVar);
  FGlobalVar := TGlobalVar.Create;
  FGlobalVar.LoadFromFile((FRunBasePath + 'project.global'));

  if LJobConfigs = nil then Exit;
  try
    for i := 0 to LJobConfigs.Count - 1 do
    begin
      LJobConfigJson := LJobConfigs.Items[i] as TJSONObject;
      if LJobConfigJson <> nil then
      begin
        if (AJobName = '') or (AJobName = GetJsonObjectValue(LJobConfigJson, 'job_name', '')) then
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
        end;
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
      AppLogger.Error('TJobMgr�и���������ִ�У����ι���ִ���˳���' + AJob.ToString);
    end
    else
      Result := True;
  finally
    Critical.Leave;
  end;
end;


//��������̰߳�ȫ����Ϊ��������ɵ��߳�������ͬһ�δ��룬Ҫô���Ǿֲ�����
//Ҫô���̰߳�ȫ�ı���
procedure TJobMgr.HandleJobRequest(Data: Pointer; AThread: TThread);
var
  LRequest: PJobRequest;
  LJob: TJobConfig;
begin
  //�ܿ�����Ҫ����critical��
  LRequest := Data;
  LJob := GetJob(LRequest.JobName);

  if not CheckJobTask(LJob) then
  begin
    AppLogger.Debug('Pop Job �����쳣��' + LRequest.JobName);
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

    AppLogger.Debug('[' + IntToStr(i) + ']��' + LJob.ToString);

    //����Ƿ�ʱ�������ʱ�أ��ȳ���stop��Ȼ��ȴ������stopʧ�ܣ�֤������Task�Ѿ��쳣��
    //���ʱ����Գ���ֱ��free�����task����Ȼ��������߳��ڲ����쳣
    //���������̱߳�����Ⱦ��������أ�����terminate��
    //���ڳ�ʱ�����񣬱�����ǰ���м�飬�Ӷ���ǰ��ֹ��������񣬱�����������
    if LJob.IsTimeOut then
    try
      //������Ҫ���������Ǽ���ִ���У������Ѿ���ȫ����û����Ӧ��״̬
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
  StartJob(LJob);
end;


procedure TJobMgr.StartJob(AJob: TJobConfig);
var
  LRequest: PJobRequest;
begin
  if not CheckJobTask(AJob) then Exit;
  if AJob.HandleStatus = jhsNone then
  begin
    AJob.HandleStatus := jhsWaited;
    InterlockedIncrement(FUnHandledCount);
    New(LRequest);
    LRequest^.JobName := AJob.JobName;
    LRequest^.TaskConfig := AJob.TaskConfigRec;
    LRequest^.TaskConfig.RunBasePath := FRunBasePath;
    LRequest^.TaskConfig.DBsConfigFile := DbsConfigFile;

    if FThreadPool <> nil then
    begin
      FThreadPool.Add(LRequest);
    end
    else
      HandleJobRequest(LRequest, nil);
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
