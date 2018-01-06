unit uServiceUtil;

interface

uses Windows, Messages, SysUtils, Winsvc, Dialogs;

type

  TServiceUtil = class
  public
    class function StartServices(Const sServiceName: String): Boolean; static;
    class function StopServices(Const sServiceName: String): Boolean; static;
    class function QueryServiceStatusStr(Const SvrName: String): String; static;
    class function InstallServices(Const SvrName, ADisplayName, FilePath: String): Boolean; static;
    class function UnInstallServices(Const SvrName: String): Boolean; static;
  end;

implementation

// ��������
class function TServiceUtil.StartServices(const sServiceName: String): Boolean;//����ĳ������
var
  schService:SC_HANDLE;
  schSCManager:SC_HANDLE;
  Argv:PChar;
begin
  Result := False;
  schSCManager:=OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if schSCManager > 0 then
  begin
    try
      schService:=OpenService(schSCManager,Pchar(sServiceName),SERVICE_ALL_ACCESS);
      if schService > 0 then
      try
        Result := StartService(schService,0,Argv);
      finally
        CloseServiceHandle(schService);
      end;
    finally
      CloseServiceHandle(schSCManager);
    end;
  end;
end;

// ֹͣ����
class function TServiceUtil.StopServices(const sServiceName:String): Boolean;//ֹͣĳ������
var
  schService:SC_HANDLE;
  schSCManager:SC_HANDLE;
  ssStatus: TServiceStatus;
begin
  Result := False;
  schSCManager:=OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if schSCManager > 0 then
  begin
    try
      schService:=OpenService(schSCManager,Pchar(sServiceName),SERVICE_ALL_ACCESS);
      if schService > 0 then
      try
        Result := ControlService(schService,SERVICE_CONTROL_STOP,ssStatus);
      finally
        CloseServiceHandle(schService);
      end;
    finally
      CloseServiceHandle(schSCManager);
    end;
  end;
end;


// ��ѯ��ǰ�����״̬
class function TServiceUtil.QueryServiceStatusStr(Const SvrName: String): String;
var
  hService, hSCManager: SC_HANDLE;
  SS: TServiceStatus;
begin
  hSCManager := OpenSCManager(nil, SERVICES_ACTIVE_DATABASE, SC_MANAGER_CONNECT);
  if hSCManager = 0 then
  begin
    result := 'Can not open the service control manager';
    exit;
  end;
  hService := OpenService(hSCManager, PChar(SvrName), SERVICE_QUERY_STATUS);
  if hService = 0 then
  begin
    CloseServiceHandle(hSCManager);
    result := 'δ��װ';
    exit;
  end;
  try
    if not QueryServiceStatus(hService, SS) then
      result := '�޷���ѯ����״̬'
    else
    begin
      case SS.dwCurrentState of
        SERVICE_CONTINUE_PENDING:
          result := '��������';
        SERVICE_PAUSE_PENDING:
          result := '������ͣ';
        SERVICE_PAUSED:
          result := '����ͣ';
        SERVICE_RUNNING:
          result := '������';
        SERVICE_START_PENDING:
          result := '��������';
        SERVICE_STOP_PENDING:
          result := '����ֹͣ';
        SERVICE_STOPPED:
          result := '��ֹͣ';
      else
        result := 'δ֪״̬';
      end;
    end;
  finally
    CloseServiceHandle(hSCManager);
    CloseServiceHandle(hService);
  end;
end;



{ �������� }
class function TServiceUtil.InstallServices(Const SvrName, ADisplayName, FilePath: String): Boolean;
var
  a, b: SC_HANDLE;
begin
  Result := False;
  if not FileExists(FilePath) then Exit;

  a := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if a <= 0 then Exit;

  try
    b := CreateService(a, PChar(SvrName), PChar(ADisplayName), SERVICE_ALL_ACCESS,
      SERVICE_INTERACTIVE_PROCESS or SERVICE_WIN32_OWN_PROCESS,
      SERVICE_AUTO_START, SERVICE_ERROR_NORMAL, PChar(FilePath), nil, nil, nil,
      nil, nil);
    if b <= 0 then
    begin
      raise Exception.Create(SysErrorMessage(GetlastError));
    end;

    CloseServiceHandle(b);
    Result := True;
  except
    CloseServiceHandle(a);
  end;
end;



{ ж�ط��� }
class function TServiceUtil.UnInstallServices(Const SvrName: String): Boolean;
var
  a, b: SC_HANDLE;
begin
  Result := False;
  a := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if a <= 0 then Exit;

  try
    b := OpenService(a, PChar(SvrName), STANDARD_RIGHTS_REQUIRED);
    if b > 0 then
    try
      Result := DeleteService(b);
      if not Result then
        raise Exception.Create(SysErrorMessage(GetlastError));
    finally
      CloseServiceHandle(b);
    end;
  finally
    closeServiceHandle(a);
  end;
end;

end.
