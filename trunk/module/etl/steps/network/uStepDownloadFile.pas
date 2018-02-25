unit uStepDownloadFile;

interface

uses
  uStepBasic, System.JSON;

type
  TStepDownloadFile = class (TStepBasic)
  private
    FSrcFileUrl: string;
    FSaveToPath: string;
    function UrlDownloadFile(AFromUrl, AToFile: string): Boolean;
  protected
    procedure StartSelf; override;
  public
    procedure ParseStepConfig(AConfigJsonStr: string); override;
    procedure MakeStepConfigJson(var AToConfig: TJSONObject); override;

    property SrcFileUrl: string read FSrcFileUrl write FSrcFileUrl;
    property SaveToPath: string read FSaveToPath write FSaveToPath;
  end;

implementation

uses
  uDefines, uFunctions, System.Classes, System.SysUtils, uExceptions, uTask,
  uStepDefines, System.Net.HttpClient;

{ TStepQuery }

procedure TStepDownloadFile.MakeStepConfigJson(var AToConfig: TJSONObject);
begin
  inherited MakeStepConfigJson(AToConfig);
  AToConfig.AddPair(TJSONPair.Create('src_file_url', FSrcFileUrl));
  AToConfig.AddPair(TJSONPair.Create('save_to_path', FSaveToPath));
end;


procedure TStepDownloadFile.ParseStepConfig(AConfigJsonStr: string);
begin
  inherited ParseStepConfig(AConfigJsonStr);
  FSrcFileUrl := GetJsonObjectValue(StepConfig.ConfigJson, 'src_file_url');
  FSaveToPath := GetJsonObjectValue(StepConfig.ConfigJson, 'save_to_path');
end;


procedure TStepDownloadFile.StartSelf;
var
  LFileName, LTargetFile, LSrcFileUrl: string;
begin
  try
    CheckTaskStatus;

    LSrcFileUrl := GetParamValue(FSrcFileUrl, 'string', FSrcFileUrl);
    LFileName := ExtractFileName(LSrcFileUrl);
    LTargetFile := GetRealAbsolutePath(FSaveToPath) + LFileName;

    //���������ļ�
    LogMsg('��ʼ�����ļ���' + LSrcFileUrl);
    if not UrlDownloadFile(FSrcFileUrl, LTargetFile) then
    begin
      StopExceptionRaise('�����ļ�ʧ��');
    end
    else
    begin
      //������浽���ص��ļ�����
      FOutData.Data := LTargetFile;
    end;
  finally

  end;
end;

//
function TStepDownloadFile.UrlDownloadFile(AFromUrl: string; AToFile: string): Boolean;
var
  LHttpClient: THTTPClient;
  LStream: TMemoryStream;
begin
  Result := False;
  LHttpClient := THTTPClient.Create;
  LStream := TMemoryStream.Create;
  try
    LHttpClient.Get(AFromUrl, LStream);
    LStream.SaveToFile(AToFile);
    Result := True;
  finally
    LStream.Free;
    LHttpClient.Free;
  end;
end;


initialization
RegisterClass(TStepDownloadFile);

finalization
UnRegisterClass(TStepDownloadFile);

end.
