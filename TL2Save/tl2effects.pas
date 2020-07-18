{}
unit TL2Effects;

interface

uses
  Classes,
  TL2Types,
  TL2Base,
  TL2Stream;

type
  TTL2EffectDamageType = (Physical, Magical, Fire, Ice, Electric, Poison, All);
  TTL2EffectSource     = (OnCastCaster, OnCastReceiver, OnUpdateCaster, OnUpdateSelf);
  TTL2EffectActivation = (Passive, Dynamic, Transfer);

  TTL2EffectFlag = (
    modUnknown1          , // $00000001
    modUnknown2          , // $00000002
    modExclusive         , // $00000004
    modNotMagical        , // $00000008
    modSaves             , // $00000010
    modDisplayPositive   , // $00000020
    modUnknown3          , // $00000040
    modUseOwnerLevel     , // $00000080
    modHasGraph          , // $00000100
    modIsBonus           , // $00000200
    modIsEnchantment     , // $00000400
    modHasLinkName       , // $00000800
    modHasParticles      , // $00001000
    modHasUnitTheme      , // $00002000
    modUnknown4          , // $00004000
    modUnknown5          , // $00008000
    modRemoveOnDeath     , // $00010000
    modHasIcon           , // $00020000
    modDisplayMaxModifier, // $00040000
    modIsForWeapon       , // $00080000
    modIsForArmor        , // $00100000
    modIsDisabled        , // $00200000
    // not realized (just reserved by me)
    modUnknown6          , // $00400000
    modUnknown7          , // $00800000
    modUnknown8          , // $01000000
    modUnknown9          , // $02000000
    modUnknown10         , // $04000000
    modUnknown11         , // $08000000
    modUnknown12         , // $10000000
    modUnknown13         , // $20000000
    modUnknown14         , // $40000000
    modUnknown15           // $80000000
  );

  TTL2EffectFlags = set of TTL2EffectFlag;

type
  TTL2Stat = packed record
    id        :TL2ID;
    percentage:TL2Float;
  end;

type
  TTL2Effect = class;
  TTL2EffectList = array of TTL2Effect;
type
  TTL2Effect = class(TL2BaseClass)
  private
    procedure InternalClear;

  public
    constructor Create(achar:boolean); overload;
    destructor Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TTL2Stream); override;
    procedure SaveToStream  (AStream: TTL2Stream); override;

  private
    FFlags       :TTL2EffectFlags;
    FName        :string;
    FLinkName    :string;
    FGraph       :string;
    FParticles   :string;
    FUnitThemeId :TL2ID;
    FClassId     :TL2ID;
    FFromChar    :boolean;
    FProperties  :array of TL2Float;
    FStats       :array of TTL2Stat;
    FEffectType  :integer;
    FDamageType  :TTL2EffectDamageType;
    FActivation  :TTL2EffectActivation;
    FLevel       :integer;
    FDuration    :TL2Float;
    FUnknown1    :TL2Float;
    FDisplayValue:TL2Float;
    FSource      :TTL2EffectSource;
    FIcon        :string;

    function GetProperties(idx:integer):TL2Float;
    function GetStats     (idx:integer):TTL2Stat;

  public
    property Flags       :TTL2EffectFlags           read FFlags        write FFlags; //??
    property Name        :string                    read FName         write FName;
    property Graph       :string                    read FGraph        write FGraph;
    property Particles   :string                    read FParticles    write FParticles;
    property UnitThemeId :TL2ID                     read FUnitThemeId  write FUnitThemeId;
    property ClassId     :TL2ID                     read FClassId      write FClassId;
    property Properties  [idx:integer]:TL2Float     read GetProperties; //!!
    property Stats       [idx:integer]:TTL2Stat     read GetStats     ; //!!
    property EffectType  :integer                   read FEffectType   write FEffectType;
    property DamageType  :TTL2EffectDamageType      read FDamageType   write FDamageType;
    property Activation  :TTL2EffectActivation      read FActivation   write FActivation;
    property Level       :integer                   read FLevel        write FLevel;
    property Duration    :TL2Float                  read FDuration     write FDuration;
    property DisplayValue:TL2Float                  read FDisplayValue write FDisplayValue;
    property Source      :TTL2EffectSource          read FSource       write FSource;
    property Icon        :string                    read FIcon         write FIcon;
  end;


function  ReadEffectList (AStream:TTL2Stream; atrans:boolean=false):TTL2EffectList;
procedure WriteEffectList(AStream:TTL2Stream; alist:TTL2EffectList);


implementation


constructor TTL2Effect.Create(achar:boolean); overload;
begin
  inherited Create;

  DataType:=dtEffect;
  FFromChar:=achar;
end;

destructor TTL2Effect.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Effect.InternalClear;
begin
  SetLength(FProperties,0);
  SetLength(FStats ,0);
