unit uJobsMgrForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBasicForm, Vcl.StdCtrls, Vcl.Buttons,
  Vcl.ExtCtrls, RzPanel, DBGridEhGrouping, ToolCtrlsEh, DBGridEhToolCtrls,
  DynVarsEh, EhLibVCL, GridsEh, DBAxisGridsEh, DBGridEh, Data.DB,
  Datasnap.DBClient, Vcl.Menus, uJobMgr, Vcl.DBCtrls, Vcl.ComCtrls, RzListVw,
  RzShellCtrls, uDesignTimeDefines, RzSplit, uFileLogger, uBasicLogForm;

type
  TJobsForm = class(TBasicLogForm)
    rzpnl1: TRzPanel;
    cdsJobs: TClientDataSet;
    dsJobs: TDataSource;
    pmJobs: TPopupMenu;
    AddJob: TMenuItem;
    DeleteTJob: TMenuItem;
    btnSave: TBitBtn;
    btnStartJob: TBitBtn;
    btnStartAll: TBitBtn;
    btnStopJob: TBitBtn;
    dbnvgrJobs: TDBNavigator;
    dlgOpenTaskFile: TOpenDialog;
    btnLoadJobs: TBitBtn;
    tmrJobsSchedule: TTimer;
    rzspltr1: TRzSplitter;
    dbgrdhJobs: TDBGridEh;
    rzpnl2: TRzPanel;
    pnl1: TPanel;
    lstLogs: TRzShellList;
    btnEnableAll: TBitBtn;
    procedure DeleteTJobClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnStartJobClick(Sender: TObject);
    procedure btnStopJobClick(Sender: TObject);
    procedure cdsJobsPostError(DataSet: TDataSet; E: EDatabaseError;
      var Action: TDataAction);
    procedure btnLoadJobsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tmrJobsScheduleTimer(Sender: TObject);
    procedure btnStartAllClick(Sender: TObject);

    procedure dbgrdhJobsColumns3CellButtons0Click(Sender: TObject;
      var Handled: Boolean);
    procedure dbgrdhJobsColumns2CellButtons0Click(Sender: TObject;
      var Handled: Boolean);
    procedure dbgrdhJobsDblClick(Sender: TObject);
    procedure btnEnableAllClick(Sender: TObject);

  private
    { Private declarations }
    JobsFile: string;
    JobMgr: TJobMgr;

    procedure RefreshData;
    procedure SaveData;
  public
    procedure ConfigJobs(AJobsConfigFile: string);
  end;

var
  JobsForm: TJobsForm;

implementation

uses uDefines, uFunctions, uJobScheduleForm, uTaskEditForm, uFileUtil, uTaskVar;

{$R *.dfm}


procedure TJobsForm.btnEnableAllClick(Sender: TObject);
var
  LStatus: Integer;
  i: Integer;
begin
  inherited;
  if btnEnableAll.Caption = 'ȫ������' then
  begin
    btnEnableAll.Caption := 'ȫ������';
    LStatus := 1;
  end
  else
  begin
    btnEnableAll.Caption := 'ȫ������';
    LStatus := 0;
  end;

  for i := 1 to cdsJobs.RecordCount do
  begin
    cdsJobs.RecNo := i;
    cdsJobs.Edit;
    cdsJobs.FieldByName('status').AsInteger := LStatus;
    cdsJobs.Post;
  end;
end;

procedure TJobsForm.btnLoadJobsClick(Sender: TObject);
begin
  inherited;
  RefreshData;
end;

procedure TJobsForm.btnSaveClick(Sender: TObject);
begin
  inherited;
  SaveData;
end;

procedure TJobsForm.btnStartAllClick(Sender: TObject);
begin
  inherited;
  if tmrJobsSchedule.Enabled then
  begin
    tmrJobsSchedule.Enabled := False;
    JobMgr.Stop;
    btnStartAll.Caption := '����ȫ������';
  end
  else
  begin
    tmrJobsSchedule.Enabled := True;
    btnStartAll.Caption := 'ֹͣȫ������';
  end;
end;

procedure TJobsForm.btnStartJobClick(Sender: TObject);
begin
  inherited;
  try
    if cdsJobs.RecordCount > 0 then
    begin
      JobMgr.StartJob(cdsJobs.FieldByName('job_name').AsString);
    end;
  finally

  end;
end;

procedure TJobsForm.btnStopJobClick(Sender: TObject);
begin
  inherited;
  JobMgr.StopJob(cdsJobs.FieldByName('job_name').AsString);
end;


procedure TJobsForm.cdsJobsPostError(DataSet: TDataSet; E: EDatabaseError;
  var Action: TDataAction);
begin
  inherited;
  if (E as EDBClient).ErrorCode = 9729 then
  begin
    ShowMsg('�Ѵ���ͬ���Ĺ�������');
  end;
  Action := daAbort;
