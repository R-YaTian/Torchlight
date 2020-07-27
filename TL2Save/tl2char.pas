unit TL2Char;

interface

uses
  classes,
  tl2stream,
  tl2common,
  tl2types,
  tl2base,
  tl2active,
  tl2effects,
  tl2item;

type
  TTL2Action = (Idle, Attack, Defence);

type
  TTL2Spell = record
    name :string;
    level:DWord;
  end;
  TTL2SpellList = array [0..3] of TTL2Spell;

type
  TTL2Character = class(TL2ActiveClass)
  private
    procedure InternalClear;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TTL2Stream); override;
    procedure SaveToStream  (AStream: TTL2Stream); override;

  private
    FSign1          :Byte;
    FSign2          :Byte;
    FIsChar         :boolean;
    FIsPet          :boolean;

    FWardrobe       :TL2Boolean;

    // Pet's corner
    FMorphId        :TL2ID;
    FScale          :TL2Float;
    FSkin           :Byte;
    FMorphTime      :TL2Float;
    FTownTime       :TL2Float;
    FAction         :TTL2Action;

    // unknowns
    FUnkn1          :TL2ID;
    FUnkn2          :Byte;
    FUnkn3          :DWord;
    FUnkn4          :Word;
    FUnkn5          :Byte;
    FUnkn6          :DWord;
    FUnkn7          :array [0..23] of byte;
    FUnkn17         :DWord;
    FUnkn9          :QWord;
    FUnkn11         :DWord;
    FUnkn12         :array [0..11] of byte;
    FUnkn13         :TL2Float;
    FUnkn14         :array [0..27] of byte;
    FUnkn15         :array [0..15] of byte;

    // player's Wardrobe etc
    FWardUnkn       :array [0..35] of byte;
    FFace           :integer;
    FHairstyle      :integer;
    FHairColor      :integer;
    FCheater        :byte;
    FPlayer         :string;

    // looks like common
    FExperience     :integer;
    FFameLevel      :integer;
    FFameExp        :integer;
    FHealth         :TL2Float;
    FHealthBonus    :integer;
    FMana           :TL2Float;
    FManaBonus      :integer;
    FPlayTime       :TL2Float;
    FFreeSkillPoints:integer;
    FFreeStatPoints :integer;
    FStrength       :integer;
    FDexterity      :integer;
    FVitality       :integer;
    FFocus          :integer;
    FGold           :integer;
    FSkills         :TL2IdValList;
    FSpells         :TTL2SpellList;
    FItems          :TTL2ItemList;

    // buttons
    FRMB1 :TL2ID;
    FRMB2 :TL2ID;
    FLMB  :TL2ID;
    FARMB1:TL2ID;
    FARMB2:TL2ID;
    FALMB :TL2ID;

    function  GetDBMods():string; override;
    function  GetStat(const iname:string):TL2Integer;
    procedure SetStat(const iname:string; aval:TL2Integer);
    function  GetSpell(idx:integer):TTL2Spell;
    procedure SetSpell(idx:integer; const aspell:TTL2Spell);
  public
    function CheckForMods(alist:TTL2ModList):boolean;

    property Action:TTL2Action read FAction write FAction;
    property IsChar         :boolean  read FIsChar;
    property IsPet          :boolean  read FIsPet;
    property Sign1          :Byte     read FSign1;
    property Sign2          :Byte     read FSign2;
    property MorphId        :TL2ID    read FMorphId         write FMorphId;
    property Player         :string   read FPlayer          write FPlayer;
    property MorphTime      :TL2Float read FMorphTime       write FMorphTime;
    property TownTime       :TL2Float read FTownTime        write FTownTime;
    property Face           :integer  read FFace            write FFace;
    property Hairstyle      :integer  read FHairstyle       write FHairstyle;
    property HairColor      :integer  read FHairColor       write FHairColor;
    property Cheater        :byte     read FCheater         write FCheater;
    property Experience     :integer  read FExperience      write FExperience;
    property FameLevel      :integer  read FFameLevel       write FFameLevel;
    property FameExp        :integer  read FFameExp         write FFameExp;
    property Health         :TL2Float read FHealth          write FHealth;
    property HealthBonus    :integer  read FHealthBonus     write FHealthBonus;
    property Mana           :TL2Float read FMana            write FMana;
    property ManaBonus      :integer  read FManaBonus       write FManaBonus;
    property PlayTime       :TL2Float read FPlayTime        write FPlayTime;
    property FreeSkillPoints:integer  read FFreeSkillPoints write FFreeSkillPoints;
    property FreeStatPoints :integer  read FFreeStatPoints  write FFreeStatPoints;
    property Strength       :integer  read FStrength        write FStrength;
    property Dexterity      :integer  read FDexterity       write FDexterity;
    property Vitality       :integer  read FVitality        write FVitality;
    property Focus          :integer  read FFocus           write FFocus;
    property Gold           :integer  read FGold            write FGold;
    property Scale          :TL2Float read FScale           write FScale;
    property Skin           :byte     read FSkin            write FSkin;

    property Spells[idx:integer ]:TTL2Spell  read GetSpell write SetSpell;
    property Skills:TL2IdValList read FSkills  write FSkills;
    property Items :TTL2ItemList read FItems  {write FItems};
  end;
