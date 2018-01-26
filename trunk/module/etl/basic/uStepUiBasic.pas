unit uStepUiBasic;

interface

uses uStepBasic;

type
  TStepUiBasic = class(TStepBasic)
  protected
    procedure CheckBlockUI;
  public
    procedure Start; override;
  end;

implementation

{ TStepUiBasic }

procedure TStepUiBasic.CheckBlockUI;
begin
  if not TaskVar.CanBlockUI then
  begin
    //StopExceptionRaise('����������BlockUI������');
  end;
end;

procedure TStepUiBasic.Start;
begin
  CheckBlockUI;
  inherited Start;
end;

end.
