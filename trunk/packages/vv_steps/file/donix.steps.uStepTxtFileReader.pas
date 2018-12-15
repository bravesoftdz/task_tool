unit donix.steps.uStepTxtFileReader;

interface

uses
  uStepBasic, System.JSON;

type
  TStepTxtFileReader = class (TStepBasic)
  private
    FFileName: string;
    FRealAbsFileName: string;
    //FFromField: string; //Ĭ����
  protected
    procedure StartSelf; override;
  public
    procedure ParseStepConfig(AConfigJsonStr: string); override;
    procedure MakeStepConfigJson(var AToConfig: TJSONObject); override;

    property ToFileName: string read FFileName write FFileName;
  end;

implementation

uses
  uDefines, uFunctions, System.Classes, System.SysUtils, uExceptions, uStepDefines, uThreadSafeFile;

{ TStepQuery }

procedure TStepTxtFileReader.MakeStepConfigJson(var AToConfig: TJSONObject);
begin
  inherited MakeStepConfigJson(AToConfig);
  AToConfig.AddPair(TJSONPair.Create('file_name', FFileName));
end;


procedure TStepTxtFileReader.ParseStepConfig(AConfigJsonStr: string);
begin
  inherited ParseStepConfig(AConfigJsonStr);
  FFileName := GetJsonObjectValue(StepConfig.ConfigJson, 'file_name');
  FRealAbsFileName := GetRealAbsolutePath(FFileName);
end;


procedure TStepTxtFileReader.StartSelf;
begin
  try
    CheckTaskStatus;

    if FRealAbsFileName = '' then
    begin
      StopExceptionRaise('Ŀ���ļ���Ϊ��');
    end;
    if not FileExists(FRealAbsFileName) then
    begin
      StopExceptionRaise('�ļ������ڣ�' + FRealAbsFileName);
    end;

    FOutData.Data := TThreadSafeFile.ReadContentFrom(FRealAbsFileName);

  finally

  end;
end;


end.
