{
  TPCharSubModuleInfo, TPCharModuleInfo, TPCharRunInfo�е���Ϣ�ṹ���ܱ䶯,
  ����, �������޷�ʵ�ֶ�ģ��DLL�ĵ��ã����ļ���Ҫ���ڴ�͸����exe��dll���Լ�dll֮��
  �������ݵĴ���

    ��Ȩ����-----------Dony Zhang @ VeryView.com.cn
    2009-12-5                                                   }

unit uRunInfo;

interface

uses
  Contnrs, Vcl.Controls, Vcl.Graphics, IniFiles, Windows, Messages;

type
  TModuleStepRec = record
    DllNameSpace: string;

    StepId: Integer;
    StepName: string;

    Caption: string;
    Hint: string;
    StepClassName: string;
    StepDesignFormClassName: string;
  end;

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
    StepName: PChar;

    //������г��ֵ�һЩ����
    Caption: PChar;
    Hint: PChar;
    StepClassName: PChar;
    StepDesignFormClassName: PChar;
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


    //ִ���������
    FExePath: PChar;
    FAppLogger: Integer;
    FFileCritical: Integer;
    FStepMgr: Integer;
    FCurrentProject: Integer;
  public
    constructor Create(aApplication, aMainScreen, aMainForm: Integer; aMainFormHandle: THandle);
    destructor Destroy; override;


    procedure SetApplication(AApplication: Integer);
    procedure SetMainScreen(aMainScreen: Integer);
    procedure SetMainForm(aMainForm: Integer);
    procedure SetMainformHandle(aMainFormHandle: Integer);

    procedure SetExePath(AExePath: PChar);
    procedure SetStepMgr(AStepMgr: Integer);
    procedure SetAppLogger(AAppLogger: Integer);
    procedure SetFileCritical(AFileCritical: Integer);
    procedure SetCurrentProject(ACurrentProject: Integer);


    property Application:Integer read FApplication;
    property MainScreen:Integer read FMainScreen;
    property MainForm:Integer read FMainForm;
    property MainFormHandle:THandle read FMainFormHandle;

    //uDefines
    property ExePath: PChar read FExePath;
    property StepMgr: Integer read FStepMgr;
    property AppLogger: Integer read FAppLogger;
    property FileCritical: Integer read FFileCritical;

    //uDesignTimeDefines
    property CurrentProject: Integer read FCurrentProject;

  end;


  //�������õ��������ڲ��Ľṹ���ⲿ�Ĵ��νṹ֮������ݸ�ʽ��ת��
  function PCharStepRecToStepRec(ADllNameSpace: PChar; APCharStepRec: TPCharModuleStepRec): TModuleStepRec;
  function StepRecToPCharStepRec(AStepRec: TModuleStepRec): TPCharModuleStepRec;

var
  RunInfo: TRunInfo;

implementation

uses Vcl.Forms, SysUtils;

function PCharStepRecToStepRec(ADllNameSpace: PChar; APCharStepRec: TPCharModuleStepRec): TModuleStepRec;
begin
  Result.DllNameSpace := ADllNameSpace;
  Result.StepId := APCharStepRec.StepId;
  Result.StepName := APCharStepRec.StepName;
  Result.Caption := APCharStepRec.Caption;
  Result.StepClassName := APCharStepRec.StepClassName;
  Result.StepDesignFormClassName := APCharStepRec.StepDesignFormClassName;
end;


function StepRecToPCharStepRec(AStepRec: TModuleStepRec): TPCharModuleStepRec;
begin
  Result.StepId := AStepRec.StepId;
  Result.StepName := PChar(AStepRec.StepName);
  Result.Caption := PChar(AStepRec.Caption);
  Result.StepClassName := PChar(AStepRec.StepClassName);
  Result.StepDesignFormClassName := PChar(AStepRec.StepDesignFormClassName);
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

procedure TRunInfo.SetApplication(AApplication: Integer);
begin
  if FApplication = 0 then
    FApplication := AApplication;
end;

procedure TRunInfo.SetAppLogger(AAppLogger: Integer);
begin
  if FAppLogger = 0 then
    FAppLogger := AAppLogger;
end;

procedure TRunInfo.SetCurrentProject(ACurrentProject: Integer);
begin
  if FCurrentProject = 0 then
    FCurrentProject := ACurrentProject;
end;

procedure TRunInfo.SetExePath(AExePath: PChar);
begin
  if not Assigned(AExePath) then
    FExePath := AExePath;
end;

procedure TRunInfo.SetFileCritical(AFileCritical: Integer);
begin
  if FFileCritical = 0 then
    FFileCritical := AFileCritical;
end;

procedure TRunInfo.SetMainForm(aMainForm: Integer);
begin
  if FMainForm = 0 then
    FMainForm := aMainForm;
end;

procedure TRunInfo.SetMainformHandle(aMainFormHandle: Integer);
begin
  if FMainFormHandle = 0 then
    FMainFormHandle := aMainFormHandle;
end;

procedure TRunInfo.SetMainScreen(aMainScreen: Integer);
begin
  if FMainScreen = 0 then
    FMainScreen := aMainScreen;
end;

procedure TRunInfo.SetStepMgr(AStepMgr: Integer);
begin
  if FStepMgr = 0 then
    FStepMgr := AStepMgr;
end;

end.
