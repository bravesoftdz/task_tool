unit uUserNotify;

interface

uses Vcl.Dialogs, System.Contnrs, uUserNotifyMsgForm;

type
  TUserNotify = class
  private
    FNotifyForms: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;

    function BlockNotify(AMsg: string): Integer;
  end;

implementation

uses Vcl.Forms;

{ TUserNotify }

function TUserNotify.BlockNotify(AMsg: string): Integer;
var
  LForm: TUserNotifyMsgForm;
begin
  //�÷��������ھ��н�����ϵͳ�н��д���Ϊ��������Ϻõ�ά����
  LForm := TUserNotifyMsgForm.Create(Application);
  FNotifyForms.Add(LForm);
  with LForm do
  try
    lblMsg.Caption := AMsg;
    Result := ShowModal;
  finally
    Free;
  end;
end;

constructor TUserNotify.Create;
begin
  inherited;
  FNotifyForms := TObjectList.Create(False);
end;

destructor TUserNotify.Destroy;
var
  i: Integer;
begin
  for i := FNotifyForms.Count - 1 downto 0 do
  begin
    FNotifyForms.Delete(i);
  end;
  FNotifyForms.Free;
  inherited;
end;

end.
