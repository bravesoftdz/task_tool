unit uDbConMgr;

interface

uses
  System.JSON, Uni, System.Classes;

type
  TDbConMgr = class
  private
    FDBConfigStr: string;
    FDBConfigsJson: TJSONArray;
    FDBConList: TStringList;
    function GetDBConfig(ADBTitle: string): TJSONObject;
    function GetDBConfigs: TJSONArray;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadDbConfigs(ADBsConfigFile: string);

    function GetDBTitles: string;
    function GetDBConnection(ADbTitle: string): TUniConnection;
    function CreateDBConnection(ADbTitle: string): TUniConnection;

    property DBConfigs: TJSONArray read GetDBConfigs;
  end;

implementation

uses uDefines, uFunctions, System.SysUtils, Winapi.ActiveX, AccessUniProvider, SQLServerUniProvider,
OracleUniProvider, MySQLUniProvider, SQLiteUniProvider, ODBCUniProvider, uThreadSafeFile;

{ TDbConMgr }

constructor TDbConMgr.Create;
begin
  inherited;
  FDBConList := TStringList.Create;
end;


destructor TDbConMgr.Destroy;
var
  i: Integer;
begin
  if FDBConfigsJson <> nil then
    FDBConfigsJson.Free;
  //�ͷ����е�uniconnection
  for i := 0 to FDBConList.Count - 1 do
  begin
    TUniConnection(FDBConList.Objects[i]).Disconnect;
    TUniConnection(FDBConList.Objects[i]).Free;
  end;

  FDBConList.Free;
  inherited;
end;


procedure TDbConMgr.LoadDbConfigs(ADBsConfigFile: string);
begin
  if FDBConfigsJson <> nil then
    FreeAndNil(FDBConfigsJson);

  FDBConfigStr := TThreadSafeFile.ReadContentFrom(ADBsConfigFile, '[]');
end;

function TDbConMgr.GetDBConfig(ADBTitle: string): TJSONObject;
var
  i: Integer;
  LDBConfigs: TJSONArray;
begin
  Result := nil;
  LDBConfigs := DBConfigs;
  AppLogger.Debug('��ȡ���ݿ����ã�' + ADBTitle);
  for i := 0 to LDBConfigs.Count - 1 do
  begin
    if (LDBConfigs.Items[i] as TJSONObject).GetValue('db_title').Value = ADBTitle then
    begin
      Result := (LDBConfigs.Items[i] as TJSONObject);
      if Result <> nil then
        AppLogger.Debug('��ȡ�����ݿ����ã�' + Result.ToString)
      else
        AppLogger.Debug('���ݿ�����Ϊ�գ�' + ADBTitle);
      Exit;
    end;
  end;
end;


function TDbConMgr.GetDBConfigs: TJSONArray;
begin
  if FDBConfigsJson = nil then
  begin
    FDBConfigsJson := TJSONObject.ParseJSONValue(FDBConfigStr) as TJSONArray;
    if FDBConfigsJson = nil then
      FDBConfigsJson := TJSONObject.ParseJSONValue('[]') as TJSONArray;
  end;
  Result := FDBConfigsJson;
end;


function TDbConMgr.GetDBConnection(ADbTitle: string): TUniConnection;
var
  LCon: TUniConnection;
  LDBConfig: TJSONObject;
begin
  Result := nil;
  LCon := nil;
  try
    //���ȴ�conlist��ƥ��
    if FDBConList.IndexOf(ADbTitle) = -1 then
    begin
      //��ȡ��Ӧ��json����
      LDBConfig := GetDBConfig(ADbTitle);
      if LDBConfig = nil then
      begin
        raise Exception.Create('DBList��δ�ҵ�DBConfig��' + FDBConfigsJson.ToString);
        Exit;
      end;

      AppLogger.Debug('����DbConnection��' + ADbTitle);
      LCon := TUniConnection.Create(nil);
      LCon.ConnectString := GetJsonObjectValue(LDBConfig, 'connection_str');
      LCon.Password := GetJsonObjectValue(LDBConfig, 'password');
      LCon.SpecificOptions.Text := GetJsonObjectValue(LDBConfig, 'specific_str');

      AppLogger.Debug('�������ӳأ�' + ADbTitle);
      LCon.Pooling := True;
      LCon.PoolingOptions.MaxPoolSize := 10;
      LCon.PoolingOptions.MinPoolSize := 1;
      LCon.PoolingOptions.ConnectionLifetime := 60000;
      AppLogger.Debug('�������ӳسɹ���' + ADbTitle);

      FDBConList.AddObject(ADbTitle, LCon);
      AppLogger.Debug('���DbConnection�����гɹ���' + ADbTitle);
    end
    else
    begin
      AppLogger.Debug('���б��л�ȡ���ݿ����ӣ�' + IntToStr(FDBConList.IndexOf(ADbTitle)));
      LCon := TUniConnection(FDBConList.Objects[FDBConList.IndexOf(ADbTitle)]);
    end;

  finally
    if LCon = nil then
      raise Exception.Create('���ݿ����ӻ�ȡʧ�ܣ�'+ADBTitle);

    Result := LCon;
  end;
end;


function TDbConMgr.CreateDBConnection(ADbTitle: string): TUniConnection;
var
  LCon: TUniConnection;
  LDBConfig: TJSONObject;
begin
  Result := nil;
  LCon := nil;
  try
    //��ȡ��Ӧ��json����
    LDBConfig := GetDBConfig(ADbTitle);
    if LDBConfig = nil then
    begin
      raise Exception.Create('DBList��δ�ҵ�DBConfig��' + FDBConfigsJson.ToString);
      Exit;
    end;

    LCon := TUniConnection.Create(nil);
    LCon.ConnectString := GetJsonObjectValue(LDBConfig, 'connection_str');
    LCon.Password := GetJsonObjectValue(LDBConfig, 'password');
    LCon.SpecificOptions.Text := GetJsonObjectValue(LDBConfig, 'specific_str');
    LCon.Pooling := True;
    LCon.PoolingOptions.MaxPoolSize := 10;
    LCon.PoolingOptions.MinPoolSize := 1;
    LCon.PoolingOptions.ConnectionLifetime := 60000;

  finally
    if LCon = nil then
      raise Exception.Create('���ݿ�����Connection��ȡʧ�ܣ�'+ADBTitle);

    Result := LCon;
  end;
end;


//�����ö��Ÿ�����comma-text
function TDbConMgr.GetDBTitles: string;
var
  i: Integer;
  LDBConfigs: TJSONArray;
begin
  Result := '';
  LDBConfigs := DBConfigs;
  if LDBConfigs = nil then Exit;
  for i := 0 to LDBConfigs.Count - 1 do
  begin
    if Result = '' then
      Result := (LDBConfigs.Items[i] as TJSONObject).GetValue('db_title').Value
    else
      Result := Result + ',' + (LDBConfigs.Items[i] as TJSONObject).GetValue('db_title').Value;
  end;
end;

initialization
CoInitialize(nil);

finalization
CoUninitialize;

end.