type
  TTL2CharArray = array of TTL2Character;

function ReadCharData(AStream:TTL2Stream; IsChar:boolean=false; IsPet:boolean=false):TTL2Character;


implementation

uses
  tl2db;

//----- Init / Free -----

constructor TTL2Character.Create;
begin
  inherited;

  DataType:=dtChar;
end;

destructor TTL2Character.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Character.InternalClear;
var
  i:integer;
begin
  SetLength(FSkills,0);
  for i:=0 to High(FItems) do
    FItems[i].Free;
  SetLength(FItems,0);

  inherited;
end;

procedure TTL2Character.Clear;
begin
  InternalClear;

  Inherited;
end;

//----- Properties -----

function TTL2Character.GetDBMods():string;
begin
  if FDBMods='' then
  begin
    if      FIsChar then FDBMods:=GetClassMods(FID)
    else if FIsPet  then FDBMods:=GetPetMods(FID)
    else                 FDBMods:=GetMobMods(FID);
  end;
  result:=FDBMods;
end;

function TTL2Character.GetStat(const iname:string):TL2Integer;
var
  i:integer;
begin

  i:=GetStatIdx(Stats,iname);
  if i>=0 then
    result:=Stats[i].value
  else
    result:=0;
end;

procedure TTL2Character.SetStat(const iname:string; aval:TL2Integer);
var
  i:integer;
begin
  i:=GetStatIdx(Stats,iname);
  if i>=0 then
    Stats[i].value:=aval;
end;

function TTL2Character.GetSpell(idx:integer):TTL2Spell;
begin
  if idx in [0..3] then
  begin
    result.name :=FSpells[idx].name;
    result.level:=FSpells[idx].level;
  end
  else
  begin
    result.name :='';
    result.level:=0;
  end;
end;

procedure TTL2Character.SetSpell(idx:integer; const aspell:TTL2Spell);
begin
  if idx in [0..3] then
  begin
    FSpells[idx].name :=aspell.name;
    FSpells[idx].level:=aspell.level;
  end;
end;

//----- Load / Save -----

procedure TTL2Character.LoadFromStream(AStream: TTL2Stream);
var
  i:integer;
