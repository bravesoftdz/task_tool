//ע�⣺����Ԫ�����������ʱ̬���ڸ������ϵĴ���
unit uProject;

interface

uses uGlobalVar;

type
  TProjectConfigRec = record
    ProjectName: string;
    RootPath: string;
    DbsFile: string;
    JobsFile: string;
  end;

  TProject = class
  private
  public
    ProjectName: string;
    RootPath: string;
    DbsFile: string;
    JobsFile: string;

    GlobalVar: TGlobalVar;

    constructor Create;
    destructor Destroy; override;

    procedure GetConfigFrom(APath: string);
  end;


implementation

uses System.SysUtils, System.Classes, System.JSON, uFunctions;

{ TProject }

constructor TProject.Create;
begin
  inherited;
  GlobalVar := TGlobalVar.Create;
end;


procedure TProject.GetConfigFrom(APath: string);
begin
  if not DirectoryExists(APath) then Exit;

  if APath[Length(APath)] <> '\' then
    APath := APath + '\';

  ProjectName := ExtractFileName(APath);
  RootPath := APath;
  DbsFile := APath + 'project.dbs';
  JobsFile := APath + 'project.jobs';

  GlobalVar.LoadFromFile(RootPath + 'project.global');
end;

destructor TProject.Destroy;
begin
  GlobalVar.Free;
  inherited;
end;

end.
