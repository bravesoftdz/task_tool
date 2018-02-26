program CgtEtlOnce;

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  uStepBasic in '..\etl\basic\uStepBasic.pas',
  uStepCondition in '..\etl\steps\common\uStepCondition.pas',
  uStepSubTask in '..\etl\steps\common\uStepSubTask.pas',
  uStepTaskResult in '..\etl\steps\common\uStepTaskResult.pas',
  uStepVarDefine in '..\etl\steps\common\uStepVarDefine.pas',
  uStepDatasetSpliter in '..\etl\steps\data\uStepDatasetSpliter.pas',
  uStepFieldsOper in '..\etl\steps\data\uStepFieldsOper.pas',
  uStepJson2DataSet in '..\etl\steps\data\uStepJson2DataSet.pas',
  uStepQuery in '..\etl\steps\database\uStepQuery.pas',
  uStepFileDelete in '..\etl\steps\file\uStepFileDelete.pas',
  uStepFolderCtrl in '..\etl\steps\file\uStepFolderCtrl.pas',
  uStepIniRead in '..\etl\steps\file\uStepIniRead.pas',
  uStepIniWrite in '..\etl\steps\file\uStepIniWrite.pas',
  uStepUnzip in '..\etl\steps\file\uStepUnzip.pas',
  uStepWriteTxtFile in '..\etl\steps\file\uStepWriteTxtFile.pas',
  uStepDownloadFile in '..\etl\steps\network\uStepDownloadFile.pas',
  uStepHttpRequest in '..\etl\steps\network\uStepHttpRequest.pas',
  uStepFastReport in '..\etl\steps\report\uStepFastReport.pas',
  uStepReportMachine in '..\etl\steps\report\uStepReportMachine.pas',
  uStepExeCtrl in '..\etl\steps\util\uStepExeCtrl.pas',
  uStepServiceCtrl in '..\etl\steps\util\uStepServiceCtrl.pas',
  uExeUtil in '..\..\core\lib\uExeUtil.pas',
  uFileLogger in '..\..\core\lib\uFileLogger.pas',
  uFileUtil in '..\..\core\lib\uFileUtil.pas',
  uNetUtil in '..\..\core\lib\uNetUtil.pas',
  uServiceUtil in '..\..\core\lib\uServiceUtil.pas',
  uThreadQueueUtil in '..\..\core\lib\uThreadQueueUtil.pas',
  uFunctions in '..\..\common\uFunctions.pas',
  uStepDefines in '..\etl\steps\uStepDefines.pas',
  uStepFactory in '..\etl\steps\uStepFactory.pas',
  uTaskVar in '..\etl\comm\uTaskVar.pas',
  uDbConMgr in '..\etl\comm\uDbConMgr.pas',
  uThreadSafeFile in '..\etl\comm\uThreadSafeFile.pas',
  uDefines in '..\etl\comm\uDefines.pas',
  uTaskDefine in '..\etl\comm\uTaskDefine.pas',
  uGlobalVar in '..\etl\comm\uGlobalVar.pas',
  uTaskResult in '..\etl\comm\uTaskResult.pas',
  uExceptions in '..\etl\comm\uExceptions.pas',
  uTask in '..\etl\comm\uTask.pas',
  uFileFinder in '..\..\core\lib\uFileFinder.pas',
  uStepUiBasic in '..\etl\basic\uStepUiBasic.pas',
  uJob in '..\etl\comm\uJob.pas',
  uJobDispatcher in '..\etl\comm\uJobDispatcher.pas',
  uJobStarter in '..\etl\comm\uJobStarter.pas';

{$R *.res}

var
  LJobStarter: TJobStarter;
  LDisStrings: TStringList;
begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  Application.Initialize;
  Application.MainFormOnTaskbar := False;

  //���г���������Ӧ��task
  ExePath := ExtractFilePath(ParamStr(0));
  LDisStrings := TStringList.Create;
  LJobStarter := TJobStarter.Create(1);
  try
    LDisStrings.Delimiter := '/';
    LDisStrings.DelimitedText := ParamStr(1);
    if LDisStrings.Count = 2 then
    begin
      LJobStarter.LoadConfigFrom(ExePath + 'projects/' + LDisStrings.Strings[0] + '/project.json', LDisStrings.Strings[1]);
      LJobStarter.StartJob(LDisStrings.Strings[1]);
    end;
  finally
    LJobStarter.Free;
    LDisStrings.Free;
  end;

  Application.Run;
end.
