unit uDatabaseConnectTestForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBasicDlgForm, Vcl.StdCtrls,
  Vcl.Buttons, Vcl.ExtCtrls, RzLabel, Vcl.Mask, RzEdit, MySQLUniProvider,
  SQLServerUniProvider, OracleUniProvider, SQLiteUniProvider, UniProvider,
  ODBCUniProvider, Uni;

type
  TDatabaseConnectTestForm = class(TBasicDlgForm)
    lblProvider: TRzLabel;
    lbl1: TRzLabel;
    lblServer: TRzLabel;
    lblPort: TRzLabel;
    lbl2: TRzLabel;
    lbl3: TRzLabel;
    lbl4: TRzLabel;
    edtDbTitle: TRzEdit;
    cbbProvider: TComboBox;
    edtServer: TRzEdit;
    edtPort: TRzEdit;
    edtDatabase: TRzEdit;
    edtUserName: TRzEdit;
    edtPassword: TRzMaskEdit;
    lblSpecificStr: TRzLabel;
    mmoSpecificStr: TMemo;
    btnTest: TBitBtn;
    procedure btnTestClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Connect: TUniConnection;
  end;

var
  DatabaseConnectTestForm: TDatabaseConnectTestForm;

implementation

uses uDesignTimeDefines;

{$R *.dfm}

procedure TDatabaseConnectTestForm.btnTestClick(Sender: TObject);
begin
  inherited;
  if Connect.Connected then
    Connect.Close;
  Connect.ProviderName := cbbProvider.Text;
  Connect.Server := edtServer.Text;
  Connect.Port := StrToIntDef(edtPort.Text, 0);
  Connect.Database := edtDatabase.Text;
  Connect.Username := edtUserName.Text;
  Connect.Password := edtPassword.Text;
  Connect.SpecificOptions.Text := mmoSpecificStr.Text;

  try
    Connect.Connect;
    if Connect.Connected then
    begin
      ShowMsg('���ݿ����ӳɹ�!');
    end
    else
    begin
      ShowMsg('���ݿ�����ʧ��');
    end;
  except
    on E: Exception do
    begin
      ShowMsg(E.Message);
    end;
  end;
end;

end.
