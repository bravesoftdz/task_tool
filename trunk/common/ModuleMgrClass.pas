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
{Modules, SubModules��������ֱ�ӹ�����
 Module[ModuleID], SubModule[FullID]����ģ��ID���й���}

unit ModuleMgrClass;

interface

uses
  PublicInfoClass, Contnrs;

type

  TSubModuleRec=record
    Name: string;
    Caption: string;
    Hint: string;
    OwnerID: Cardinal;
    ID: Byte;
    ShowDlg: Boolean;
    AllowMulti: Boolean;
    InitBeforeCall: Boolean;
    Existed: Boolean;
    H1:THandle;  //���Ա�������ģ��������ɿ�����ʹ��
    H2:THandle;
    H3:Cardinal;
    H4:Cardinal;
    H5:Integer;
    H6:Integer;
  end;

  TSubModuleList=array of TSubModuleRec;

  TModuleRec=record
    FilePath:string;
    DllName:string;
    Name:string;
    Caption:string;
    Hint:string;
    ID:Integer;
    SubModuleCount: Byte;
    SubModules: TSubModuleList;
  end;

  TModuleList=array of TModuleRec;

  TRunDllInfo=class
    FilePath:string;
    DllName:string;
    DllHandle:THandle;
    DllEntryPointer:Pointer;
  public
    destructor Destroy; override;
  end;

  TIDRec=record
    ModuleID: Integer;
    SubModuleID: Integer;
  end;

  //ģ���������������ϵͳȫ��Module��Ϣ�Ĺ������Լ������������е�Module�Ĺ���
  TModuleMgr=class
  private
    FModuleList: TModuleList;
    FModuleCount: Integer;
    FModuleCapacity: Integer;
    FModuleRecSize: Integer;
    FMaxModuleCount: Integer;

    FRunDllList: TObjectList;

    function GetDllEntryPointer(aFullID: integer): Pointer;
    
    {ModuleList}
    procedure setModuleCapacity(const Value: Integer);
    function GetModule(aModuleID: Integer): TModuleRec;
    function GetSubModule(aFullID: Integer): TSubModuleRec;

    {RunDllList}
    function GetRunDllCount: Integer;
    function GetRunDll(idx: Integer): TRunDllInfo;
  protected
    procedure ModuleListGrow;
  public
    constructor Create;
    destructor Destroy; override;

    property DllEntryPointer[aFullID: integer]: Pointer read GetDllEntryPointer;
    function DecodeID(const aFullID: Cardinal): TIDRec;
    function EncodeID(aModuleID: Cardinal; aSubModuleID: Byte): Cardinal;

    {ModuleList}
    function AddModule(const aPCharModuleInfo: TPCharModuleInfo): Integer; overload;
    function AddModule(const aFilePath, aDllName: string;
                          const aPCharModuleInfo: TPCharModuleInfo): Integer; overload;
    function IndexOfModule(const aModuleID: Integer): Integer;
    function GetDllFullName(const aFullID: Cardinal): string;
    function SubModuleByName(const ASubModuleName: string): TSubModuleRec;
    procedure LoadModules(const aFilePath, aDllName: string);
    procedure LoadModuleDlls(aFilePath: string);
    procedure LoadModuleDllsFrom(aFilePath: string);
    property ModuleCount: Integer read FModuleCount write FModuleCount;
    property ModuleCapacity: Integer read FModuleCapacity write setModuleCapacity;
    property Modules: TModuleList read FModuleList write FModuleList;
    property Module[aModuleID: Integer]: TModuleRec read GetModule;
    property SubModule[aFullID: Integer]: TSubModuleRec read GetSubModule;

    {RunDllList}
    function AddRunDll(const aRunDllInfo: TRunDllInfo): Integer; overload;
    function AddRunDll(const aFilePath, aDllName: string; const aDllHandle: THandle;
                       const aDllEntryPointer: Pointer): Integer; overload;
    procedure RemoveRunDll(idx: Integer);
    function IndexofRunDll(const aDllFullName: string): Integer;
    property RunDlls: TObjectList read FRunDllList write FRunDllList;
    property RunDll[idx: Integer]: TRunDllInfo read GetRunDll;
    property RunDllCount: Integer read GetRunDllCount;

  end;

