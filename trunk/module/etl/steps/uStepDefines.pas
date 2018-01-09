unit uStepDefines;

interface

uses System.JSON, System.SysUtils;

type
  TTaskRunStatus = (trsUnknown, trsRunning, trsStop, trsSuspend);

  TTaskCongfigRec = record
    FileName: string;
    TaskName: string;
    Description: string;
    Version: string;
    Auth: string;

    StepsStr: string;

    //������������jobmgr����ʱ����
    RunBasePath: string;
    DBsConfigFile: string;
  end;

  //Step�����ݵļ������ͣ�ʵ����Ŀǰ����֧���ı��ͣ���ʱ������������
  TStepDataType = (sdtText);

  PStepData = ^TStepData;

  //���ڱ�����Step����Ҫ��������ݵ�����
  TStepData = record
    DataType: TStepDataType;
    Data: string;
  end;


  TStepParamValue = string;

  //Step������
  TStepType = string;

  //��������һ��Step�Ķ���
  TStepDefine = record
    StepTypeId: Integer;
    StepType: TStepType;
    StepTypeName: string;
    StepClassName: string;
    FormClassName: string;
  end;


  //��һ��ʵ��Step���õ�����
  TStepConfig = class
  private
    FConfigJson: TJSONObject;
    FConfigJsonStr: string;
    function GetConfigJson: TJSONObject;
    function GetConfigJsonStr: string;
    procedure SetConfigJsonStr(const Value: string);
  public
    StepId: Integer;
    StepType: TStepType;
    StepTitle: string;
    Description: string;
    RegDataToTask: Boolean;
    StepStatus: Integer;

    property ConfigJsonStr: string read GetConfigJsonStr write SetConfigJsonStr;
    property ConfigJson: TJSONObject read GetConfigJson;

    destructor Destroy; override;
  end;


implementation

uses uFunctions;

{ TStepConfig }

destructor TStepConfig.Destroy;
begin
  if FConfigJson <> nil then
    FConfigJson.Free;
  inherited;
end;

function TStepConfig.GetConfigJson: TJSONObject;
begin
  if FConfigJson = nil then
    FConfigJson := TJSONObject.ParseJSONValue(FConfigJsonStr) as TJSONObject;
  Result := FConfigJson;
end;

function TStepConfig.GetConfigJsonStr: string;
begin
  Result := FConfigJsonStr;
end;

procedure TStepConfig.SetConfigJsonStr(const Value: string);
begin
  if FConfigJsonStr <> Value then
  begin
    if FConfigJson <> nil then
      FConfigJson.Free;
    FConfigJsonStr := Value;
  end;
end;

end.
