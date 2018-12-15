unit donix.steps.uStepServiceCtrl;

interface

uses
  uStepBasic, System.JSON;

type
  TStepServiceCtrl = class (TStepBasic)
  private
    FServiceName: string;
    FCtrlType: Integer;
    FServiceExeFile: string;
    FDisplayName: string;
    function CheckStatus(AStartTime: TDateTime; AToStatus: string): Boolean;
  protected
    procedure StartSelf; override;
  public
    procedure ParseStepConfig(AConfigJsonStr: string); override;
    procedure MakeStepConfigJson(var AToConfig: TJSONObject); override;

    property ServiceName: string read FServiceName write FServiceName;
    property CtrlType: Integer read FCtrlType write FCtrlType;
    property ServiceExeFile: string read FServiceExeFile write FServiceExeFile;
    property DisplayName: string read FDisplayName write FDisplayName;
  end;

implementation

uses
  uDefines, uFunctions, System.Classes, System.SysUtils, uExceptions, uStepDefines, uServiceUtil, System.DateUtils;

type
  TServiceCtrlType = (sctInstall, sctStart, sctStop, sctUninstall);

{ TStepQuery }

procedure TStepServiceCtrl.MakeStepConfigJson(var AToConfig: TJSONObject);
begin
  inherited MakeStepConfigJson(AToConfig);
  AToConfig.AddPair(TJSONPair.Create('service_name', FServiceName));
  AToConfig.AddPair(TJSONPair.Create('ctrl_type', IntToStr(FCtrlType)));
  AToConfig.AddPair(TJSONPair.Create('service_exe_file', FServiceExeFile));
  AToConfig.AddPair(TJSONPair.Create('display_name', FDisplayName));
end;


procedure TStepServiceCtrl.ParseStepConfig(AConfigJsonStr: string);
begin
  inherited ParseStepConfig(AConfigJsonStr);
  FServiceName := GetJsonObjectValue(StepConfig.ConfigJson, 'service_name');
  FCtrlType := GetJsonObjectValue(StepConfig.ConfigJson, 'ctrl_type', '-1', 'int');
  FServiceExeFile := GetJsonObjectValue(StepConfig.ConfigJson, 'service_exe_file');
  FDisplayName := GetJsonObjectValue(StepConfig.ConfigJson, 'display_name');
end;


procedure TStepServiceCtrl.StartSelf;
var
  LAbsServcieExeFile: string;
  LCtrlType: TServiceCtrlType;
  LResult: Boolean;
  LServiceStatusStr: string;
begin
  try
    CheckTaskStatus;

    LCtrlType := TServiceCtrlType(FCtrlType);
    LResult := True;

    //��ѯ����״̬
    LServiceStatusStr := TServiceUtil.QueryServiceStatusStr(FServiceName);
    case LCtrlType of
      sctInstall:
      begin
        if LServiceStatusStr = 'δ��װ' then
        begin
          LAbsServcieExeFile := GetRealAbsolutePath(FServiceExeFile);
          LResult := TServiceUtil.InstallServices(FServiceName, FDisplayName, LAbsServcieExeFile);

          //ִ���쳣���
          LResult := CheckStatus(Now, '��ֹͣ');
        end;
      end;
      sctStart:
      begin
        if LServiceStatusStr = '��ֹͣ' then
        begin
          LResult := TServiceUtil.StartServices(FServiceName);

          //ִ���쳣���
          LResult := CheckStatus(Now, '������');
        end;
      end;
      sctStop:
      begin
        if LServiceStatusStr = '������' then
        begin
          TServiceUtil.StopServices(FServiceName);
          //Ҫִ�еȴ���飬������Ҫ��¼�쳣
          LResult := CheckStatus(Now, '��ֹͣ');
        end;
      end;
      sctUninstall:
      begin
        if LServiceStatusStr = '��ֹͣ' then
        begin
          TServiceUtil.UnInstallServices(FServiceName);

          //Ҫִ�м�飬������Ҫ��¼�쳣
          LResult := CheckStatus(Now, 'δ��װ');
        end;
      end;
    end;

    if not LResult then
    begin
      StopExceptionRaise('��������ִ��ʧ��');
    end;
  finally

  end;
end;


function TStepServiceCtrl.CheckStatus(AStartTime: TDateTime; AToStatus: string): Boolean;
var
  LServerStatusStr: string;
begin
  while SecondsBetween(Now, AStartTime) < 120 do
  begin
    Sleep(1000);
    LServerStatusStr := TServiceUtil.QueryServiceStatusStr(FServiceName);
    if LServerStatusStr = AToStatus then
    begin
      Break;
    end;
  end;

  Result := LServerStatusStr = AToStatus;
end;

end.
