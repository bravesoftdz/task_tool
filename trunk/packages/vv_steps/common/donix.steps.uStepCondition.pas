unit donix.steps.uStepCondition;
interface

uses
  uStepBasic, System.JSON;

type
  TValueOperator = (voUnknown, voDengYu, voBuDengYu, voXiaoYu, voXiaoyuDengyu, voDayu, voDayuDengYu,
                    voJia, voJian, voCheng, voChu, voMD5);

  TExpressionRec = record
    LeftParamRef: string;
    RightParamRef: string;
    ValueOperator: TValueOperator;
    ValueType: string;
  end;

  TStepCondition = class (TStepBasic)
  private
    FConditionParams: string;
    FConditionResults: string;
    function CalcConditionResult(AParamsConfigJson: TJSONArray): Variant;
    procedure ActToResult(AResult: Variant);
    function CalcExpression(ALastResult: Variant; AExpressionRec: TExpressionRec): Variant;
    procedure Act(AAction: string);
    function GetOperatorStr(AOperator: TValueOperator): string;
  protected
    procedure StartSelf; override;
  public
    procedure ParseStepConfig(AConfigJsonStr: string); override;
    procedure MakeStepConfigJson(var AToConfig: TJSONObject); override;

    procedure Start; override;

    property ConditionParams: string read FConditionParams write FConditionParams;
    property ConditionResults: string read FConditionResults write FConditionResults;
  end;

implementation

uses
  uDefines, uFunctions, System.Classes, System.SysUtils, uExceptions, System.Variants,
   uStepDefines;

{ TStepQuery }

procedure TStepCondition.MakeStepConfigJson(var AToConfig: TJSONObject);
begin
  inherited MakeStepConfigJson(AToConfig);
  AToConfig.AddPair(TJSONPair.Create('condition_params', FConditionParams));
  AToConfig.AddPair(TJSONPair.Create('condition_results', FConditionResults));
end;


procedure TStepCondition.ParseStepConfig(AConfigJsonStr: string);
begin
  inherited ParseStepConfig(AConfigJsonStr);
  FConditionParams := GetJsonObjectValue(StepConfig.ConfigJson, 'condition_params');
  FConditionResults := GetJsonObjectValue(StepConfig.ConfigJson, 'condition_results');
end;



procedure TStepCondition.Start;
begin
  try
    StartSelf;

    //ע������
    if StepConfig.RegDataToTask then
      RegOutDataToTaskVar;
  except
    on E: StopStepException do
    begin
      TaskVar.Logger.Error(FormatLogMsg('Stepִ����ֹ'));
    end;
  end;
end;

procedure TStepCondition.StartSelf;
var
  LConditionResult: Variant;
  LParamsConfigJson: TJSONArray;
begin
  try
    CheckTaskStatus;

    {�������������ڶ�������ģ����� or �������㣬����ÿһ�У�ִ����Ӧ��������,
    ���ڶ��еģ���ѭ��ִ����ɣ����еĽ����ж����������ʱ������Ӷ��У����� <>��
    ==, >=�� <=�� <��>��Ŀǰ֧����6�������������������+, - ,* , /�ȣ������֧��
    �������㣬���̷�������params����������
    }
    LParamsConfigJson := TJSONObject.ParseJSONValue(FConditionParams) as TJSONArray;
    if LParamsConfigJson = nil then Exit;

    LConditionResult := CalcConditionResult(LParamsConfigJson);

    {��������Ľ���ͽ�������е�ÿһ�����Ƚϣ�����ж��Ƿ�==���������������
    ����ö�Ӧ��Action����}
    ActToResult(LConditionResult);

    FOutData.DataType := sdtText;
    FOutData.Data := LConditionResult;
  finally
    if LParamsConfigJson <> nil then
      FreeAndNil(LParamsConfigJson);
  end;
end;


function TStepCondition.CalcConditionResult(AParamsConfigJson: TJSONArray): Variant;
var
  i: Integer;
  LConditionRow: TJSONObject;
  LExpressionRec: TExpressionRec;
begin
  Result := null;
  if AParamsConfigJson = nil then Exit;

  for i := 0 to AParamsConfigJson.Count - 1 do
  begin
    LConditionRow := AParamsConfigJson.Items[i] as TJSONObject;
    if LConditionRow = nil then
    begin
      StopExceptionRaise('����������������');
    end;

    LExpressionRec.LeftParamRef := GetJsonObjectValue(LConditionRow, 'left_param_ref');
    LExpressionRec.RightParamRef := GetJsonObjectValue(LConditionRow, 'right_param_ref');
    LExpressionRec.ValueOperator := TValueOperator(GetJsonObjectValue(LConditionRow, 'operator', '0', 'int'));
    LExpressionRec.ValueType := GetJsonObjectValue(LConditionRow, 'param_type');

    Result := CalcExpression(Result, LExpressionRec);

    if (LExpressionRec.ValueOperator > voUnknown) and (LExpressionRec.ValueOperator < voJia) then
    begin
      if Result then Break;
    end;
  end;
end;


procedure TStepCondition.Act(AAction: string);
var
  LSteps: TStringList;
