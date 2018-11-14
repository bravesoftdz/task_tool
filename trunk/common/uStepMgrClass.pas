{$A8,B-,C+,D+,E-,F-,G+,H+,I+,J-,K-,L+,M-,N-,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$MINSTACKSIZE $00004000}
{$MAXSTACKSIZE $00100000}
{$IMAGEBASE $00400000}
{$APPTYPE GUI}
{$WARN SYMBOL_DEPRECATED ON}
{$WARN SYMBOL_LIBRARY ON}
{$WARN SYMBOL_PLATFORM ON}
{$WARN SYMBOL_EXPERIMENTAL ON}
{$WARN unit_LIBRARY ON}
{$WARN unit_PLATFORM ON}
{$WARN unit_DEPRECATED ON}
{$WARN unit_EXPERIMENTAL ON}
{$WARN HRESULT_COMPAT ON}
{$WARN HIDING_MEMBER ON}
{$WARN HIDDEN_VIRTUAL ON}
{$WARN GARBAGE ON}
{$WARN BOUNDS_ERROR ON}
{$WARN ZERO_NIL_COMPAT ON}
{$WARN STRING_CONST_TRUNCED ON}
{$WARN FOR_LOOP_VAR_VARPAR ON}
{$WARN TYPED_CONST_VARPAR ON}
{$WARN ASG_TO_TYPED_CONST ON}
{$WARN CASE_LABEL_RANGE ON}
{$WARN FOR_VARIABLE ON}
{$WARN CONSTRUCTING_ABSTRACT ON}
{$WARN COMPARISON_FALSE ON}
{$WARN COMPARISON_TRUE ON}
{$WARN COMPARING_SIGNED_UNSIGNED ON}
{$WARN COMBINING_SIGNED_UNSIGNED ON}
{$WARN UNSUPPORTED_CONSTRUCT ON}
{$WARN FILE_OPEN ON}
{$WARN FILE_OPEN_unitSRC ON}
{$WARN BAD_GLOBAL_SYMBOL ON}
{$WARN DUPLICATE_CTOR_DTOR ON}
{$WARN INVALID_DIRECTIVE ON}
{$WARN PACKAGE_NO_LINK ON}
{$WARN PACKAGED_THREADVAR ON}
{$WARN IMPLICIT_IMPORT ON}
{$WARN HPPEMIT_IGNORED ON}
{$WARN NO_RETVAL ON}
{$WARN USE_BEFORE_DEF ON}
{$WARN FOR_LOOP_VAR_UNDEF ON}
{$WARN unit_NAME_MISMATCH ON}
{$WARN NO_CFG_FILE_FOUND ON}
{$WARN IMPLICIT_VARIANTS ON}
{$WARN UNICODE_TO_LOCALE ON}
{$WARN LOCALE_TO_UNICODE ON}
{$WARN IMAGEBASE_MULTIPLE ON}
{$WARN SUSPICIOUS_TYPECAST ON}
{$WARN PRIVATE_PROPACCESSOR ON}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN OPTION_TRUNCATED ON}
{$WARN WIDECHAR_REDUCED ON}
{$WARN DUPLICATES_IGNORED ON}
{$WARN unit_INIT_SEQ ON}
{$WARN LOCAL_PINVOKE ON}
{$WARN MESSAGE_DIRECTIVE ON}
{$WARN TYPEINFO_IMPLICITLY_ADDED ON}
{$WARN RLINK_WARNING ON}
{$WARN IMPLICIT_STRING_CAST ON}
{$WARN IMPLICIT_STRING_CAST_LOSS ON}
{$WARN EXPLICIT_STRING_CAST OFF}
{$WARN EXPLICIT_STRING_CAST_LOSS OFF}
{$WARN CVT_WCHAR_TO_ACHAR ON}
{$WARN CVT_NARROWING_STRING_LOST ON}
{$WARN CVT_ACHAR_TO_WCHAR OFF}
{$WARN CVT_WIDENING_STRING_LOST OFF}
{$WARN XML_WHITESPACE_NOT_ALLOWED ON}
{$WARN XML_UNKNOWN_ENTITY ON}
{$WARN XML_INVALID_NAME_START ON}
{$WARN XML_INVALID_NAME ON}
{$WARN XML_EXPECTED_CHARACTER ON}
{$WARN XML_CREF_NO_RESOLVE ON}
{$WARN XML_NO_PARM ON}
{$WARN XML_NO_MATCHING_PARM ON}
{Modules, ModuleSteps��������ֱ�ӹ���
 Module[ModuleID], ModuleStep[FullID]����ģ��ID���й���}

