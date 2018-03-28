unit uStepJson2Table;

interface

uses
  uStepBasic, System.JSON, System.Classes, Uni;

type
  TStepJson2Table = class (TStepBasic)
  private
    FDBConTitle: string;
    FTableName: string;
    FUniqueKeyFields: string;
    FSkipExists: Boolean;

  protected
    procedure StartSelf; override;
  public
    procedure ParseStepConfig(AConfigJsonStr: string); override;
    procedure MakeStepConfigJson(var AToConfig: TJSONObject); override;

    property DBConTitle: string read FDBConTitle write FDBConTitle;
    property TableName: string read FTableName write FTableName;
    property UniqueKeyFields: string read FUniqueKeyFields write FUniqueKeyFields;
    property SkipExists: Boolean read FSkipExists write FSkipExists;
  end;

implementation

uses
  uDefines, uFunctions, uStepDefines, Winapi.ActiveX, System.SysUtils;

{ TStepQuery }

procedure TStepJson2Table.MakeStepConfigJson(var AToConfig: TJSONObject);
begin
  inherited MakeStepConfigJson(AToConfig);
  AToConfig.AddPair(TJSONPair.Create('db_title', FDBConTitle));
  AToConfig.AddPair(TJSONPair.Create('table_name', FTableName));
  AToConfig.AddPair(TJSONPair.Create('unique_key_fields', FUniqueKeyFields));
  AToConfig.AddPair(TJSONPair.Create('skip_exists', BoolToStr(FSkipExists)));
end;


procedure TStepJson2Table.ParseStepConfig(AConfigJsonStr: string);
begin
  inherited ParseStepConfig(AConfigJsonStr);
  FDBConTitle := GetJsonObjectValue(StepConfig.ConfigJson, 'db_title');
  FTableName := GetJsonObjectValue(StepConfig.ConfigJson, 'table_name');
  FUniqueKeyFields := GetJsonObjectValue(StepConfig.ConfigJson, 'unique_key_fields');
  FSkipExists := GetJsonObjectValue(StepConfig.ConfigJson, 'skip_exists');
end;


procedure TStepJson2Table.StartSelf;
var
  LQuery: TUniQuery;
  i: Integer;
  LParamName: string;
  LParamConfig: TJSONObject;
  LSqlParamsConfigJson: TJSONArray;
begin
  CheckTaskStatus;
  CoInitialize(nil);

  //��ȡ���ݿ�����
  LQuery := TUniQuery.Create(nil);
  try
    TaskVar.Logger.Debug(FormatLogMsg('��ȡ���ݿ����ӣ�' + FDBConTitle));

    LQuery.Connection := TaskVar.DbConMgr.GetDBConnection(FDBConTitle);
    if (LQuery.Connection.ProviderName = 'SQL Server')
        or (LQuery.Connection.ProviderName = 'MySQL')
        or (LQuery.Connection.ProviderName = 'PostgreSQL') then
    begin
      LQuery.SpecificOptions.Add('CommandTimeout=30');
    end;

    TaskVar.Logger.Debug(FormatLogMsg('SQL��' + FTableName));

    //��ȡSql���
    LQuery.SQL.Text := 'select * from ' + FTableName + ' where 1';

    //�����󶨲���
    if LQuery.ParamCount > 0 then
    begin
      try
        //���Σ�������������unique_key_fields�����ж�λ����



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
      LQuery.Open;
    except
      on E: Exception do
      begin
        TaskVar.Logger.Error('Query.Openִ���쳣��' + E.Message);
        StopExceptionRaise(E.Message);
      end;
    end;


    if LQuery.Active then
    begin
      FOutData.DataType := sdtText;
      FOutData.Data := UniQueryToJsonStr(LQuery);

      TaskVar.Logger.Debug(FormatLogMsg('Sql���гɹ�����¼����' + IntToStr(LQuery.RecordCount)));
    end
    else
      TaskVar.Logger.Debug(FormatLogMsg('Sql����ʧ��'));
  finally
    LQuery.Close;
    LQuery.Free;
    CoUninitialize;
  end;
end;



initialization
RegisterClass(TStepJson2Table);


finalization
UnRegisterClass(TStepJson2Table);




end.