begin
  TaskVar.Logger.Debug(FormatLogMsg('Act To Result��' + AAction));

  if AAction = 'END_STEP' then
  begin
    raise StopStepException.Create('END_STEP');
  end
  else if AAction = 'END_TASK' then
  begin
    StopExceptionRaise('�����ж���ֹ�˳�: END_TASK');
  end
  else
  begin
    //��Ҫ�Ǹ��ݸ�������ִ�ж�������Ŀ��ƴ���
    LSteps := TStringList.Create;
    try
      LSteps.Delimiter := '.';
      LSteps.DelimitedText := AAction;
      if (LSteps.Count <> 2) or (LSteps.Strings[0] <> 'step') then
        StopExceptionRaise('���������ж���������step.��ͷ');

      FOutData := FInData;
      if LSteps.Strings[1] = '*' then
      begin
        StartChildren;
      end
      else
      begin
        StartChildren(LSteps.Strings[1]);
      end;
    finally
      LSteps.Free;
    end;
  end;
end;

procedure TStepCondition.ActToResult(AResult: Variant);
var
  LResultsJson: TJSONArray;
  LResultJson: TJSONObject;
  LResultValue: Variant;
  LResultAction: string;
  i: Integer;
begin
  {���ݻ�õı��ʽ��ֽAResult������ͬ������
   //���ٵ���children�����Ǹ��ݱ�Action�е�������������Ӧ�Ĵ���}
  LResultsJson := TJSONObject.ParseJSONValue(ConditionResults) as TJSONArray;
  if LResultsJson = nil then Exit;

  try
    for i := 0 to LResultsJson.Count - 1 do
    begin
      LResultJson := LResultsJson.Items[i] as TJSONObject;
      if LResultJson = nil then
        StopExceptionRaise('����������������');

      LResultValue := GetJsonObjectValue(LResultJson, 'result_value');
      LResultAction := GetJsonObjectValue(LResultJson, 'result_action');
      if (LResultValue = 'TRUE') and (not VarIsNull(AResult)) and AResult then
      begin
        Act(LResultAction);
      end
      else if (LResultValue = 'FALSE') and (not VarIsNull(AResult)) and (not AResult) then
      begin
        Act(LResultAction);
      end
      else
      begin
        LResultValue := GetParamValue(LResultValue, 'string', '');
        if AResult = LResultValue then
        begin
          Act(LResultAction);
        end;
      end;
    end;
  finally
    LResultsJson.Free;
  end;

end;


function TStepCondition.CalcExpression(ALastResult: Variant; AExpressionRec: TExpressionRec): Variant;
var
  LLeftValue, LRightValue: Variant;
begin
  if (AExpressionRec.ValueOperator < voJia) then
  begin
    if (not VarIsNull(ALastResult)) and (ALastResult) then
    begin
      Result := ALastResult;
      Exit;
    end;
  end;


  Result := ALastResult;
  LLeftValue := GetParamValue(AExpressionRec.LeftParamRef, AExpressionRec.ValueType, '');
  LRightValue := GetParamValue(AExpressionRec.RightParamRef, AExpressionRec.ValueType, '');

  case AExpressionRec.ValueOperator of
    voUnknown: Result := LRightValue;
    voDengYu: Result := (LLeftValue = LRightValue);
    voBuDengYu: Result := (LLeftValue <> LRightValue);
    voXiaoYu: Result := (LLeftValue < LRightValue);
    voXiaoyuDengyu: Result := (LLeftValue <= LRightValue);
    voDayu: Result := (LLeftValue > LRightValue);
    voDayuDengYu: Result := (LLeftValue >= LRightValue);
    voJia:
    begin
      Result := (LLeftValue + LRightValue);
    end;
    voJian:
    begin
      Result := (LLeftValue - LRightValue);
    end;
    voCheng: Result := (LLeftValue * LRightValue);
    voChu: Result := (LLeftValue / LRightValue);
    voMD5: Result := Md5String(LRightValue);
  end;

  if AExpressionRec.ValueOperator >= voJia then
  begin
    Result := ALastResult + Result;
  end;

  TaskVar.Logger.Debug(FormatLogMsg('������ʽ��left_param:' + VarToStr(LLeftValue)
                                     + '��value_operator:' + GetOperatorStr(AExpressionRec.ValueOperator)
                                     + '��right_param:' + VarToStr(LRightValue)
                                     + '��param_type:' + AExpressionRec.ValueType
                                     + '��result:' + VarToStrDef(Result, '')));
end;


function TStepCondition.GetOperatorStr(AOperator: TValueOperator): string;
begin
  case AOperator of
    voUnknown: Result := '��';
    voDengYu: Result := '==';
    voBuDengYu: Result := '!=';
    voXiaoYu: Result := '<';
    voXiaoyuDengyu: Result := '<=';
    voDayu: Result := '>';
    voDayuDengYu: Result := '>=';
    voJia: Result := '+';
    voJian: Result := '-';
    voCheng: Result := '*';
    voChu: Result := '/';
    voMD5: Result := 'MD5';
  else
    Result := 'δ֪';
  end;
end;


end.