unit uStepMgrClass;

interface

uses
  uRunInfo, Contnrs, Classes, System.JSON, uStepBasic, uStepBasicForm;

type
  TRunDllInfo = class
  private
    FStepEntryPointer: Pointer;
    FStepDesignFormEntryPointer: Pointer;
    function GetStepDesignFormEntryPointer: Pointer;
    function GetStepEntryPointer: Pointer;
  public
    FilePath: string;
    DllName: string;
    DllNameSpace: string;

    DllHandle: THandle;
    constructor Create;
    destructor Destroy; override;

    function GetStep(AStepRec: TModuleStepRec): TStepBasic;
    function GetStepDesignForm(AStepRec: TModuleStepRec): TStepBasicForm;
  end;

  //ÿ��step���Լ����ڵ�namespace���Ӷ��Բ�ͬ��namespace�Ŀ������Ч������
  TStepMgr = class
  private
    FModuleSteps: TJSONObject;

    FRunDllList: TStringList;

    function AddRunDll(ANameSpace: string): Integer;
    function RemoveRunDll(ANameSpace): Boolean;
    function GetRunDll(ANameSpace: string): TRunDllInfo;
    function ClearRunDll: Boolean;
  public 
    constructor Create;
    destructor Destroy; override;

    //��ȡ��ƽ׶ε�����step�����moduleStepsΪ�գ�����Ҫɨ�����е�ע���dll
    function GetDesigningSteps: string;

    function GetStep(AStepRec: TModuleStepRec): string;

    function GetStepDesignForm(AStepRec: TModuleStepRec): string;

    //ע�����е�steps����ʵ�������ṩ�˶��ⲿ��ƽ׶ν���step���ṩ��������ƽ׶��ṩ����Щdll
    //��ô��һ��project������Щnamespace/dllҲ����Ҫ��project��Ӧ���ļ��н�������˵����ͬ����
    //һ��task�ڼ���һ���µ�step��step����Ӧ��namespaceҲ��Ҫ��task�����ļ��н��д�����taskɾ����
    //Ҳ��Ҫ��һ������ɨ�衣Ҳ����˵��һ��taskҪ���ڲ����������step����������������������������ǲ���
    //�������ʽʵ�ֵģ�ͬ����һ��project�������Ҫ�����namespace�������Զ� project�и���task�������
    //namespace��һ�����ϡ�project������ȷ����namespace����������ƹ����п���ͨ����task�ķ�������ʵ��
    //����������namespace�Ĵ������ҿ��Ժܷ���Ŀ�����ÿ��namespace����Щtask��ʹ��

    //dllͨ�����ذ����е�Stepע�뵽���л����У�����ƾ�ͨ�����������ṩ���п���ʹ�õ�step�������н׶Σ�
    //��ʵ��û��ʵ�����壬��Ϊ��ϵͳ����ʱ��ͨ��task�ű��е�fullId������ֱ��ÿ��Step��Ӧ��namespace��
    //namespace alias�ȣ�ͨ��namespaceֱ�ӹ�������Ӧ��dll�ļ���Ȼ��ֱ�ӵ��ö�Ӧ��step����stepform���ɣ�
    {*
    ��dll�����ڲ���step�ṹ��stepId����Ӧ��������ɣ�Ҳ��������ָ���Ĵ��룬��ˣ�Ψһ��dll����ע�ᣬ
    ʵ����ֻ��Ҫע��namespace�����н׶θ����Ͳ���Ҫstep��ע����Ϣ�Ĳ���
    ��ˣ������Խ�һ�������Ż�������dll����ƽ׶ζ�������һ��ͬ����abc.dll.config������ļ����ڶ���
    �ڲ���step����˵��������������й��촦������һ��������designForm�����Դ�����ʱ��dll�н��а��룬
    �Ӷ�ʹ��ÿ������ʱ�İ���С������Ҳ��������й¶���ͻ�����ô��ÿ��Dll������Ϊһ�������������������ʱ��
    ���ʱ�������⼸�����֡����������ÿ��dll���м��ء����ʱ�ļ��ػ���Ҫ���ʱ���������������֡�
    �������ʱ��ֻ��Ҫ���ط���ʱ��dll���ɡ���Ȼ��Ҳ����ͨ������ָ����벻ͬ�汾��dll���򻯶��ļ��Ĺ���
    ��ˣ�Ŀǰ���ٿ���ͨ�������ļ���һ���ļ�������abc.dll.config��������namespace, steps�����ã���
    ��һ���ļ���������abc.dll��������ͨ��ע�������abc.dll.config���ض�Ӧ��ģ�顣���г�������ֱ��ֻ��
    abc.dll��Ӧ�������ռ����ע�ἴ�ɡ���������ʱ�������˶�Ӧ�����ռ��Step����ֱ�Ӱ���Ӧ��step��������Ϣ
    ���͸���Ӧ��dll�����ɡ����г��򲢲����step������ĸ��洦��
    ���������ɨ������ע�������abc.dll.config�����ʱ����ȡ��Ӧ��step������Ȼ����dll����
    ���г�����Ը�����Ŀ����������������г��������������ض�Ӧ��dll��Ȼ���ڽ���taskʱ��������Ӧ��step��
    ���step����������Ӧ��dll����
    ����
    *}
  end;