implementation

uses
  Windows, SysUtils, Classes;


{ TRunDllInfo }

destructor TRunDllInfo.Destroy;
begin
  if DllHandle<>0 then
  begin
    FreeLibrary(DllHandle);
  end;
  inherited;
end;

{ TModuleMgr }

constructor TModuleMgr.Create;
begin
  inherited Create;
  FRunDllList:=TObjectList.Create(False);
  FModuleRecSize:=SizeOf(TModuleRec);
  FModuleRecSize:=((FModuleRecSize + 3 ) shr 2) shl 2;
  FMaxModuleCount:=MaxInt div FModuleRecSize;
  FModuleCount:=0;
end;


destructor TModuleMgr.Destroy;
var
  i:Integer;
begin
  for i := 0 to FRunDllList.Count - 1 do
    RunDll[i].Free;
  FreeAndNil(FRunDllList);
  inherited;
end;


function TModuleMgr.GetDllEntryPointer(aFullID: integer): Pointer;
var
  aDllFullName: string;
  idx: Integer;
  h: THandle;
  p: Pointer;
begin
  Result:=nil;
  aDllFullName:=GetDllFullName(aFullID);
  idx:=IndexofRunDll(aDllFullName);
  if idx>-1 then
  begin
    Result:=RunDll[idx].DllEntryPointer;
    Exit;
  end;
  h:=LoadLibrary(PChar(aDllFullName));
  if h>0 then
  begin
    p:=GetProcAddress(h,'DllEntryPointer');
    if p<>nil then
    begin
      Result:=p;
      AddRunDll(ExtractFilePath(aDllFullName),ExtractFileName(aDllFullName),h,p);
    end
    else
      FreeLibrary(h);
  end;
end;

{ModuleList}

function TModuleMgr.IndexOfModule(const aModuleID: Integer): Integer;
var
  i:Integer;
begin
  Result:=-1;
  for i:=0 to FModuleCount-1 do
  begin
    if FModuleList[i].ID=aModuleID then
    begin
      Result:=i;
      Exit;
    end;
  end;
end;

function TModuleMgr.DecodeID(const aFullID:Cardinal):TIDRec;
begin
  Result.SubModuleID:=$000000FF and aFullID;
  Result.ModuleID:=aFullID shr 8;
end;

function TModuleMgr.EncodeID(aModuleID: Cardinal;
  aSubModuleID: Byte): Cardinal;
begin
  Result:=aModuleID shl 8 + aSubModuleID;
end;

function TModuleMgr.GetDllFullName(const aFullID: Cardinal): string;
var
  idx: Integer;
  aID: TIDRec;
begin
  Result:='';
  aID:=DecodeID(aFullID);
  idx:=IndexofModule(aID.ModuleID);
  if idx>-1 then
    Result:=Modules[idx].FilePath+Modules[idx].DllName;
end;

function TModuleMgr.AddModule(const aPCharModuleInfo: TPCharModuleInfo): Integer;
var
  i:Integer;
begin
  if FModuleCount=FModuleCapacity then
    ModuleListGrow;
  with FModuleList[FModuleCount] do
  begin
    Name:=aPCharModuleInfo.Name;
    Caption:=aPCharModuleInfo.Caption;
    Hint:=aPCharModuleInfo.Hint;
    ID:=aPCharModuleInfo.ID;
    SubModuleCount:=aPCharModuleInfo.SubModuleCount;
    SetLength(SubModules, SubModuleCount);
    for i:=0 to SubModuleCount-1 do
    begin
      with SubModules[i] do
      begin
        Name:=TPCharSubModuleInfo(aPCharModuleInfo.SubModules[i]).Name;
        Caption:=TPCharSubModuleInfo(aPCharModuleInfo.SubModules[i]).Caption;
        Hint:=TPCharSubModuleInfo(aPCharModuleInfo.SubModules[i]).Hint;
