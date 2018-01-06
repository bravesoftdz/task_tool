unit uJobEditForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBasicDlgForm, Vcl.StdCtrls,
  Vcl.Buttons, Vcl.ExtCtrls, Vcl.Mask, RzEdit, RzBtnEdt, Datasnap.DBClient,
  Vcl.ComCtrls, RzDTP;

type
  TJobEditForm = class(TBasicDlgForm)
    lblTaskName: TLabel;
    edtTaskName: TEdit;
    lblFileName: TLabel;
    btnFileName: TRzButtonEdit;
    lbl1: TLabel;
    edtInterval: TEdit;
    lblLastTime: TLabel;
    lblNextTime: TLabel;
    lblTimeOut: TLabel;
    edtTimeOut: TEdit;
    rgStatus: TRadioGroup;
    btnDelete: TBitBtn;
    rzdtmpckrLastTime: TRzDateTimePicker;
    rzdtmpckrNextTime: TRzDateTimePicker;
    dlgOpenTaskFile: TOpenDialog;
    procedure btnOKClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnFileNameButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    cdsTaskList: TClientDataSet;
    RecNo: Integer;
    EditMode: string;

    procedure LoadData;
  end;

var
  JobEditForm: TJobEditForm;

implementation

uses uDefines;

{$R *.dfm}

procedure TJobEditForm.btnDeleteClick(Sender: TObject);
begin
  inherited;
  if EditMode <> 'add' then
  begin
    if cdsTaskList.RecordCount > 0 then
    begin
      if MessageDlg('��ȷ��Ҫɾ���������ִ����', mtWarning, [mbOK, mbNo], 0) = mrOk then
        cdsTaskList.Delete;
    end;
  end;
end;

procedure TJobEditForm.btnFileNameButtonClick(Sender: TObject);
begin
  inherited;
  //����Ч��Task�ļ�
  dlgOpenTaskFile.InitialDir := ExePath + 'data\';
  if dlgOpenTaskFile.Execute then
  begin
    if FileExists(dlgOpenTaskFile.FileName) then
    begin
      btnFileName.Text := dlgOpenTaskFile.FileName;
      edtTaskName.Text := ChangeFileExt(ExtractFileName(btnFileName.Text), '');
    end;
  end;
end;

procedure TJobEditForm.btnOKClick(Sender: TObject);
begin
  inherited;
  if edtTaskName.Text = '' then
  begin
    ShowMessage('�������Ʋ���Ϊ��');
    ModalResult := mrNone;
    Exit;
  end;
  if not FileExists(btnFileName.Text) then
  begin
    ShowMessage('�����ļ�������');
    ModalResult := mrNone;
    Exit;
  end;

  if EditMode = 'add' then
  begin
    if cdsTaskList.Locate('task_name', edtTaskName.Text, []) then
    begin
      ShowMessage('�������Ѿ��������б���');
      ModalResult := mrNone;
      Exit;
    end;
    cdsTaskList.Append;
  end
  else if cdsTaskList.FieldByName('task_name').AsString <> '' then
  begin
    if cdsTaskList.Locate('task_name', edtTaskName.Text, []) then
    begin
      if cdsTaskList.RecNo <> RecNo then
      begin
        ShowMessage('�����б��д���ͬ��������ȷ��');
        ModalResult := mrNone;
        cdsTaskList.RecNo := RecNo;
        Exit;
      end;
    end;
    cdsTaskList.Edit;
  end;

  cdsTaskList.FieldByName('task_name').AsString := edtTaskName.Text;
  cdsTaskList.FieldByName('file_name').AsString := btnFileName.Text;
  cdsTaskList.FieldByName('interval').AsString := edtInterval.Text;
  cdsTaskList.FieldByName('last_time').AsString := FormatDateTime('yyyy-MM-dd hh:mm:ss', rzdtmpckrLastTime.DateTime);
  cdsTaskList.FieldByName('next_time').AsString := FormatDateTime('yyyy-MM-dd hh:mm:ss', rzdtmpckrNextTime.DateTime);
  cdsTaskList.FieldByName('time_out').AsString := edtTimeOut.Text;
  cdsTaskList.FieldByName('status').AsInteger := rgStatus.ItemIndex;
  cdsTaskList.Post;
end;

procedure TJobEditForm.LoadData;
begin
  if (EditMode <> 'add') and (cdsTaskList.RecordCount > 0) then
  begin
    RecNo := cdsTaskList.RecNo;
    edtTaskName.Text := cdsTaskList.FieldByName('task_name').AsString;
    btnFileName.Text := cdsTaskList.FieldByName('file_name').AsString;
    edtInterval.Text := cdsTaskList.FieldByName('interval').AsString;
    rzdtmpckrLastTime.DateTime := VarToDateTime(cdsTaskList.FieldByName('last_time').AsString);
    rzdtmpckrNextTime.DateTime := VarToDateTime(cdsTaskList.FieldByName('next_time').AsString);
    edtTimeOut.Text := cdsTaskList.FieldByName('time_out').AsString;
    rgStatus.ItemIndex := cdsTaskList.FieldByName('status').AsInteger;
  end;

end;

end.