implementation

uses
  Windows, SysUtils, uRunInfo;


{ TRunDllInfo }

constructor TRunDllInfo.Create;
begin
  FStepEntryPointer := nil;
  FStepDesignFormEntryPointer := nil;
end;

destructor TRunDllInfo.Destroy;
begin
  if DllHandle <> 0 then
  begin
    FreeLibrary(DllHandle);
  end;
  inherited;
end;


function TRunDllInfo.GetStep(AStepRec: TModuleStepRec): TStepBasic;
type
  TGetStepFunc = function (ARunInfo: TRunInfo; APCharModuleStepRec: TPCharModuleStepRec): TStepBasic; stdcall;
var
  LEntryPointer: Pointer;
begin
  //����ʵ�ʵĵ���
  Result := nil;
  LEntryPointer := GetStepEntryPointer;
  if LEntryPointer = nil then Exit;

  Result := TGetStepFunc(LEntryPointer)(RunInfo, );
end;

function TRunDllInfo.GetStepDesignForm(AStepRec: TModuleStepRec): TStepBasicForm;
type
  TGetStepDesignFormFunc = function (ARunInfo: TRunInfo; APCharModuleStepRec: TPCharModuleStepRec): TStepBasic; stdcall;
var
  LEntryPointer: Pointer;
begin
  //����ʵ�ʵĵ���
  Result := nil;
  LEntryPointer := GetStepDesignFormEntryPointer;
  if LEntryPointer = nil then Exit;

  Result := TGetStepDesignFormFunc(LEntryPointer)(RunInfo, );
end;

function TRunDllInfo.GetStepDesignFormEntryPointer: Pointer;
begin
  if FStepDesignFormEntryPointer = nil then
  begin
    FStepDesignFormEntryPointer := GetProcAddress(DllHandle, 'ModuleStepDesignForm');
  end;
  Result := FStepDesignFormEntryPointer;
