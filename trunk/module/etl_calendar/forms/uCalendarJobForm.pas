unit uCalendarJobForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBasicLogForm, Vcl.StdCtrls,
  Vcl.Buttons, RzPanel, Vcl.ComCtrls, Vcl.ExtCtrls, RzSplit, Vcl.Mask, RzEdit,
  DBGridEhGrouping, ToolCtrlsEh, DBGridEhToolCtrls, DynVarsEh, EhLibVCL,
  GridsEh, DBAxisGridsEh, DBGridEh, Data.DB, Datasnap.DBClient, uJobStarter, uStepDefines;

type
  TJobStarterExt = class(TJobStarter)
  protected
    function GetTaskInitParams: PStepData; override;
  end;

  TCalendarJobForm = class(TBasicLogForm)
    rzpnlTop: TRzPanel;
    btnSetting: TBitBtn;
    dtpDate: TDateTimePicker;
    dbgrdhJobs: TDBGridEh;
    dsJobs: TDataSource;
    cdsJobs: TClientDataSet;
    btnSyncFromApi: TBitBtn;
    btnSyncFromFile: TBitBtn;
    procedure btnSettingClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSyncFromApiClick(Sender: TObject);
    procedure btnSyncFromFileClick(Sender: TObject);
    procedure dtpDateCloseUp(Sender: TObject);
  private
    function CheckJobs: Boolean;
    procedure PrepareTaskParams;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CalendarJobForm: TCalendarJobForm;
  JobStarter: TJobStarterExt;

implementation

uses uSettingForm, uAppDefine, uDefines, uCalendarJobConfig, System.JSON;

type
  TTaskParamsRec = record
    Date: string;
  end;

var
  TaskParamsRec: TTaskParamsRec;


{$R *.dfm}


procedure TCalendarJobForm.PrepareTaskParams;
begin
  TaskParamsRec.Date := FormatDateTime('yyyy-mm-dd', dtpDate.DateTime);
end;

procedure TCalendarJobForm.btnSettingClick(Sender: TObject);
begin
  inherited;
  with TSettingForm.Create(nil) do
  try
    if ShowModal = mrOk then
      CheckJobs;
  finally
    Free;
  end;
end;

procedure TCalendarJobForm.FormCreate(Sender: TObject);
begin
  inherited;
  AppLogger.NoticeHandle := Self.Handle;

  dtpDate.DateTime := Now;

  ConfigFile := ExePath + 'config\calendar.ini';
  CalendarProjectConfigRec := TCalendarProjectConfigUtil.ReadConfigFrom(ConfigFile);

  PrepareTaskParams;

  //�ж��Ƿ���Ҫ����JobStarter����db���ӽ��м��
  CheckJobs;

  JobStarter := TJobStarterExt.Create(CalendarProjectConfigRec.ThreadCount, CalendarProjectConfigRec.LogLevel);
  JobStarter.LogNoticeHandle := Self.Handle;
end;

procedure TCalendarJobForm.FormDestroy(Sender: TObject);
begin
  inherited;
  JobStarter.Stop;
  JobStarter.Free;
end;


procedure TCalendarJobForm.btnSyncFromApiClick(Sender: TObject);
begin
  inherited;
  JobStarter.Stop;

  //�����־
  btnClearLog.Click;

  JobStarter.LoadConfigFrom(CalendarProjectConfigRec.AbsRootPath + 'sync_from_api.jobs');
  JobStarter.Start;
end;

procedure TCalendarJobForm.btnSyncFromFileClick(Sender: TObject);
begin
  inherited;
  //ִ�дӱ����ļ����������ļ�������
  JobStarter.Stop;

  //�����־
  btnClearLog.Click;

  JobStarter.LoadConfigFrom(CalendarProjectConfigRec.AbsRootPath + 'sync_from_file.jobs');
  JobStarter.Start;
end;


function TCalendarJobForm.CheckJobs: Boolean;
begin
  Result := FileExists(CalendarProjectConfigRec.AbsRootPath + 'project.json');
  if not Result then
  begin
    btnSyncFromApi.Enabled := False;
    btnSyncFromFile.Enabled := False;
  end
  else
  begin
    btnSyncFromApi.Enabled := True;
    btnSyncFromFile.Enabled := True;
  end;
end;


procedure TCalendarJobForm.dtpDateCloseUp(Sender: TObject);
begin
  inherited;
  PrepareTaskParams;
end;

{ TJobStartExt }

function TJobStarterExt.GetTaskInitParams: PStepData;
var
  LJsonData: TJSONObject;
begin
  //������֯�������
  Result := nil;
  LJsonData := TJSONObject.Create;
  try
    LJsonData.AddPair(TJSONPair.Create('date', TaskParamsRec.Date));
    New(Result);
    Result^.DataType := sdtText;
    Result^.Data := LJsonData.ToJSON;
  finally
    LJsonData.Free;
  end;
end;

end.
