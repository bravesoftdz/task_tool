unit uStepUiBasic;

interface

uses uStepBasic;

type
  TStepUiBasic = class(TStepBasic)
  protected
    procedure CheckUserInteractive;
  public
    procedure Start; override;
  end;

implementation

{ TStepUiBasic }

procedure TStepUiBasic.CheckUserInteractive;
begin
  if TaskVar.Interactive <> 1 then
  begin
    StopExceptionRaise('����������Interactive����ģʽ������Job��Interactive����');
  end;
end;

procedure TStepUiBasic.Start;
begin
  CheckUserInteractive;
  inherited Start;
end;

end.
