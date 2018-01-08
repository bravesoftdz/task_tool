unit uStepFastReport;

interface

uses
  uStepBasic, System.JSON, Datasnap.DBClient, Data.DB, frxClass, frxBarcode, frxDBSet, frxRich;

type
  TStepFastReport = class (TStepBasic)
  private
    FReport: TfrxReport;
    //
    FDBDataSetsConfigStr: string;
    FDBVariablesConfigStr: string;
    FPreview: Boolean;
    FPrinterName: string;
    FReportFile: string;

  protected
    procedure StartSelf; override;

  public
    destructor Destroy; override;

    procedure ParseStepConfig(AConfigJsonStr: string); override;
    procedure MakeStepConfigJson(var AToConfig: TJSONObject); override;

    property DBDataSetsConfigStr: string read FDBDataSetsConfigStr write FDBDataSetsConfigStr;
    property DBVariablesConfigStr: string read FDBVariablesConfigStr write FDBVariablesConfigStr;
    property Preview: Boolean read FPreview write FPreview;
    property PrinterName: string read FPrinterName write FPrinterName;
    property ReportFile: string read FReportFile write FReportFile;
  end;

implementation

uses
  uDefines, uFunctions, System.Classes, System.SysUtils, uExceptions, uStepDefines;

{ TStepQuery }

destructor TStepFastReport.Destroy;
begin
  if FReport <> nil then
    FreeAndNil(FReport);
  inherited;
end;

procedure TStepFastReport.MakeStepConfigJson(var AToConfig: TJSONObject);
begin
  inherited MakeStepConfigJson(AToConfig);
  AToConfig.AddPair(TJSONPair.Create('datasets', FDBDataSetsConfigStr));
  AToConfig.AddPair(TJSONPair.Create('variables', FDBVariablesConfigStr));
  AToConfig.AddPair(TJSONPair.Create('preview', BoolToStr(FPreview)));
  AToConfig.AddPair(TJSONPair.Create('printer_name', FPrinterName));
  AToConfig.AddPair(TJSONPair.Create('report_file', FReportFile));
end;


procedure TStepFastReport.ParseStepConfig(AConfigJsonStr: string);
begin
  inherited ParseStepConfig(AConfigJsonStr);
  FDBDataSetsConfigStr := GetJsonObjectValue(StepConfig.ConfigJson, 'datasets');
  FDBVariablesConfigStr := GetJsonObjectValue(StepConfig.ConfigJson, 'variables');
  FPreview := StrToBoolDef(GetJsonObjectValue(StepConfig.ConfigJson, 'preview'), False);
  FPrinterName := GetJsonObjectValue(StepConfig.ConfigJson, 'printer_name');
  FReportFile := GetJsonObjectValue(StepConfig.ConfigJson, 'report_file');
end;


procedure TStepFastReport.StartSelf;
begin
  try
    CheckTaskStatus;

    FReport := TfrxReport.Create(nil);
    //����datasets
    //FReport.DataSets.Add();

    //�������ظ���variables

    //����Report_file

    //����Ԥ�����д�ӡ�����������service������²����ṩԤ�����ܣ�ֻ��ֱ�������ָ�����ļ���

  finally

  end;
end;

end.

