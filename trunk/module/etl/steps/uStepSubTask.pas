unit uStepSubTask;

interface

uses
  uStepBasic, System.JSON;

type
  TStepSubTask = class (TStepBasic)
  private
    FSubTaskFile: string;
    FSubTaskRealAbsFile: string;
  protected
    procedure StartSelf; override;
    procedure StartSelfDesign; override;
  public
    procedure ParseStepConfig(AConfigJsonStr: string); override;
    procedure MakeStepConfigJson(var AToConfig: TJSONObject); override;

    property SubTaskFile: string read FSubTaskFile write FSubTaskFile;
  end;

implementation

uses
  uDefines, uFunctions, System.Classes, System.SysUtils, uExceptions, uTask, uStepDefines,
  uTaskVar, uTaskDefine;

{ TStepQuery }

procedure TStepSubTask.MakeStepConfigJson(var AToConfig: TJSONObject);
begin
  inherited MakeStepConfigJson(AToConfig);
  AToConfig.AddPair(TJSONPair.Create('sub_task_file', FSubTaskFile));
end;


procedure TStepSubTask.ParseStepConfig(AConfigJsonStr: string);
begin
  inherited ParseStepConfig(AConfigJsonStr);
  FSubTaskFile := GetJsonObjectValue(StepConfig.ConfigJson, 'sub_task_file');
  FSubTaskRealAbsFile := GetRealAbsolutePath(FSubTaskFile);
end;


procedure TStepSubTask.StartSelfDesign;
var
  LStepConfigJson: TJSONObject;
  LTaskConfigRec: TTaskCongfigRec;
  LTaskBlock: TTaskBlock;
  LTaskStep: TTaskStep;
begin
  if not FileExists(FSubTaskRealAbsFile) then
  begin
    Exit;
  end;

  LTaskStep.OwnerBlock := TaskBlock;
  LTaskStep.Id := StepConfig.StepId;
  if TaskVar.IsToStep(LTaskStep) then Exit;

  TaskVar.Logger.Debug(FormatLogMsg('ִ���ļ�������' + FSubTaskFile));

  LTaskConfigRec := TTaskUtil.ReadConfigFrom(FSubTaskRealAbsFile);

  LStepConfigJson := TJSONObject.ParseJSONValue(LTaskConfigRec.StepsStr) as TJSONObject;
  try
    LTaskBlock.BlockName := TaskBlock.BlockName + '/' + StepConfig.StepTitle;
    LTaskBlock._ENTRY_FILE := TaskBlock._ENTRY_FILE;
    TaskVar.StartStep(LTaskBlock, LStepConfigJson, @FInData);
  finally
    if LStepConfigJson <> nil then
      LStepConfigJson.Free;
  end;
end;

procedure TStepSubTask.StartSelf;
var
  LStepConfigJson: TJSONObject;
  LTaskConfigRec: TTaskCongfigRec;
  LTaskBlock: TTaskBlock;
begin
  try
    CheckTaskStatus;

    //���������ļ�
    if not FileExists(FSubTaskRealAbsFile) then
    begin
      StopExceptionRaise('�������ļ������ڣ�' + FSubTaskRealAbsFile);
    end;

    TaskVar.Logger.Debug(FormatLogMsg('ִ���ļ�������' + FSubTaskFile));

    LTaskConfigRec := TTaskUtil.ReadConfigFrom(FSubTaskRealAbsFile);

    LStepConfigJson := TJSONObject.ParseJSONValue(LTaskConfigRec.StepsStr) as TJSONObject;
    try
      LTaskBlock.BlockName := TaskBlock.BlockName + '/' + StepConfig.StepTitle;
      LTaskBlock._ENTRY_FILE := TaskBlock._ENTRY_FILE;
      TaskVar.StartStep(LTaskBlock, LStepConfigJson, @FInData);
    finally
      if LStepConfigJson <> nil then
        LStepConfigJson.Free;
    end;
  finally

  end;
end;


initialization
RegisterClass(TStepSubTask);

finalization
UnRegisterClass(TStepSubTask);

end.
