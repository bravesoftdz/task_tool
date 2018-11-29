unit uStepExceptionCatch;
interface

uses
  uStepBasic, System.JSON;

type
  TStepExceptionCatch = class (TStepBasic)
  private
    FAct: Integer;
  protected

  public
    procedure ParseStepConfig(AConfigJsonStr: string); override;
    procedure MakeStepConfigJson(var AToConfig: TJSONObject); override;

    procedure Start; override;

    property Act: Integer read FAct write FAct;
  end;

implementation

uses
  uDefines, uFunctions, System.Classes, System.SysUtils, uFileLogger,
   uStepDefines;

{ TStepQuery }

procedure TStepExceptionCatch.MakeStepConfigJson(var AToConfig: TJSONObject);
begin
  inherited MakeStepConfigJson(AToConfig);
  AToConfig.AddPair(TJSONPair.Create('except_act', IntToStr(FAct)));
end;


procedure TStepExceptionCatch.ParseStepConfig(AConfigJsonStr: string);
begin
  inherited ParseStepConfig(AConfigJsonStr);
  FAct := StrToIntDef(GetJsonObjectValue(StepConfig.ConfigJson, 'except_act'), 0);
end;



procedure TStepExceptionCatch.Start;
begin
  try
    StartSelf;

    //ע������
    if StepConfig.RegDataToTask then
      RegOutDataToTaskVar;

    StartChildren();
  except
    on E: Exception do
    begin
      //�жϾ����ִ�ж���
      if FAct = 1 then
        raise E
      else
      begin
        LogMsg('��׽��δ������쳣��' + E.Message, llForce);
      end;
    end;
  end;
end;



initialization
RegisterClass(TStepExceptionCatch);

finalization
UnRegisterClass(TStepExceptionCatch);

end.
