{
  TPCharSubModuleInfo, TPCharModuleInfo, TPCharRunInfo�е���Ϣ�ṹ���ܱ䶯,
  ����, �������޷�ʵ�ֶ�ģ��DLL�ĵ���

    ��Ȩ����-----------Dony Zhang @ VeryView.com.cn
    2009-12-5                                                   }

unit PublicInfoClass;

interface

uses
  Contnrs, Vcl.Controls, Vcl.Graphics, IniFiles, Windows, Messages;

type
  {*****************************************************************************
   1. ÿ����ģ�鴴��ʱ��Ҫ�Ĳ������Ӹýṹ��ȡ���������������Dll�е�
  ��ģ��ʱ��Dll���ݵĲ��������ü�¼�ṹ����ΪΪ�˹�����ģ����ģ
  ��ʱ���ܹ����ڴ��ϱ���һ�£��Ӷ��ܹ�����ģ��Ŀ��ٶ�λ��
   2. ��ģ���൱���������е�һ��Tabҳ��
   3. ��ģ������Զ����൱�ڸ��������е�Tabҳ�������ԵĶ��壻
   ****************************************************************************}
  TPCharModuleStepRec = record
    //����Step�Ľṹ������
    StepId: Integer;

    //������г��ֵ�һЩ����
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
  TPCharModuleStepInfo=class
  private
    FModuleStepRec: TPCharModuleStepRec;
  public
    constructor Create(aName,aCaption,aHint: PChar;
                        aShowDlg: WordBool=True; aAllowMulti: WordBool=False;
                        aInitBeforeCall: WordBool=True);
    property Name: PChar read FModuleStepRec.Name write FModuleStepRec.Name;
    property Caption: PChar read FModuleStepRec.Caption write FModuleStepRec.Caption;
    property Hint: PChar read FModuleStepRec.Hint write FModuleStepRec.Hint;
    property ShowDlg: WordBool read FModuleStepRec.ShowDlg write FModuleStepRec.ShowDlg;
    property AllowMulti: WordBool read FModuleStepRec.AllowMulti write FModuleStepRec.AllowMulti;
    property InitBeforeCall: WordBool read FModuleStepRec.InitBeforeCall write FModuleStepRec.InitBeforeCall;
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
    FNo: Integer; // ����ţ�����ģ��֮������򣬿�����
    FModuleStepList: TObjectList;
    function getSubModuleCount: Byte;
    procedure setModuleStep(idx: Byte; const value: TPCharModuleStepInfo);
    function getModuleStep(idx: Byte): TPCharModuleStepInfo;
  public
    constructor Create; overload;
    constructor Create(aName, aCaption, aHint: PChar); overload;
    destructor Destroy; override;
    function Add(aPCharModuleStepInfo: TPCharModuleStepInfo): Integer;overload;
    function Add(aName,aCaption,aHint: PChar;
                        aShowDlg: WordBool=True; aAllowMulti: WordBool=True;
                        aInitBeforeCall: WordBool=True):Integer;overload;
    property Name: PChar read FName write FName;
    property Caption: PChar read FCaption write FCaption;
    property Hint: PChar read FHint write FHint;
    property ModuleStepCount: Byte read getSubModuleCount;
    property ModuleSteps: TObjectList read FModuleStepList write FModuleStepList;
    property ModuleStep[idx: Byte]: TPCharModuleStepInfo read getModuleStep
                               write setModuleStep;
  end;


  {*****************************************************************************
  ����ȫ�ֱ�������Щȫ�ֱ��������������в������ı���ߺ��ٷ����ı�
  *****************************************************************************}
  TRunInfo = class
  private
    FApplication: Integer;
    FMainScreen: Integer;
    FMainForm: Integer;
    FMainFormHandle: THandle;

    FThemeStyle: Byte;
    FConfigFile: TiniFile;
    FDebug: Integer;  // �洢VVDebug
  public
    constructor Create(aApplication, aMainScreen, aMainForm: Integer; aMainFormHandle: THandle);
    destructor Destroy; override;
    property Application:Integer read FApplication;
    property MainScreen:Integer read FMainScreen;
    property MainForm:Integer read FMainForm write FMainForm;
    property MainFormHandle:THandle read FMainFormHandle;

    property ThemeStyle: Byte read FThemeStyle write FThemeStyle;
    property ConfigFile: TIniFile read FConfigFile write FConfigFile;
    property Debug: Integer read FDebug write FDebug;
  end;


var
  RunInfo: TRunInfo;

implementation

uses Vcl.Forms, SysUtils;

{ TPCharSubModuleInfo }

constructor TPCharModuleStepInfo.Create(
  aName, aCaption, aHint: PChar; aShowDlg, aAllowMulti,
  aInitBeforeCall: WordBool);
begin
  Name:=aName;
  Caption:=aCaption;
  Hint:=aHint;
  ShowDlg := aShowDlg;
  AllowMulti := aAllowMulti;
  InitBeforeCall := aInitBeforeCall;
end;


{ TPCharModuleInfo }

constructor TPCharModuleInfo.Create;
begin
  inherited Create;
  ModuleSteps:=TObjectList.Create;
end;

constructor TPCharModuleInfo.Create(aName, aCaption, aHint: PChar);
begin
  inherited Create;
  ModuleSteps:=TObjectList.Create;
  FName:=aName;
  FCaption:=aCaption;
  FHint:=aHint;
end;

destructor TPCharModuleInfo.Destroy;
begin
  ModuleSteps.Clear;
  ModuleSteps.Free;
  inherited;
end;

function TPCharModuleInfo.GetModuleStep(idx: Byte): TPCharModuleStepInfo;
begin
  Result:=TPCharModuleStepInfo(FModuleStepList[idx]);
end;

procedure TPCharModuleInfo.setModuleStep(idx: Byte;
  const value: TPCharModuleStepInfo);
begin
  FModuleStepList[idx]:=value;
end;

function TPCharModuleInfo.Add(aPCharModuleStepInfo: TPCharModuleStepInfo): Integer;
begin
  Result:=-1;
  if (aPCharModuleStepInfo<>nil) and (FModuleStepList.Count<255) then
  begin
    FModuleStepList.Add(aPCharModuleStepInfo);
    Result:=FModuleStepList.Count;
  end;
end;

function TPCharModuleInfo.Add(aName,
  aCaption, aHint: PChar; aShowDlg, aAllowMulti, aInitBeforeCall: WordBool): Integer;
var
  aPCharModuleStepInfo: TPCharModuleStepInfo;
begin
  aPCharModuleStepInfo:=TPCharModuleStepInfo.Create(aName,aCaption,aHint,
                         aShowDlg,aAllowMulti,aInitBeforeCall);
  Result:=Add(aPCharModuleStepInfo);
end;

function TPCharModuleInfo.getSubModuleCount: Byte;
begin
  Result:=FModuleStepList.Count;
end;



{ TRunInfo }

constructor TRunInfo.Create(aApplication, aMainScreen, aMainForm: Integer; aMainFormHandle: THandle);
begin
  FApplication     := aApplication;
  FMainScreen      := aMainScreen;
  FMainForm        := aMainForm;
  FMainFormHandle  := aMainFormHandle;
end;


destructor TRunInfo.Destroy;
begin
  inherited;
end;

end.
