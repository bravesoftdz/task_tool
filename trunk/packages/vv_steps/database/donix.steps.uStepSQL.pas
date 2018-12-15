unit donix.steps.uStepSQL;

interface

uses
  uStepBasic, System.JSON, System.Classes, Uni;

type
  TStepSQL = class (TStepBasic)
  private
    FDBConTitle: string;
    FQuerySql: string;
    FSqlParamsConfigJsonStr: string;

  protected
    procedure StartSelf; override;
  public
    procedure ParseStepConfig(AConfigJsonStr: string); override;
    procedure MakeStepConfigJson(var AToConfig: TJSONObject); override;

    property DBConTitle: string read FDBConTitle write FDBConTitle;
    property QuerySql: string read FQuerySql write FQuerySql;
    property SqlParamsConfigJsonStr: string read FSqlParamsConfigJsonStr write FSqlParamsConfigJsonStr;
  end;

implementation

uses
  uDefines, uFunctions, uStepDefines, Winapi.ActiveX, System.SysUtils;

{ TStepQuery }

procedure TStepSQL.MakeStepConfigJson(var AToConfig: TJSONObject);
begin
  inherited MakeStepConfigJson(AToConfig);
  AToConfig.AddPair(TJSONPair.Create('db_title', FDBConTitle));
  AToConfig.AddPair(TJSONPair.Create('sql', FQuerySql));
  AToConfig.AddPair(TJSONPair.Create('sql_params', FSqlParamsConfigJsonStr));
end;


procedure TStepSQL.ParseStepConfig(AConfigJsonStr: string);
begin
  inherited ParseStepConfig(AConfigJsonStr);
  FDBConTitle := GetJsonObjectValue(StepConfig.ConfigJson, 'db_title');
  FQuerySql := GetJsonObjectValue(StepConfig.ConfigJson, 'sql');
  FSqlParamsConfigJsonStr := GetJsonObjectValue(StepConfig.ConfigJson, 'sql_params');
end;


procedure TStepSQL.StartSelf;
var
  LQuery: TUniSQL;
  i: Integer;
  LParamName: string;
  LParamConfig: TJSONObject;
  LSqlParamsConfigJson: TJSONArray;
begin
  CheckTaskStatus;
  CoInitialize(nil);

  //��ȡ���ݿ�����
  LQuery := TUniSql.Create(nil);
  try
    //��ȡSql���
    LQuery.SQL.Text := FQuerySql;

    TaskVar.Logger.Debug(FormatLogMsg('��ȡ���ݿ����ӣ�' + FDBConTitle));

    LQuery.Connection := TaskVar.DbConMgr.GetDBConnection(FDBConTitle);
    if (LQuery.Connection.ProviderName = 'SQL Server')
        or (LQuery.Connection.ProviderName = 'MySQL')
        or (LQuery.Connection.ProviderName = 'PostgreSQL') then
    begin
      LQuery.SpecificOptions.Add('CommandTimeout=30');
    end;

    TaskVar.Logger.Debug(FormatLogMsg('SQL��' + FQuerySql));

    //�����󶨲���
    if LQuery.ParamCount > 0 then
    begin
      LSqlParamsConfigJson := TJSONObject.ParseJSONValue(FSqlParamsConfigJsonStr) as TJSONArray;
      if (LSqlParamsConfigJson = nil) then
      begin
        TaskVar.Logger.Error(FormatLogMsg('���������쳣��' + FSqlParamsConfigJsonStr));
        LQuery.Free;
        Exit;
      end
      else if LSqlParamsConfigJson.Count = 0 then
      begin
        TaskVar.Logger.Error(FormatLogMsg('������Ӧ�����쳣��' + FSqlParamsConfigJsonStr));
        LQuery.Free;
        LSqlParamsConfigJson.Free;
        Exit;
      end;

      try
        for i := 0 to LQuery.ParamCount - 1 do
        begin
          LParamName := LQuery.Params[i].Name;
          LParamConfig := GetRowInJsonArray(LSqlParamsConfigJson, 'param_name', LParamName);

          LQuery.ParamByName(LParamName).Value := GetParamValue(LParamConfig);

          TaskVar.Logger.Debug(FormatLogMsg('Sql�󶨲�����' + LParamName + '=' + LQuery.ParamByName(LParamName).Value));
        end;
      finally
        LSqlParamsConfigJson.Free;
      end;
    end;

    //ִ��
    try
      LQuery.Prepare;
      LQuery.Execute;

      TaskVar.Logger.Debug(FormatLogMsg('Sql���гɹ���Ӱ���¼����' + IntToStr(LQuery.RowsAffected)));

      if LQuery.RowsAffected > 0 then
      begin
        FOutData.DataType := sdtText;
        FOutData.Data := IntToStr(LQuery.LastInsertId);
      end;
    except
      on E: Exception do
      begin
        TaskVar.Logger.Error('SQL.Executeִ���쳣��' + E.Message);
        StopExceptionRaise(E.Message);
      end;
    end;


  finally
    LQuery.Free;
    CoUninitialize;
  end;
end;

end.
