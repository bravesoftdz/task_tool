unit uSettingForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBasicDlgForm, Vcl.StdCtrls,
  Vcl.Buttons, Vcl.ExtCtrls, Vcl.Mask, RzEdit, RzBtnEdt, uCalendarJobConfig;

type
  TSettingForm = class(TBasicDlgForm)
    lbl1: TLabel;
    lbl2: TLabel;
    edtHandlerCount: TEdit;
    lbl4: TLabel;
    mmoAllowedTime: TMemo;
    lbl5: TLabel;
    mmoDisallowedTime: TMemo;
    lbl8: TLabel;
    lbl7: TLabel;
    lbl3: TLabel;
    cbbLogLevel: TComboBox;
    btnDatabase: TBitBtn;
    btnGlobalVar: TBitBtn;
    btnDocRoot: TRzButtonEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnDatabaseClick(Sender: TObject);
    procedure btnGlobalVarClick(Sender: TObject);
    procedure btnDocRootButtonClick(Sender: TObject);
  private
    { Private declarations }
    procedure CheckJobsFile;
  public
    { Public declarations }
  end;

var
  SettingForm: TSettingForm;

implementation

uses uDefines, uFileLogger, uFileUtil, uAppDefine, uDatabasesForm, uGlobalVarSettingForm,
uSelectFolderForm;

{$R *.dfm}

procedure TSettingForm.btnDatabaseClick(Sender: TObject);
begin
  inherited;
  //����project������Ŀ·�������ݿ�
  with TDatabasesForm.Create(nil) do
  try
    ConfigDatabases(CalendarProjectConfigRec.DbsFile);
    ShowModal;
  finally
    Free;
  end;
end;

procedure TSettingForm.btnDocRootButtonClick(Sender: TObject);
begin
  inherited;
  with TSelectFolderForm.Create(nil) do
  try
    RootDir := ExePath;
    if ShowModal = mrOk then
    begin
       btnDocRoot.Text := TFileUtil.GetRelativePath(ExePath, SelectedPath);
    end;
  finally
    Free;
  end;
end;

procedure TSettingForm.btnGlobalVarClick(Sender: TObject);
begin
  inherited;
  //����jobsfile������Ŀ��ȫ�ֲ���
  with TGlobalVarSettingForm.Create(nil) do
  try
    ConfigGlobalVar(CalendarProjectConfigRec.RootPath + 'project.global');
    ShowModal;
  finally
    Free;
  end;
end;

procedure TSettingForm.btnOKClick(Sender: TObject);
begin
  inherited;
  CalendarProjectConfigRec.RootPath := btnDocRoot.Text;
  CalendarProjectConfigRec.LogLevel := TLogLevel(cbbLogLevel.ItemIndex);
  CalendarProjectConfigRec.ThreadCount := StrToIntDef(edtHandlerCount.Text, 1);
  CalendarProjectConfigRec.AllowedTimes := mmoAllowedTime.Lines.DelimitedText;
  CalendarProjectConfigRec.DisallowedTimes := mmoDisallowedTime.Lines.DelimitedText;

  TCalendarProjectConfigUtil.WriteConfigTo(CalendarProjectConfigRec, ConfigFile);

  //���¶�ȡ����
  CalendarProjectConfigRec := TCalendarProjectConfigUtil.ReadConfigFrom(ConfigFile);
end;

procedure TSettingForm.FormCreate(Sender: TObject);
begin
  inherited;
  btnDocRoot.Text := CalendarProjectConfigRec.RootPath;
  cbbLogLevel.ItemIndex := Ord(CalendarProjectConfigRec.LogLevel);
  edtHandlerCount.Text := IntToStr(CalendarProjectConfigRec.ThreadCount);
  mmoAllowedTime.Lines.DelimitedText := CalendarProjectConfigRec.AllowedTimes;
  mmoDisallowedTime.Lines.DelimitedText := CalendarProjectConfigRec.DisallowedTimes;

  //����Ƿ�����Ч��jobs��Ŀ�ļ�
  CheckJobsFile;
end;


procedure TSettingForm.CheckJobsFile;
begin
  //��ȡ��ǰjobsfile���ڵ���Ŀ·��
  if btnDocRoot.Text <> '' then
  begin
    btnDatabase.Enabled := True;
    btnGlobalVar.Enabled := True;
  end
  else
  begin
    btnDatabase.Enabled := False;
    btnGlobalVar.Enabled := False;
  end;
end;

end.
