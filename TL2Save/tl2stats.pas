unit TL2Stats;

interface

uses
  TL2Types,
  TL2Stream,
  TL2Base;

type
  tStatMob = packed record
    id    :TL2ID;
    field1:TL2Integer; // ?? amount killed, player+aoe
    field2:TL2Integer; // ?? amount killed, player+pet
    exp   :TL2Integer;
    field4:TL2Integer;
    field5:TL2Integer;
    field6:TL2Integer;
    field7:TL2Integer;
    field8:Word;       // by phys? no :(
    field9:Word;
  end;
  tStatMobArray = array of tStatMob;

  tStatItem = packed record
    id    :TL2ID;
    field1:TL2Integer; // ?? word=amount picked (equipped+pots?); word=amount picked(unusable)
    field2:TL2Integer; // ?? crafted                word+word
    field3:TL2Integer; // ??                        word+word
    field4:TL2Integer; // min level? (to recognize) word+word
  end;
  tStatItemArray = array of tStatItem;

  tStatSkill = packed record
    id    :TL2ID;
    times :TL2Integer; // ?? manual
    field2:TL2Integer; // ?? auto
    level :Byte;
  end;
  tStatSkillArray = array of tStatSkill;

  tStatLevelup = packed record
    uptime :TL2Float;   // time
    field2 :TL2Integer; // 27 phys dmg?
    field3 :TL2Integer; // 54 magic dmg?
    field4 :TL2Integer; // ?? amount of attacks?
    field5 :Byte;       // ?? flag=equipped manually? or amount on pet?
    field6 :TL2Integer; // plus gold per level (picked and shop) ??hibyte/word (01/02)
    field7 :Byte;       // maybe word (with byte from Field06)
    field8 :TL2Integer; // like field2 (not always)
    field9 :TL2Integer; // like field3 (not always)
    field10:Byte;
  end;
  tStatLevelUpArray = array of tStatLevelUp;

type
  TTL2StringVal = record
    name :string;
    value:TL2Integer;
  end;
  TTL2StringValList = array of TTL2StringVal;

type
  TTL2Stats = class(TL2BaseClass)
  private
    procedure InternalClear;

  public
    constructor Create;
    destructor  Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TTL2Stream); override;
    procedure SaveToStream  (AStream: TTL2Stream); override;

  private
    FStatMobs   :tStatMobArray;     // array [0..39] of byte;
    FStatItems  :tStatItemArray;    // array [0..23] of byte;
    FStatSkills :tStatSkillArray;   // array [0..16] of byte;
    FStatLevelUp:tStatLevelUpArray; // array [0..30] of byte;
    FStatArea1  :TTL2StringValList;
    FStatArea2  :TTL2StringValList;
    FStatKillers:TL2IdValList;

    FUnkn1    :Word;
    FUnkn2    :Word;
    FUnkn17  :array [0..16] of byte;
    FUnkn9   :array [0.. 8] of byte;
    FUnknLast:DWord;

    FStatName :string;
    FStatClass:string;
    FStatPet  :string;
  public
    property PlayerName :string read FStatName;
    property PlayerClass:string read FStatClass;
    property PetClass   :string read FStatPet;

    property Mobs   :tStatMobArray     read FStatMobs;
    property Items  :tStatItemArray    read FStatItems;
    property Skills :tStatSkillArray   read FStatSkills;
    property LevelUp:tStatLevelUpArray read FStatLevelUp;
    property Area1  :TTL2StringValList read FStatArea1;
    property Area2  :TTL2StringValList read FStatArea2;
    property Killers:TL2IdValList      read FStatKillers;
  end;

function ReadLastBlock(AStream:TTL2Stream):TTL2Stats;


implementation

uses
  TL2Common;

constructor TTL2Stats.Create;
begin
  inherited;

  DataType:=dtStat;
end;

destructor TTL2Stats.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Stats.InternalClear;
begin
  SetLength(FStatMobs   ,0);
  SetLength(FStatItems  ,0);
  SetLength(FStatSkills ,0);
  SetLength(FStatLevelUp,0);
  SetLength(FStatArea1  ,0);
  SetLength(FStatArea2  ,0);
  SetLength(FStatKillers,0);
end;

procedure TTL2Stats.Clear;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Stats.LoadFromStream(AStream:TTL2Stream);
var
  i,lcnt:integer;