end;


procedure TJobsForm.dbgrdhJobsColumns2CellButtons0Click(Sender: TObject;
  var Handled: Boolean);
begin
  inherited;
  dlgOpenTaskFile.InitialDir := CurrentProject.RootPath;
  if dlgOpenTaskFile.Execute then
  begin
    if FileExists(dlgOpenTaskFile.FileName) then
    begin
      if cdsJobs.FieldByName('job_name').AsString = '' then
      begin
        cdsJobs.Append;
        cdsJobs.FieldByName('job_name').AsString := ChangeFileExt(ExtractFileName(dlgOpenTaskFile.FileName), '');
        cdsJobs.FieldByName('schedule').AsString := '';
        cdsJobs.FieldByName('status').AsInteger := 0;
        cdsJobs.FieldByName('sort_no').AsInteger := 0;
      end
      else
      begin
        cdsJobs.Edit;
      end;

      //�޸�Ϊ���·��
      cdsJobs.FieldByName('task_file').AsString := TDesignUtil.GetRelativePathToProject(dlgOpenTaskFile.FileName);
    end;
  end;
  Handled := True;
end;

procedure TJobsForm.dbgrdhJobsColumns3CellButtons0Click(Sender: TObject;
  var Handled: Boolean);
begin
  inherited;
  with TJobScheduleForm.Create(nil) do
  try
    ParseConfig(cdsJobs.FieldByName('schedule').AsString);
    if ShowModal = mrOk then
    begin
      cdsJobs.Edit;
      cdsJobs.FieldByName('schedule').AsString := MakeConfigJsonStr;
      cdsJobs.Post;
    end;
  finally
    Free;
  end;
end;

procedure TJobsForm.dbgrdhJobsDblClick(Sender: TObject);
var
  LTaskFile: string;
begin
  inherited;
  //˫���༭
  if cdsJobs.RecordCount > 0 then
  begin
    //��ȡ��ǰ���ļ�
    LTaskFile := TFileUtil.GetAbsolutePathEx(CurrentProject.RootPath, cdsJobs.FieldByName('task_file').AsString);
    if not FileExists(LTaskFile) then
    begin
      ShowMsg('�����ļ������ڣ������ļ�·�������������');
      Exit;
    end;

    with TTaskEditForm.Create(nil) do
    try
      ConfigTask(LTaskFile);
      ShowModal;
    finally
      Free;
    end;
  end;
end;

procedure TJobsForm.DeleteTJobClick(Sender: TObject);
begin
  inherited;
  if (not cdsJobs.Active) or (cdsJobs.RecordCount = 0) then Exit;
  
  if ShowMsg('��ȷ��Ҫɾ����ǰ������', MB_OKCANCEL) = mrOk then
  begin
    cdsJobs.Delete;
  end;
end;

procedure TJobsForm.ConfigJobs(AJobsConfigFile: string);
begin
  JobsFile := AJobsConfigFile;
  RefreshData;
end;

procedure TJobsForm.FormCreate(Sender: TObject);
begin
  inherited;
  AppLogger.NoticeHandle := Handle;
  JobMgr := TJobMgr.Create(2);
  JobMgr.LoadConfigFrom(CurrentProject.JobsFile);
  JobMgr.CallerHandle := Handle;
  lstLogs.Folder.PathName := CurrentProject.RootPath + 'task_log\';
end;

procedure TJobsForm.FormDestroy(Sender: TObject);
begin
  AppLogger.NoticeHandle := 0;
  SaveData;
  JobMgr.Free;
end;

procedure TJobsForm.SaveData;
var
  LStringList: TStringList;
begin
  inherited;
  LStringList := TStringList.Create;
  try
    LStringList.Text := DataSetToJsonStr(cdsJobs);
    LStringList.SaveToFile(JobsFile);
  finally
    LStringList.Free;
  end;
end;

procedure TJobsForm.tmrJobsScheduleTimer(Sender: TObject);
begin
  inherited;
  try
    if cdsJobs.RecordCount > 0 then
    begin
      JobMgr.Start;
    end;
  finally

  end;
end;

procedure TJobsForm.RefreshData;
var
  LStringList: TStringList;
begin
  //��Ĭ�ϵ�jobs�ļ�����
  LStringList := TStringList.Create;
  try
    if FileExists(JobsFile) then
    begin
      if JobMgr.LoadConfigFrom(JobsFile) then
      begin
        cdsJobs.EmptyDataSet;
        LStringList.LoadFromFile(JobsFile);
        JsonToDataSet(LStringList.Text, cdsJobs);
      end
      else
        ShowMsg('��Ŀ�����б������ļ�����ʧ��');
    end;
  finally
    LStringList.Free;
  end;
end;

end.