//  isPet:boolean;
begin
DbgLn('start char');
  DataSize  :=AStream.ReadDWord;
  DataOffset:=AStream.Position;

  // signature
  // can be word+byte, can be 3 bytes. last looks like bool
  FSign    :=AStream.ReadByte;  // $FF or 02
  FSign1   :=Check(AStream.ReadByte,'sign 1 '+HexStr(AStream.Position,8),0);  // 0
  FSign2   :=Check(AStream.ReadByte,'sign 2 '+HexStr(AStream.Position,8),0);  // 0 or (sometime)
  {
    1 - hidden?
  }
	
  FMorphId:=TL2ID(AStream.ReadQWord);    // current Class ID (with sex)
  FID     :=TL2ID(AStream.ReadQword);    // *$FF or base class id (if morphed)
  if FID=TL2IdEmpty then
  begin
    FID     :=FMorphId;
    FMorphId:=TL2IdEmpty;
  end;

  FUnkn1:=TL2ID(AStream.ReadQword);    //!! (changing) (F6ED2564.F596F9AA)

  FUnkn2:=Check(AStream.ReadByte,'pre-wardrobe_'+HexStr(AStream.Position,8),0);
{
  1 for some mobs
}
  FWardrobe:=AStream.ReadByte<>0;     // not sure but why not?
  if FWardrobe then
  begin
    FFace     :=AStream.ReadDWord;    // face
    FHairStyle:=AStream.ReadDWord;    // hairstyle
    FHairColor:=AStream.ReadDWord;    // haircolor (+bandana for outlander)
    // !!*$FF = 36
    AStream.Read(FWardUnkn,36);
{
    AStream.ReadQWord;
    AStream.ReadQWord;
    AStream.ReadQWord;
    AStream.ReadQWord;
    AStream.ReadDWord;
}
  end;
  //??
  FUnkn3:=Check(AStream.ReadDWord,'pre-pet enabled_'+HexStr(AStream.Position,8),0);    // 0
{
  22 for one NPC
}
  FEnabled:=AStream.ReadByte<>0; // 1 (pet - enabled)
  //??
  FUnkn4:=Check(AStream.ReadWord,'post-pet enabled_'+HexStr(AStream.Position,8),0);
{
  256 for [quest] boss bloatfang, alpha...
  1 for invisibleturretmonster, snake Cacklespit
  AStream.ReadByte;     // 0 ??non-cross
  AStream.ReadByte;     // 0 ??BOSS??
}

//  if FWardrobe then //!! YES, i know, i know!!!
  if FIsChar then
    FCheater:=AStream.ReadByte; //!!!! cheat (67($43) or 78($4E)[=elfly] no cheat, 214($D6) IS cheat
  //??  :24 for pet, :55 for char
  FUnkn5:=Check(AStream.ReadByte,'after cheat_'+HexStr(AStream.Position,8),0);
  // pet: elfly=4, lonelfly=0, rage=0
  {mobs: 0 or 4
  barricade=6, invturretmonster,statue,
  }

  FMorphTime:=AStream.ReadFloat;   // pet morph time, sec
  FTownTime :=AStream.ReadFloat;   // time to town, sec
  FAction   :=TTL2Action(AStream.ReadDWord);  // 1  (pet status)
  //??
  FUnkn6:=Check(AStream.ReadDWord,'before scale_'+HexStr(AStream.Position,8),1);    // 1
{
  0 for horse, frog and snake
  2 for mobs
  7 for Barricade, statue
}
  FScale:=AStream.ReadFloat;   // scale (1.0 for char) (pet size)
  //??
  AStream.Read(FUnkn7,24);
{
  AStream.ReadQWord;    // ? player = FFFFFFFF, pet - no
  AStream.ReadQWord;    // -1
  AStream.ReadQWord;    // -1
}
  // can it be a name hash?
  FUnkn17:=AStream.ReadDWord;
//  isPet:=(FUnkn17=$FFFFFFFF); //  const. elfly=69DF417B ?? if not -1 then "player" presents

  FName  :=AStream.ReadShortString();    // :55(pet) Char name