end;

procedure TTL2Effect.Clear;
begin
  InternalClear;

  inherited;
end;

function TTL2Effect.GetProperties(idx:integer):single;
begin
  if (idx>=0) and (idx<Length(FProperties)) then
    result:=FProperties[idx]
  else
    result:=0;
end;

function TTL2Effect.GetStats(idx:integer):TTL2Stat;
begin
  if (idx>=0) and (idx<Length(FStats)) then
    result:=FStats[idx]
  else
  begin
    result.id:=TL2IdEmpty;
    result.percentage:=0;
  end;
end;


procedure TTL2Effect.LoadFromStream(AStream: TTL2Stream);
var
  lcnt:integer;
begin
  DataOffset:=AStream.Position;

  FFlags:=TTL2EffectFlags(AStream.ReadDword);
  FName :=AStream.ReadShortString();

  if modHasLinkName in FFlags then
    FLinkName:=AStream.ReadShortString();

  if modHasGraph in FFlags then
    FGraph:=AStream.ReadShortString();

  if modHasParticles in FFlags then
    FParticles:=AStream.ReadShortString();

  if modHasUnitTheme in FFlags then
    FUnitThemeId:=TL2ID(AStream.ReadQWord);

  if FFromChar then
    FClassId:=TL2ID(AStream.ReadQWord);

  lcnt:=AStream.ReadByte();
  SetLength(FProperties,lcnt);
  if lcnt>0 then
    AStream.Read(FProperties[0],lcnt*SizeOf(TL2Float));

  lcnt:=AStream.ReadWord;
  SetLength(FStats,lcnt);
  if lcnt>0 then
    AStream.Read(FStats[0],lcnt*SizeOf(TTL2Stat));

  FEffectType  :=AStream.ReadDWord();
  FDamageType  :=TTL2EffectDamageType(AStream.ReadDWord);
  FActivation  :=TTL2EffectActivation(AStream.ReadDWord); // ????
  FLevel       :=AStream.ReadDWord;
  FDuration    :=AStream.ReadFloat;
  FUnknown1    :=AStream.ReadFloat;  // 0 ??  SoakScale??
  FDisplayValue:=AStream.ReadFloat;
  FSource      :=TTL2EffectSource(AStream.ReadDWord);

  if modHasIcon in FFlags then
    FIcon:=AStream.ReadByteString();

  LoadBlock(AStream);
end;

procedure TTL2Effect.SaveToStream(AStream: TTL2Stream);
begin
  if not Changed then
  begin
    SaveBlock(AStream);
    exit;
  end;

  DataOffset:=AStream.Position;
  
  AStream.WriteDword(DWord(FFlags));
  AStream.WriteShortString(FName);

  if modHasLinkName in FFlags then
    AStream.WriteShortString(FLinkName);

  if modHasGraph in FFlags then
    AStream.WriteShortString(FGraph);

  if modHasParticles in FFlags then
    AStream.WriteShortString(FParticles);

  if modHasUnitTheme in FFlags then
    AStream.WriteQWord(QWord(FUnitThemeId));

  if FFromChar then
    AStream.WriteQWord(QWord(FClassId));

  AStream.WriteByte(Length(FProperties));
  if Length(FProperties)>0 then
    AStream.Write(FProperties[0],Length(FProperties)*SizeOf(TL2Float));

  AStream.WriteWord(Length(FStats));
  if Length(FStats)>0 then
    AStream.Write(FStats[0],Length(FStats)*SizeOf(TTL2Stat));

  AStream.WriteDWord(FEffectType);

  AStream.WriteDWord(DWord(FDamageType));
  AStream.WriteDWord(DWord(FActivation));

  AStream.WriteDWord(FLevel);
  AStream.WriteFloat(FDuration);
  //??
  AStream.WriteFloat(FUnknown1);
  AStream.WriteFloat(FDisplayValue);

  AStream.WriteDWord(DWord(FSource));

  if modHasIcon in FFlags then
    AStream.WriteByteString(FIcon);

  LoadBlock(AStream);
end;

function ReadEffectList(AStream:TTL2Stream; atrans:boolean=false):TTL2EffectList;
var
  i,lcnt:integer;
begin
  result:=nil;
  lcnt:=AStream.ReadDWord;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    for i:=0 to lcnt-1 do
    begin
      result[i]:=TTL2Effect.Create(atrans);
      result[i].LoadFromStream(AStream);
    end;
  end;
end;

procedure WriteEffectList(AStream:TTL2Stream; alist:TTL2EffectList);
var
  i:integer;
begin
  AStream.WriteDWord(Length(alist));
  for i:=0 to High(alist) do
    alist[i].SaveToStream(AStream);
end;

end.