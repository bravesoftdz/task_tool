{
  TPCharSubModuleInfo, TPCharModuleInfo, TPCharRunInfo�е���Ϣ�ṹ���ܱ䶯,
  ����, �������޷�ʵ�ֶ�ģ��DLL�ĵ���

    ��Ȩ����-----------Dony Zhang @ VeryView.com.cn
    2009-12-5                                                   }

unit PublicInfoClass;

interface

uses
  Contnrs, Vcl.Controls, Vcl.Graphics, IniFiles, Windows, Messages, System.Classes, uFileLogger, System.SyncObjs;

type
  {*****************************************************************************
   1. ÿ����ģ�鴴��ʱ��Ҫ�Ĳ������Ӹýṹ��ȡ���������������Dll�е�
  ��ģ��ʱ��Dll���ݵĲ��������ü�¼�ṹ����ΪΪ�˹�����ģ����ģ
  ��ʱ���ܹ����ڴ��ϱ���һ�£��Ӷ��ܹ�����ģ��Ŀ��ٶ�λ��
   2. ��ģ���൱���������е�һ��Tabҳ��
   3. ��ģ������Զ����൱�ڸ��������е�Tabҳ�������ԵĶ��壻
   ****************************************************************************}
  TPCharSubModuleRec = record
//    OwnerID: Cardinal;     // ������ģ��ID����ģ������ർ�����еĶ�����
//    ID: Byte;              // ��ģ������ģ���е�ID��OwnerID + ID ��ϵͳ��Ψһ

    UniqueID: PChar;        // ������ʵȷ����ǰSubmodule��ÿ��SubModule����һ��ȫ��Ψһ��������

// ����Ҫ�������module��step����step��DesignForm

    Name: PChar;
    Caption: PChar;
    Hint: PChar;
    ShowDlg: WordBool;     // ����ʱ�Ƿ���Dlg��ģʽ��ʾ��TODO: ��ͳһȥ��������ģ������ʵ�������ʾ
    AllowMulti: WordBool;  // �Ƿ�ͬʱ��������ģ�����У�һ�����ĵ���Ӧ����ģ����
    InitBeforeCall: WordBool; // ÿ�ε���ǰ��ʼ����־
  end;

  {*****************************************************************************
  ��¼subModule��Ϣ, ����Dll���������ṩ����ģ��Ĳ���ʱ���ã�����
  ��TPCharSubModuleParams��¼�ṹ�ķ�װ�壬���ڷ����ڴ�Ĺ���ȷ��
  �ڴ汻��ȫ�ͷ�
  *****************************************************************************}
  TPCharSubModuleInfo=class
  private
    FSubModuleParams: TPCharSubModuleRec;
  public
    constructor Create(ASubModuleRec: TPCharSubModuleRec);
    property Name: PChar read FSubModuleParams.Name write FSubModuleParams.Name;
    property Caption: PChar read FSubModuleParams.Caption write FSubModuleParams.Caption;
    property Hint: PChar read FSubModuleParams.Hint write FSubModuleParams.Hint;
    property ShowDlg: WordBool read FSubModuleParams.ShowDlg write FSubModuleParams.ShowDlg;
    property AllowMulti: WordBool read FSubModuleParams.AllowMulti write FSubModuleParams.AllowMulti;
    property InitBeforeCall: WordBool read FSubModuleParams.InitBeforeCall write FSubModuleParams.InitBeforeCall;
  end;

  {*****************************************************************************
  ��¼Module��Ϣ, ����Dll���������ṩ����ģ��Ĳ���ʱ���ã�������
  ģ���е�������ģ�����Ϣ����PCharSubModuleInfo�Ĺ�����
  *****************************************************************************}
  TPCharModuleInfo=class
  private
    FName: PChar;
    FCaption: PChar;
    FHint: PChar;
    FID: Integer;
    //FNo: Integer; // ����ţ�����ģ��֮������򣬿�����
    FSubModuleList: TObjectList;
    function getSubModuleCount: Byte;
    procedure setSubModule(idx: Byte; const value: TPCharSubModuleInfo);
    function getSubModule(idx: Byte): TPCharSubModuleInfo;
  public
    constructor Create; overload;
    constructor Create(aID:Integer; aName, aCaption, aHint: PChar); overload;
    destructor Destroy; override;
    function Add(aPCharSubModuleInfo: TPCharSubModuleInfo): Integer;overload;
    function Add(ASubModuleRec: TPCharSubModuleRec):Integer;overload;
    property Name: PChar read FName write FName;
    property Caption: PChar read FCaption write FCaption;
    property Hint: PChar read FHint write FHint;
    property ID: Integer read FID write FID;
    property SubModuleCount: Byte read getSubModuleCount;
    property SubModules: TObjectList read FSubModuleList write FSubModuleList;
    property SubModule[idx: Byte]: TPCharSubModuleInfo read getSubModule
                               write setSubModule;
  end;


  {*****************************************************************************
  �Կ�dllģ���ȫ�ִ��ε���
  *****************************************************************************}
  TRunGlobalVar = class
    ExePath: PChar;
    FileLogger: TThreadFileLog;
    FileCritical: TCriticalSection;
  end;


  {*****************************************************************************
  ����ȫ�ֱ�������Щȫ�ֱ��������������в������ı���ߺ��ٷ����ı�
  *****************************************************************************}
  TRunInfo = class
  private
    //���²�����Ҫ�����ṩvcl�е���Ϣѭ�����ṩ��dll�д������������
    FApplication: Integer;
    FMainScreen: Integer;
    FMainForm: Integer;
    FMainFormHandle: THandle;

    //����ȫ�ֱ�������Ҫ������exe��dll�������ɷ�֮����д���
    //���磬���ݿ������ڲ�ͬdll��step�й���
    //���磬��־��������ڲ�ͬdll֮��Ĺ���
    //���磬�ṩȫ�ֵ�Ժ�Ӽ�������ȵ�
    FRunGlobalVar: Integer;
  public
    constructor Create(aApplication, aMainScreen, aMainForm, aRunGlobalVar: Integer;
                       aMainFormHandle: THandle);
    //
    property Application:Integer read FApplication;
    property MainScreen:Integer read FMainScreen;
    property MainForm:Integer read FMainForm write FMainForm;
    property MainFormHandle:THandle read FMainFormHandle;

    property __RUN_GLOBAL: Integer read FRunGlobalVar;
  end;


