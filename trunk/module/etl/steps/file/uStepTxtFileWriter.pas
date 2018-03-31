unit uStepTxtFileWriter;

interface

uses
  uStepBasic, System.JSON;

type
  TStepTxtFileWriter = class (TStepBasic)
  private
    FFileName: string;
    FRealAbsFileName: string;
    //FFromField: string; //Ĭ����
    FRewriteExist: Boolean;
  protected
    procedure StartSelf; override;
  public
    procedure ParseStepConfig(AConfigJsonStr: string); override;
    procedure MakeStepConfigJson(var AToConfig: TJSONObject); override;

    property ToFileName: string read FFileName write FFileName;
    property RewriteExist: Boolean read FRewriteExist write FRewriteExist;
  end;

implementation

uses
  uDefines, uFunctions, System.Classes, System.SysUtils, uExceptions, uStepDefines;

{ TStepQuery }

procedure TStepTxtFileWriter.MakeStepConfigJson(var AToConfig: TJSONObject);
begin
  inherited MakeStepConfigJson(AToConfig);
  AToConfig.AddPair(TJSONPair.Create('to_file_name', FFileName));
  AToConfig.AddPair(TJSONPair.Create('rewrite_exist', BoolToStr(FRewriteExist)));
end;


procedure TStepTxtFileWriter.ParseStepConfig(AConfigJsonStr: string);
begin
  inherited ParseStepConfig(AConfigJsonStr);
  FFileName := GetJsonObjectValue(StepConfig.ConfigJson, 'to_file_name');
  FRealAbsFileName := GetRealAbsolutePath(FFileName);
  FRewriteExist := StrToBoolDef(GetJsonObjectValue(StepConfig.ConfigJson, 'rewrite_exist'), False);
end;


procedure TStepTxtFileWriter.StartSelf;
var
  F: TextFile;
  LDir: string;
begin
  try
    CheckTaskStatus;

    if FRealAbsFileName = '' then
    begin
      StopExceptionRaise('Ŀ���ļ���Ϊ��');
    end;
    
    LDir := ExtractFileDir(FRealAbsFileName);
    if not DirectoryExists(LDir) then
    begin
      if not ForceDirectories(LDir) then
      begin
        Exit;
      end;
    end;

    AssignFile(F, FRealAbsFileName);

    TaskVar.Logger.Debug(FormatLogMsg('д���ļ���' + FRealAbsFileName));

    if (not FileExists(FRealAbsFileName)) or (FRewriteExist) then
      Rewrite(F)
    else
      Append(F);

    Writeln(F, FInData.Data);

    CloseFile(F);

  finally

  end;
end;


initialization
RegisterClass(TStepTxtFileWriter);

finalization
UnRegisterClass(TStepTxtFileWriter);

end.