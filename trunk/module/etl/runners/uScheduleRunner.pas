unit uScheduleRunner;

interface

uses System.Classes, uScheduleConfig, uFileLogger;

type
  TScheduleRunner = class(TThread)
  private
    FJobsFile: string;
    FJobThreadCount: Integer;
    FAllowedTimes: string;
    FDisAllowedTimes: string;
    FLogLevel: TLogLevel;
  public
    constructor Create(AExePath: string; AConfig: TScheduleConfig);
    procedure Execute; override;
  end;

implementation

uses uJobStarter, uDefines, System.SysUtils, uFileUtil;

{ TJobRunner }

constructor TScheduleRunner.Create(AExePath: string; AConfig: TScheduleConfig);
begin
  FJobsFile := TFileUtil.GetAbsolutePathEx(AExePath, AConfig.JobsFile);
  FJobThreadCount := AConfig.ThreadCount;
  FAllowedTimes := AConfig.AllowedTimes;
  FDisAllowedTimes := AConfig.DisAllowedTimes;
  FLogLevel := AConfig.LogLevel;

  FreeOnTerminate := False;

  inherited Create(True);
end;


procedure TScheduleRunner.Execute;
var
  LJobStarter: TJobStarter;
  LAllowedTimes: TStringList;
  LDisAllowedTimes: TStringList;
  LNowStr: string;
  LRec: Integer;

  function IsAllowed: Boolean;
  var
    i: Integer;
  begin
    Result := False;
    if LAllowedTimes.Count = 0 then
    begin
      Result := True;
      Exit;
    end;

    for i := 0 to LAllowedTimes.Count - 1 do
    begin
      if (LNowStr >= LAllowedTimes.Names[i])
        and (LNowStr <= LAllowedTimes.ValueFromIndex[i]) then
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
    if LDisallowedTimes.Count = 0 then
    begin
      Exit;
    end;

    for i := 0 to LDisallowedTimes.Count - 1 do
    begin
      if (LNowStr >= LDisallowedTimes.Names[i])
        and (LNowStr <= LDisallowedTimes.ValueFromIndex[i]) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;


begin
  inherited;
  AppLogger.Force('启动Runner：Jobs:' + FJobsFile + '；HandlerCount:' + IntToStr(FJobThreadCount));

  LAllowedTimes := TStringList.Create;
  LAllowedTimes.DelimitedText := FAllowedTimes;
  LAllowedTimes.NameValueSeparator := '-';
  LDisAllowedTimes := TStringList.Create;
  LDisAllowedTimes.DelimitedText := FDisAllowedTimes;
  LDisAllowedTimes.NameValueSeparator := '-';

  LJobStarter := TJobStarter.Create(FJobThreadCount, FLogLevel);
  LJobStarter.LoadConfigFrom(FJobsFile);
  try
    LRec := 0;
    while not Terminated do
    begin
      //每分钟记录一次日志
      LRec := LRec + 1;
      if LRec = 300 then
      begin
        AppLogger.Force('Runner运行');
        LRec := 0;
      end;

      //时间白名单黑名单过滤
      LNowStr := FormatDateTime('hh:nn:ss', Now);
      if IsAllowed and (not IsDisallowed) then
      begin
        LJobStarter.Start;
      end;

      //每秒执行一次
      Sleep(1000);
    end;
  finally
    LDisAllowedTimes.Free;
    LAllowedTimes.Free;
    LJobStarter.Free;
  end;
end;

end.