DbgLn('name:'+string(widestring(fname)));
  FSuffix:=AStream.ReadShortString();    // like mob title "(Teleporting)"
  if FIsChar{not isPet} then                      // maybe this is "PLAYERMAPICONS" from GLOBALS.DAT?
    FPlayer:=AStream.ReadShortString();  // "PLAYER" (prefix) !!!!! not exists for pets!!!!!!
  //??
  FUnkn9:=AStream.ReadQWord;
{
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0 (SEE: Statistic=unknown) elfly=7, rage=2, lonelfly=2, zorro=0
}
  AStream.Read(FOrientation,SizeOf(FOrientation));

  FLevel      :=AStream.ReadDWord;    // level
  FExperience :=AStream.ReadDWord;    // exp
  FFameLevel  :=AStream.ReadDWord;    // fame level
  FFameExp    :=AStream.ReadDWord;    // fame exp
  FHealth     :=AStream.ReadFloat;    // current HP
  FHealthBonus:=AStream.ReadDWord;    // health bonus (pet=full hp)
  FUnkn11:=Check(AStream.ReadDWord,'stat_'+HexStr(AStream.Position,8),0);  // 0 ?? charge maybe? or armor?
  FMana       :=AStream.ReadFloat;    // current MP
  FManaBonus  :=AStream.ReadDWord;    // Mana bonus   (pet=full mp)
  //??
  AStream.Read(FUnkn12,12);
{
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0
  AStream.ReadDWord;    // 0
}
  FPlayTime:=AStream.ReadFloat;    // play time, sec
  FUnkn13:=Check(AStream.ReadFloat,'afterplaytime',1.0);      // 1.0
  {
  barricade,statue,frog=0 (but not snake)
  }

  FFreeStatPoints :=AStream.ReadDWord; // unallocated statpoints ? (elfly have 35 with 30 in fact)
  FFreeSkillPoints:=AStream.ReadDWord; // unallocated skillpoints? (elfly have 28 with 28 in fact)

  // mouse button skils.
  FRMB1:=TL2ID(AStream.ReadQWord);    // skill ID RMB active = Pet 1st spell?
  FRMB2:=TL2ID(AStream.ReadQWord);    // skill ID RMB secondary
  FLMB :=TL2ID(AStream.ReadQWord);    // skill ID LMB
  // second weapon set (!!!!!!!!!) not for pets
  FARMB1:=TL2ID(AStream.ReadQWord);    // skill ID RMB active
  FARMB2:=TL2ID(AStream.ReadQWord);    // skill ID RMB secondary
  FALMB :=TL2ID(AStream.ReadQWord);    // skill ID LMB
{  Pet: 6x4b = Nizza: 27BA7400, 27BA6E00,

}
  // CURRENT Skill list. depends of current weapon (passive mainly)
  FSkills:=AStream.ReadIdValList;

  // Spell list
  for i:=0 to 3 do
  begin
    FSpells[i].name :=AStream.ReadShortString; // spell name
    FSpells[i].level:=AStream.ReadDWord;       // spell level
  end;

  //!!-- 28 bytes
  // something defensive/offensive? Physical, [Magical,] Fire, Ice, Electric, Poison, All
  AStream.Read(Funkn14,28);
{
  AStream.ReadQWord;    // 0 same as pets
  AStream.ReadDWord;    // 0, Elfly pet = $0197 (407)
  AStream.ReadDWord;    // 0, Elfly pet = $0197
  AStream.ReadDWord;    // 0, Elfly pet = $0197
  AStream.ReadDWord;    // 0, Elfly pet = $0197
  AStream.ReadDWord;    // 0 same as pets
}
  FStrength :=AStream.ReadDWord;    // strength      0 for pet
  FDexterity:=AStream.ReadDWord;    // dexterity     0 for pet
  FVitality :=AStream.ReadDWord;    // vitality      10\ sure, pet have hp/mp bonuses
  FFocus    :=AStream.ReadDWord;    // focus         10/
  FGold     :=AStream.ReadDWord;    // gold          0
  //??
  AStream.Read(Funkn15,16);
{
  AStream.ReadDWord;    // $FF=-1 / 1/0 (elfly)      0
  AStream.ReadQWord;    // FF same as pets
  AStream.ReadDWord;    // FF same as pets
}
  FSkin:=AStream.ReadByte;  // FF OR pet texture (color)

  // mod id list
  FModIds:=AStream.ReadIdList;

  //----- item list -----

  FItems:=ReadItemList(AStream);

  //----- Effects -----
  // dynamic,passive,transfer

  FEffects1:=ReadEffectList(AStream,true);
  FEffects2:=ReadEffectList(AStream,true);
  FEffects3:=ReadEffectList(AStream,true);

  FAugments:=AStream.ReadShortStringList;
  
  //----- STATS -----

