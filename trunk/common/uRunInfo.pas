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
    FStepMgr: Integer;


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

    property StepMgr: Integer read FStepMgr;

    property ThemeStyle: Byte read FThemeStyle write FThemeStyle;
    property ConfigFile: TIniFile read FConfigFile write FConfigFile;
    property Debug: Integer read FDebug write FDebug;
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
end;


function StepRecToPCharStepRec(AStepRec: TModuleStepRec): TPCharModuleStepRec;
begin
  Result.StepId := AStepRec.StepId;
  Result.StepName := PChar(AStepRec.StepName);
  Result.Caption := PChar(AStepRec.Caption);
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