end;

function TRunDllInfo.GetStepEntryPointer: Pointer;
begin
  if FStepEntryPointer = nil then
  begin
    FStepEntryPointer := GetProcAddress(DllHandle, 'ModuleStep');
  end;
  Result := FStepEntryPointer;
end;

{ TStepMgr }

function TStepMgr.AddRunDll(ANameSpace: string): Integer;
begin
  Result := FRunDllList.IndexOfName(ANameSpace);
  //�鿴�Ƿ������ANameSpace��������ڣ����ֱ�ӷ���
  if Result = -1 then
  begin
    //����ANameSpace����ָ���dll�ļ�

    //�ļ������ڣ���Ĭ��Ϊ��ǰ·�� + steps/ + namespace.dll

    //����dll

  end;

end;

function TStepMgr.RemoveRunDll(ANameSpace): Boolean;
var
  idx: Integer;
  LRunDllObj: TObject;
begin
  Result := False;
  idx := FRunDllList.IndexOfName(ANameSpace);
  if idx = -1 then Result := True;

  LRunDllObj := FRunDllList.Objects[idx];
  if LRunDllObj <> nil then
  begin
    TRunDllInfo(LRunDllObj).Free;
  end;
  FRunDllList.Delete(idx);
end;


function TStepMgr.ClearRunDll: Boolean;
var
  idx: Integer;
  LRunDllObj: TObject;
begin
  for idx := FRunDllList.Count - 1 downto 0 do
  begin
    LRunDllObj := TRunDllInfo(FRunDllList.Objects[idx]);
    if LRunDllObj <> nil then
    begin
      LRunDllObj.Free;
    end;
    FRunDllList.Delete(idx);
  end;
end;

function TStepMgr.GetRunDll(ANameSpace: string): TRunDllInfo;
var
  idx: Integer;
begin
  Result := nil;
  idx := FRunDllList.IndexOfName(ANameSpace);
  if idx = -1 then
  begin
    idx := AddRunDll(ANameSpace);
  end;
  if idx = -1 then Exit;

  Result := TRunDllInfo(FRunDllList.Objects[idx]);
end;

constructor TStepMgr.Create;
begin
  FRunDllList := TStringList.Create(False);
end;

destructor TStepMgr.Destroy;
begin
  if FModuleSteps <> nil then
    FModuleSteps.Free;
  ClearRunDll;
  FRunDllList.Free;
  inherited;
end;


{*
����������ƽ׶�ִ��
*}
function TStepMgr.GetDesigningSteps: string;
begin
  if FModuleSteps = nil then
  begin
    FModuleSteps := TJSONObject.Create;
    //���α������е�dll

  end;
  Result := FModuleSteps.ToJSON;
end;

{*
����������ƽ׶�ִ��
*}
function TStepMgr.GetStepDesignForm(AStepRec: TModuleStepRec): TStepBasicForm;
var
  LRunDllInfo: TRunDllInfo;
begin
  Result := nil;
  //��ȡstep��Ӧ��dll���
  LRunDllInfo := GetRunDll(AStepRec.DllNameSpace);
  if LRunDllInfo = nil then Exit;

  //��dll���ض�Ӧ��ָ���ַ����
  Result := LRunDllInfo.GetStepDesignForm(AStepRec);
end;

{*
����������ƽ׶κ����н׶ξ���ִ��
*}
function TStepMgr.GetStep(AStepRec: TModuleStepRec): TStepBasic;
var
  LRunDllInfo: TRunDllInfo;
begin
  Result := nil;
  //��ȡstep��Ӧ��dll���
  LRunDllInfo := GetRunDll(AStepRec.DllNameSpace);
  if LRunDllInfo = nil then Exit;

  //��dll���ض�Ӧ��ָ���ַ����
  Result := LRunDllInfo.GetStep(AStepRec);
end;

end.

