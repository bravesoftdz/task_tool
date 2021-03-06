unit uStepSQL;

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

  //获取数据库连接
  LQuery := TUniSql.Create(nil);
  try
    //获取Sql语句
    LQuery.SQL.Text := FQuerySql;

    TaskVar.Logger.Debug(FormatLogMsg('获取数据库连接：' + FDBConTitle));

    LQuery.Connection := TaskVar.DbConMgr.GetDBConnection(FDBConTitle);
    if (LQuery.Connection.ProviderName = 'SQL Server')
        or (LQuery.Connection.ProviderName = 'MySQL')
        or (LQuery.Connection.ProviderName = 'PostgreSQL') then
    begin
      LQuery.SpecificOptions.Add('CommandTimeout=30');
    end;

    TaskVar.Logger.Debug(FormatLogMsg('SQL：' + FQuerySql));

    //解析绑定参数
    if LQuery.ParamCount > 0 then
    begin
      LSqlParamsConfigJson := TJSONObject.ParseJSONValue(FSqlParamsConfigJsonStr) as TJSONArray;
      if (LSqlParamsConfigJson = nil) then
      begin
        TaskVar.Logger.Error(FormatLogMsg('参数配置异常：' + FSqlParamsConfigJsonStr));
        LQuery.Free;
        Exit;
      end
      else if LSqlParamsConfigJson.Count = 0 then
      begin
        TaskVar.Logger.Error(FormatLogMsg('参数对应配置异常：' + FSqlParamsConfigJsonStr));
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

          TaskVar.Logger.Debug(FormatLogMsg('Sql绑定参数：' + LParamName + '=' + LQuery.ParamByName(LParamName).Value));
        end;
      finally
        LSqlParamsConfigJson.Free;
      end;
    end;

    //执行
    try
      LQuery.Prepare;
      LQuery.Execute;

      TaskVar.Logger.Debug(FormatLogMsg('Sql运行成功，影响记录数：' + IntToStr(LQuery.RowsAffected)));

      if LQuery.RowsAffected > 0 then
      begin
        FOutData.DataType := sdtText;
        FOutData.Data := IntToStr(LQuery.LastInsertId);
      end;
    except
      on E: Exception do
      begin
        TaskVar.Logger.Error('SQL.Execute执行异常：' + E.Message);
        StopExceptionRaise(E.Message);
      end;
    end;


  finally
    LQuery.Free;
    CoUninitialize;
  end;
end;



initialization
RegisterClass(TStepSQL);


finalization
UnRegisterClass(TStepSQL);




end.