{ two base:
  CURRENT_PLAYER_STAT_PTS  - unallocated stat points
  CURRENT_PLAYER_SKILL_PTS - unallocated skill points
  multiply_hotbar adds SELECTED_HOTBAR stat
}
  FStats:=AStream.ReadIdValList;

  //----- Fixes -----

  if FIsChar then
  begin
    i:=GetStatIdx(FStats,DefaultStats[DefStatStat].id);
    if i>=0 then
    begin
      if      FFreeStatPoints<FStats[i].value then FFreeStatPoints:=FStats[i].value
      else if FFreeStatPoints>FStats[i].value then FStats[i].value:=FFreeStatPoints;
    end;
    i:=GetStatIdx(FStats,DefaultStats[DefStatSkill].id);
    if i>=0 then
    begin
      if      FFreeSkillPoints<FStats[i].value then FFreeSkillPoints:=FStats[i].value
      else if FFreeSkillPoints>FStats[i].value then FStats[i].value:=FFreeSkillPoints;
    end;
  end;

DbgLn('end char'#13#10'---------');
  LoadBlock(AStream);
end;

procedure TTL2Character.SaveToStream(AStream: TTL2Stream);
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

  //----- Fixes -----

  if FIsChar then
  begin
    i:=GetStatIdx(FStats,DefaultStats[DefStatStat].id);
    if i>=0 then
    begin
      if      FFreeStatPoints<FStats[i].value then FFreeStatPoints:=FStats[i].value
      else if FFreeStatPoints>FStats[i].value then FStats[i].value:=FFreeStatPoints;
    end;
    i:=GetStatIdx(FStats,DefaultStats[DefStatSkill].id);
    if i>=0 then
    begin
      if      FFreeSkillPoints<FStats[i].value then FFreeSkillPoints:=FStats[i].value
      else if FFreeSkillPoints>FStats[i].value then FStats[i].value:=FFreeSkillPoints;
    end;
  end;

  // signature
  AStream.WriteByte(FSign );  // $FF or 2
  AStream.WriteByte(FSign1);  // 0
  AStream.WriteByte(FSign2);  // 0, or 1

  if FMorphId=TL2IdEmpty then
  begin
    AStream.WriteQWord(QWord(FID));
    AStream.WriteQWord(QWord(TL2IdEmpty));
  end
  else
  begin
    AStream.WriteQWord(QWord(FMorphId));
    AStream.WriteQWord(QWord(FID));
  end;
  AStream.WriteQWord(QWord(FUnkn1));    //!! (changing) (F6ED2564.F596F9AA)

  AStream.WriteByte(FUnkn2);
  AStream.WriteByte(byte(FWardrobe) and 1);
  if FWardrobe then // WARDROBE
  begin
    AStream.WriteDWord(FFace);       // face
    AStream.WriteDWord(FHairStyle);  // hairstyle
    AStream.WriteDWord(FHairColor);  // haircolor (+bandana for outlander)

    AStream.Write(FWardUnkn,36);
  end;

  AStream.WriteDWord(FUnkn3);
  AStream.WriteByte (byte(FEnabled) and 1);
  AStream.WriteWord (FUnkn4);

  if FIsChar{FWardrobe} then
    AStream.WriteByte(FCheater);

  AStream.WriteByte(FUnkn5);

  AStream.WriteFloat(FMorphTime);
  AStream.WriteFloat(FTownTime);     // time to town,sec?
  AStream.WriteDWord(ord(FAction));  // 1  (pet status)

  AStream.WriteDWord(FUnkn6);  // 1
  AStream.WriteFloat(FScale);  // scale (1.0 for char) (pet size)
  
  AStream.Write(FUnkn7,24);

  AStream.WriteDWord(FUnkn17);

  AStream.WriteShortString(FName); // :55(pet) Char name
  AStream.WriteShortString(FSuffix);
  if FIsChar{(FUnkn17<>$FFFFFFFF)} then
    AStream.WriteShortString(FPlayer);      // "PLAYER" !!!!! not exists for pets!!!!!!
  
  AStream.WriteQWord(FUnkn9);

  AStream.Write(FOrientation,SizeOf(FOrientation));

  AStream.WriteDWord(FLevel);        // level
  AStream.WriteDWord(FExperience);   // exp
  AStream.WriteDWord(FFameLevel);    // fame level
  AStream.WriteDWord(FFameExp);      // fame
  AStream.WriteFloat(FHealth);       // current HP
  AStream.WriteDWord(FHealthBonus);  // health bonus (pet=full hp)
  AStream.WriteDWord(FUnkn11);
  AStream.WriteFloat(FMana);         // current MP
  AStream.WriteDWord(FManaBonus);    // Mana bonus   (pet=full mp)

  AStream.Write(FUnkn12,12);

  AStream.WriteFloat(FPlayTime);        // play time, sec
  AStream.WriteFloat(FUnkn13);          // 1.0
  AStream.WriteDWord(FFreeStatPoints ); // unallocated statpoints ? (elfly have 35 with 30 in fact)
  AStream.WriteDWord(FFreeSkillPoints); // unallocated skillpoints? (elfly have 28 with 28 in fact)

  // mouse button skils
  AStream.WriteQWord(QWord(FRMB1));    // skill ID RMB active = Pet 1st spell?
  AStream.WriteQWord(QWord(FRMB2));    // skill ID RMB secondary
  AStream.WriteQWord(QWord(FLMB));     // skill ID LMB
  // second weapon set
  AStream.WriteQWord(QWord(FARMB1));   // skill ID RMB active
  AStream.WriteQWord(QWord(FARMB2));   // skill ID RMB secondary
  AStream.WriteQWord(QWord(FALMB));    // skill ID LMB

  // CURRENT Skill list. depends of current weapon (passive mainly)
  AStream.WriteIdValList(FSkills);

  // Spell list
  for i:=0 to 3 do
  begin
    AStream.WriteShortString(FSpells[i].name ); // spell name
    AStream.WriteDWord      (FSpells[i].level); // spell level
  end;

  AStream.Write(FUnkn14,28);

  AStream.WriteDWord(FStrength );    // strength      0 for pet
  AStream.WriteDWord(FDexterity);    // dexterity     0 for pet
  AStream.WriteDWord(FVitality );    // vitality      10\ sure, pet have hp/mp bonuses
  AStream.WriteDWord(FFocus    );    // focus         10/
  AStream.WriteDWord(FGold     );    // gold          0

  AStream.Write(FUnkn15,16);

  AStream.WriteByte(FSkin); // FF OR pet texture (color)

  // mod id list
  AStream.WriteIdList(FModIds);

  WriteItemList(AStream,FItems);

  //----- Effects -----
  // dynamic,passive,transfer

  WriteEffectList(AStream,FEffects1);
  WriteEffectList(AStream,FEffects2);
  WriteEffectList(AStream,FEffects3);

  AStream.WriteShortStringList(FAugments);
  
  //----- STATS -----

  AStream.WriteIdValList(FStats);

  LoadBlock(AStream);
  FixSize  (AStream);
end;

function ReadCharData(AStream:TTL2Stream; IsChar:boolean=false; IsPet:boolean=false):TTL2Character;
begin
  result:=TTL2Character.Create();
  result.FIsChar:=IsChar;
  result.FIsPet :=IsPet;
  try
    result.LoadFromStream(AStream);
  except
    if IsConsole then writeln('got char exception at ',HexStr(result.DataOffset,8));
    AStream.Position:=result.DataOffset+result.DataSize;
  end;
end;

//----- Other -----

function TTL2Character.CheckForMods(alist:TTL2ModList):boolean;
begin
  result:=inherited CheckForMods(alist);

  // really, "not char" means "just pet" here
  // means, ModIds is nil
  // so, we just replace pet type by one of standard type
  if not (result or FIsChar) then
  begin
    FID:=GetDefaultPet();
    Changed:=true;
    result:=true;
  end;
end;

end.