//        OwnerID:=TPCharSubModuleInfo(aPCharModuleInfo.SubModules[i]).OwnerID;
//        ID:=TPCharSubModuleInfo(aPCharModuleInfo.SubModules[i]).ID;
        ShowDlg:=TPCharSubModuleInfo(aPCharModuleInfo.SubModules[i]).ShowDlg;
        AllowMulti:=TPCharSubModuleInfo(aPCharModuleInfo.SubModules[i]).AllowMulti;
        InitBeforeCall:=TPCharSubModuleInfo(aPCharModuleInfo.SubModules[i]).InitBeforeCall;
        Existed:=True;
      end;
    end;
    Result:=FModuleCount;
    inc(FModuleCount);
  end;
end;

function TModuleMgr.AddModule(const aFilePath, aDllName: string;
  const aPCharModuleInfo: TPCharModuleInfo): Integer;
begin
  if FModuleCount=FModuleCapacity then
    ModuleListGrow;
  with FModuleList[FModuleCount] do
  begin
    FilePath:=aFilePath;
    DllName:=aDllName;
  end;
  Result:=AddModule(aPCharModuleInfo);
end;

procedure TModuleMgr.ModuleListGrow;
var
  NewCapacity: Integer;
begin
  if ModuleCapacity=0 then
    NewCapacity:=4
  else if ModuleCapacity<64 then
    NewCapacity:=ModuleCapacity + 16
  else
    NewCapacity:=ModuleCapacity + (ModuleCapacity div 4);
  if NewCapacity>FMaxModuleCount then
  begin
    NewCapacity:=FMaxModuleCount;
    if (NewCapacity=ModuleCapacity) then
      raise Exception.Create('�ڴ��������Ѵ�ģ���������');
  end;
  ModuleCapacity:=NewCapacity;
end;

procedure TModuleMgr.setModuleCapacity(const Value: Integer);
begin
  if Value<>FModuleCapacity then
  begin
    if Value>FMaxModuleCount then
      raise Exception.Create('�ڴ��������Ѵ�ģ���������');
    SetLength(FModuleList,Value);
    FModuleCapacity := Value;
  end;
end;

function TModuleMgr.SubModuleByName(
  const ASubModuleName: string): TSubModuleRec;
var
  i,j: Integer;
begin
  Result.Existed:=False;
  for j := 0 to ModuleCount - 1 do
  begin
    for i:=0 to Modules[j].SubModuleCount-1 do
    begin
      if Modules[j].SubModules[i].Name = ASubModuleName then
      begin
        Result := Modules[j].SubModules[i];
        Exit;
      end;
    end;
  end;
end;

function TModuleMgr.GetModule(aModuleID: Integer): TModuleRec;
var
  idx:Integer;
begin
  idx:=IndexofModule(aModuleID);
  if (idx>-1) then
    Result:=FModuleList[idx]
  else
    Result.ID:=-1;
end;

function TModuleMgr.GetSubModule(aFullID: Integer): TSubModuleRec;
var
  aID: TIDRec;
  i,idx: Integer;
begin
  Result.Existed:=False;
  aID:=DecodeID(aFullID);
  idx:=IndexOfModule(aID.ModuleID);
  if idx=-1 then Exit;
  for i:=0 to Modules[idx].SubModuleCount-1 do
  begin
    if Modules[idx].SubModules[i].ID=aID.SubModuleID then
    begin
      Result:=Modules[idx].SubModules[i];
      Exit;
    end;
  end;
end;

// �������������ļ����ض�̬ģ��
procedure TModuleMgr.LoadModuleDllsFrom(aFilePath: string);
var
  lStringList: TStringList;
  i: Integer;
  lFilePath, lFileName: string;
