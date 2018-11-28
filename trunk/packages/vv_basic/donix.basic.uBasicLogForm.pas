unit donix.basic.uBasicLogForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBasicForm, Vcl.ExtCtrls, RzPanel,
  RzSplit, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Buttons, uFileLogger;

type
  TBasicLogForm = class(TBasicForm)
    rzspltrLogForm: TRzSplitter;
    rzpnl3: TRzPanel;
    btnClearLog: TBitBtn;
    redtLog: TRichEdit;
    procedure MSGLoggerHandler(var AMsg: TMessage); message VV_MSG_LOGGER;
    procedure SetRichEditLineColor(AEditor: TRichEdit; ALine: Integer;AColor: TColor);
    procedure btnClearLogClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BasicLogForm: TBasicLogForm;

implementation

{$R *.dfm}

procedure TBasicLogForm.SetRichEditLineColor(AEditor: TRichEdit; ALine: Integer; AColor: TColor);
begin
  redtLog.SelStart := SendMessage(redtLog.Handle, EM_LINEINDEX, ALine, 0); // ѡ����һ������
  redtLog.SelLength := Length(redtLog.Lines.Strings[ALine]);
  redtLog.SelAttributes.Color := AColor; // ��Ϊ��Ҫ�������С
end;


procedure TBasicLogForm.btnClearLogClick(Sender: TObject);
begin
  inherited;
  redtLog.Clear;
end;

procedure TBasicLogForm.MSGLoggerHandler(var AMsg: TMessage);
var
  LMsg: PChar;
  LLine: Integer;
begin
  LMsg := PChar(AMsg.WParam);
  //����״̬
  LLine := redtLog.Lines.Add(LMsg);

  if Pos('[WARN]', LMsg) > 0 then
  begin
    SetRichEditLineColor(redtLog, LLine, clWebOrangeRed);
  end
  else if (Pos('[ERROR]', LMsg) > 0) or (Pos('[FATAL]', LMsg) > 0)
          or (Pos('����', LMsg) > 0) or (Pos('ʧ��', LMsg) > 0)
          or (Pos('�쳣', LMsg) > 0)  then
  begin
    SetRichEditLineColor(redtLog, LLine, clWebRed);
  end
  else if Pos('[FORCE]', LMsg) > 0 then
  begin
    SetRichEditLineColor(redtLog, LLine, clWebGreen);
  end;
end;

end.