begin
  DataSize  :=AStream.ReadDWord;
  DataOffset:=AStream.Position;
  
  FUnkn1:=Check(AStream.ReadWord,'last block 1_'+HexStr(AStream.Position,8),1);
  FUnkn2:=Check(AStream.ReadWord,'last block 2_'+HexStr(AStream.Position,8),0);
  //??
  AStream.Read(FUnkn17[0],17);
{
  AStream.ReadDWord; // 3DF65D40 = 0.12
  AStream.ReadDword; // 0x####0040
  AStream.ReadDWord; // 3DF65D40 = 0.12
  AStream.ReadDWord; // 0x######40

  AStream.ReadByte;  // 0
}
  // mobs
  lcnt:=AStream.ReadDWord;
  SetLength(FStatMobs,lcnt);
  if lcnt>0 then
    AStream.Read(FStatMobs[0],lcnt*40);
{
  8b - mob id (media/units/monsters)
  4b - x?
  4b - y?
  4b - exp
  4b - 
  4b - 
  4b - ?
  4b - 
  2b
  2b
}

  // items
  lcnt:=AStream.ReadDWord;
  SetLength(FStatItems,lcnt);
  if lcnt>0 then
    AStream.Read(FStatItems[0],lcnt*24);
{
  8b - item id (media\units\items)
  4b - 
  4b - 
  4b - [0]
  4b - amount?
}

  // skills
  lcnt:=AStream.ReadDWord;
  SetLength(FStatSkills,lcnt);
  if lcnt>0 then
    AStream.Read(FStatSkills[0],lcnt*17);
{
  8b - skill id (media\skills)
  4b - 
  4b - 
  1b - 
}

  // levelups
  lcnt:=AStream.ReadDWord;
  SetLength(FStatLevelUp,lcnt);
  if lcnt>0 then
    AStream.Read(FStatLevelUp[0],lcnt*31);
{
  4b - time to level up
  4b - ?
  4b - ?
  4b - ?
  1b - [0]
  4b - 
  1b
  4b
  4b
  1b
}

  //----- Area -----
  // usually, count and titles are the same

  //--- time on location ---
  lcnt:=AStream.ReadDWord;
  SetLength(FStatArea1,lcnt);
  for i:=0 to lcnt-1 do
  begin
    FStatArea1[i].name :=AStream.ReadShortString;
    FStatArea1[i].value:=AStream.ReadDWord;       // time on location?
  end;

  //--- player level at first entrance ---
  lcnt:=AStream.ReadDWord;
  SetLength(FStatArea2,lcnt);
  for i:=0 to lcnt-1 do
  begin
    FStatArea2[i].name :=AStream.ReadShortString;
    FStatArea2[i].value:=AStream.ReadDWord;        // char level
  end;

  //----- ?? Unknown -----

  AStream.Read(FUnkn9[0],9);
{
  ## | < 0 > | < 1 > | < 2 > | < 3 > |
  00 | 01 00 | 00 00 | 00 00 | 00 00 | zero
  00 | 0F 00 | 03 00 | 00 00 | 00 00 | Zorro (cheat)
  02 | 00 00 | 00 00 | 08 00 | 00 00 | ElTheo
  02 | 09 00 | 00 00 | 0A 00 | 00 00 | Timon
  01 | 00 00 | 18 00 | 00 00 | 00 00 | Lonelfly 24
  01 | 00 00 | 23 00 | 00 00 | 00 00 | Elfly    35
  03 | 00 00 | 00 00 | 00 00 | 02 00 | Archer
  02 | 00 00 | 00 00 | 05 00 | 00 00 | Tenebris
  02 | 00 00 | 00 00 | 01 00 | 0C 00 | ElPro
  03 | 00 00 | 00 00 | 00 00 | 06 00 | ElDrui
}
  //----- Player killers -----

  FStatKillers:=AStream.ReadIdValList;

  FUnknLast:=Check(AStream.ReadDWord,'pre-end',0);

  FStatName :=AStream.ReadShortString; // player name
  FStatClass:=AStream.ReadShortString; // class
  FStatPet  :=AStream.ReadShortString; // Pet class

  Check(AStream.ReadByte,'final',0); // 0

  LoadBlock(AStream);
end;

procedure TTL2Stats.SaveToStream(AStream:TTL2Stream);
var
  i:integer;
begin
  AStream.WriteDWord(DataSize);
  
  if not Changed then
  begin
    SaveBlock(AStream);
    exit;
  end;

  DataOffset:=AStream.Position;

  AStream.WriteWord(FUnkn1);
  AStream.WriteWord(FUnkn2);

  AStream.Write(FUnkn17[0],17);

  // mobs
  AStream.WriteDWord(Length(FStatMobs));
  if Length(FStatMobs)>0 then
    AStream.Write(FStatMobs[0],Length(FStatMobs)*40);

  // items
  AStream.WriteDWord(Length(FStatItems));
  if Length(FStatItems)>0 then
    AStream.Write(FStatItems[0],Length(FStatItems)*24);

  // skills
  AStream.WriteDWord(Length(FStatSkills));
  if Length(FStatSkills)>0 then
  AStream.Write(FStatSkills[0],Length(FStatSkills)*17);

  // levelups
  AStream.WriteDWord(Length(FStatLevelUp));
  if Length(FStatLevelUp)>0 then
    AStream.Write(FStatLevelUp[0],Length(FStatLevelUp)*31);

  //----- Area, time on location and player level -----

  AStream.WriteDWord(Length(FStatArea1));
  for i:=0 to High(FStatArea1) do
  begin
    AStream.WriteShortString(FStatArea1[i].name);
    AStream.WriteDWord      (FStatArea1[i].value);
  end;

  AStream.WriteDWord(Length(FStatArea2));
  for i:=0 to High(FStatArea2) do
  begin
    AStream.WriteShortString(FStatArea2[i].name);
    AStream.WriteDWord      (FStatArea2[i].value);
  end;

  //----- ?? Unknown -----

  AStream.Write(FUnkn9[0],9);

  //----- Player killers -----

  AStream.WriteIdValList(FStatKillers);

  AStream.WriteDWord(FUnknLast);

  AStream.WriteShortString(FStatName ); // player name
  AStream.WriteShortString(FStatClass); // class
  AStream.WriteShortString(FStatPet  ); // Pet class

  AStream.WriteByte(0);

  LoadBlock(AStream);
  FixSize  (AStream);
end;


function ReadLastBlock(AStream:TTL2Stream):TTL2Stats;
begin
  result:=TTL2Stats.Create;
  result.LoadFromStream(AStream);
end;

end.