begin
  if DirectoryExists(aFilePath) then
  begin
    lStringList := TStringList.Create;
    try
      //TODO Config.IniFile.ReadSectionValues('Modules', lStringList);
      for i := 0 to lStringList.Count - 1 do
      begin
        if FileExists(lStringList.ValueFromIndex[i]) then
        begin
          lFilePath := ExtractFilePath(lStringList.ValueFromIndex[i]);
          lFileName := ExtractFileName(lStringList.ValueFromIndex[i]);
          LoadModules(lFilePath, lFileName);
        end
        else
          LoadModules(aFilePath, lStringList.ValueFromIndex[i]);
      end;
    finally
      lStringList.Free;
    end;
  end;
end;

procedure TModuleMgr.LoadModuleDlls(aFilePath: string);
var
  aSearchrec:TSearchRec;
  findresult:integer;
begin
  if DirectoryExists(aFilePath) then
  begin
    if aFilePath[Length(aFilePath)]<>'\' then
      aFilePath:=aFilePath+'\';
    // �������������ļ���Modules�������Զ�����
    findresult:=findfirst(aFilePath+'*.dll',faAnyFile,asearchrec);
    while (findresult=0) do
    begin
      LoadModules(aFilePath,aSearchrec.Name);
      findresult:=FindNext(aSearchrec);
    end;
    FindClose(aSearchrec);
  end;
end;

procedure TModuleMgr.LoadModules(const aFilePath, aDllName: string);
type
  TGetModuleInfo=procedure (DllModuleList:TObjectList);stdcall;
var
  h:thandle;
  p:Pointer;
  i:Integer;
  afullName:string;
  tempPCharModuleInfo:TPCharModuleInfo;
  tempList:TObjectList;
begin
  afullName:=aFilePath+aDllName;
  h:=LoadLibrary(PChar(afullName));
  if h>0 then
  begin
    p:=GetProcAddress(h,'ModulesInfo');
    if p<>nil then
    begin
      tempList:=TObjectList.Create;
      TGetModuleInfo(p)(tempList);
      for i:=0 to tempList.Count-1 do
      begin
        tempPCharModuleInfo:=TPCharModuleInfo(tempList.Items[i]);
        AddModule(aFilePath,aDllName,tempPCharModuleInfo);
      end;
      tempList.Clear;
      tempList.Free;
    end;
    FreeLibrary(h);
  end;
end;

{RunDllList}
function TModuleMgr.GetRunDllCount: Integer;
begin
  Result:=FRunDllList.Count;
end;

function TModuleMgr.AddRunDll(const aRunDllInfo: TRunDllInfo): Integer;
begin
  Result:=-1;
  if aRunDllInfo<>nil then
  begin
    Result:=FRunDllList.Add(aRunDllInfo);
  end;
end;

function TModuleMgr.AddRunDll(const aFilePath, aDllName: string;
  const aDllHandle: THandle; const aDllEntryPointer: Pointer): Integer;
var
  aRunDllInfo: TRunDllInfo;
begin
  aRunDllInfo:=TRunDllInfo.Create;
  aRunDllInfo.FilePath:=aFilePath;
  aRunDllInfo.DllName:=aDllName;
  aRunDllInfo.DllHandle:=aDllHandle;
  aRunDllInfo.DllEntryPointer:=aDllEntryPointer;
  Result:=AddRunDll(aRunDllInfo);
  if Result=-1 then
    aRunDllInfo.Free;
end;

procedure TModuleMgr.RemoveRunDll(idx: Integer);
begin
  RunDll[idx].Free;
  FRunDllList.Delete(idx);
end;

function TModuleMgr.IndexofRunDll(const aDllFullName: string): Integer;
var
  i:integer;
begin
  Result:=-1;
  for i:=0 to FRunDllList.Count-1 do
  begin
    if CompareText(aDllFullName,RunDll[i].FilePath+Rundll[i].DllName)=0 then
    begin
      Result:=i;
      Exit;
    end;
  end;
end;

function TModuleMgr.GetRunDll(idx: Integer): TRunDllInfo;
begin
  Result:=nil;
  if (idx>-1) and (idx<FRunDllList.Count) then
    Result:=TRunDllInfo(FRunDllList[idx]);
end;


end.
 