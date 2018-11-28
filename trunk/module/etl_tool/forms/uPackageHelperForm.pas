unit uPackageHelperForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uBasicForm, Vcl.StdCtrls, Vcl.Buttons;

type
  TPackageHelperForm = class(TBasicForm)
    btnCleanLog: TBitBtn;
    btnRenameInit: TBitBtn;
    procedure btnCleanLogClick(Sender: TObject);
    procedure btnRenameInitClick(Sender: TObject);
  private
    procedure OnLogFolderFound(AFolderName: string; var ARecursive: Boolean; AFinder: TObject);
    procedure OnInitFileFound(AFileName: string; AFinder: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PackageHelperForm: TPackageHelperForm;

implementation

uses uFileFinder, uDefines, uFileUtil;

{$R *.dfm}

procedure TPackageHelperForm.OnInitFileFound(AFileName: string; AFinder: TObject);
var
  LToFileName, LFileName: string;
begin
  //�ж��ļ����Ƿ�Ϊglobal����dbs������ǣ���ֱ�����Ӧ���ļ���������ղ�����
  //ͬʱ����������������key fields
  LFileName := ExtractFileName(AFileName);
  LToFileName := AFileName + '.init';
  if LFileName = 'project.global' then
  begin
    //ȫ�ֲ�������json�ֶε����Խ��д�����Ĭ��ֵ��ȫ��գ�������Ҫ����Ĭ��ֵ
    TFileUtil.DeleteFile(LToFileName);
    TFileUtil.RenameFile(AFileName, LToFileName);
  end
  else if LFileName = 'project.dbs' then
  begin
    //���ݿ�ȫ���
    TFileUtil.DeleteFile(LToFileName);
    TFileUtil.RenameFile(AFileName, LToFileName);
  end;
end;

procedure TPackageHelperForm.btnRenameInitClick(Sender: TObject);
var
  LFileFinder: TVVFileFinder;
begin
  inherited;
  LFileFinder := TVVFileFinder.Create;
  try
    LFileFinder.Dir := ExePath;
    LFileFinder.Recursive := True;
    LFileFinder.OnFileFound := OnInitFileFound;
    LFileFinder.Find;
  finally
    LFileFinder.Free;
  end;
end;




procedure TPackageHelperForm.OnLogFolderFound(AFolderName: string; var ARecursive: Boolean; AFinder: TObject);
var
  LDirName: string;
begin
  LDirName := TVVFileFinder(AFinder).CurrentName;
  //�ж��ļ����Ƿ�Ϊlog����task_log������ǣ���ֱ�ӽ�������ļ��м���
  if (LDirName = 'log') or (LDirName = 'task_log') then
  begin
    ARecursive := False;
    TFileUtil.DeleteDir(AFolderName);
    TFileUtil.CreateDir(AFolderName);
  end;
end;

procedure TPackageHelperForm.btnCleanLogClick(Sender: TObject);
var
  LFileFinder: TVVFileFinder;
begin
  inherited;
  LFileFinder := TVVFileFinder.Create;
  try
    LFileFinder.Dir := ExePath;
    LFileFinder.Recursive := True;
    LFileFinder.OnFolderFound := OnLogFolderFound;
    LFileFinder.Find;
  finally
    LFileFinder.Free;
  end;

end;

end.