var
  //Dll��������Ҫ�еĿ��Ʊ���
  RunInfo: TRunInfo;

implementation

uses Vcl.Forms, SysUtils;

{ TPCharSubModuleInfo }

constructor TPCharSubModuleInfo.Create(ASubModuleRec: TPCharSubModuleRec);
begin
//  OwnerID:=ASubModuleRec.OwnerID;
//  ID:=ASubModuleRec.ID;
  Name:=ASubModuleRec.Name;
  Caption:=ASubModuleRec.Caption;
  Hint:=ASubModuleRec.Hint;
  ShowDlg := ASubModuleRec.ShowDlg;
  AllowMulti := ASubModuleRec.AllowMulti;
  InitBeforeCall := ASubModuleRec.InitBeforeCall;
end;


{ TPCharModuleInfo }

constructor TPCharModuleInfo.Create;
begin
  inherited Create;
  SubModules:=TObjectList.Create;
end;

constructor TPCharModuleInfo.Create(aID: Integer; aName, aCaption,
  aHint: PChar);
begin
  inherited Create;
  SubModules:=TObjectList.Create;
  FID:=aID;
  FName:=aName;
  FCaption:=aCaption;
  FHint:=aHint;
end;

destructor TPCharModuleInfo.Destroy;
begin
  SubModules.Clear;
  SubModules.Free;
  inherited;
end;

function TPCharModuleInfo.GetSubModule(idx: Byte): TPCharSubModuleInfo;
begin
  Result:=TPCharSubModuleInfo(FSubModuleList[idx]);
end;

procedure TPCharModuleInfo.setSubModule(idx: Byte;
  const value: TPCharSubModuleInfo);
begin
  FSubModuleList[idx]:=value;
end;

function TPCharModuleInfo.Add(aPCharSubModuleInfo: TPCharSubModuleInfo): Integer;
begin
  Result:=-1;
  if (aPCharSubModuleInfo<>nil) and (FSubModuleList.Count<255) then
  begin
    FSubModuleList.Add(aPCharSubModuleInfo);
    Result:=FSubModuleList.Count;
  end;
end;

function TPCharModuleInfo.Add(ASubModuleRec: TPCharSubModuleRec): Integer;
var
  aPCharSubModuleInfo: TPCharSubModuleInfo;
begin
  aPCharSubModuleInfo:=TPCharSubModuleInfo.Create(ASubModuleRec);
  Result:=Add(aPCharSubModuleInfo);
end;

function TPCharModuleInfo.getSubModuleCount: Byte;
begin
  Result:=FSubModuleList.Count;
end;



{ TRunInfo }

constructor TRunInfo.Create(aApplication, aMainScreen, aMainForm, aRunGlobalVar: Integer;
                       aMainFormHandle: THandle);
begin
  FApplication     := aApplication;
  FMainScreen      := aMainScreen;
  FMainForm        := aMainForm;
  FRunGlobalVar    := aRunGlobalVar;
end;

end.
