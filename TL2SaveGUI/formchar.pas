unit formChar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  Spin, ExtCtrls, Buttons, Grids, SpinEx,
  rgglobal, tl2save, tl2char, tl2db, formSkills, formItems, formEffects;

type
  tCharInfoType = (ciPlayer, ciPet, ciUnit);

  { TfmChar }

  TfmChar = class(TForm)
    bbUpdate: TBitBtn;
    lblCustomClass: TLabel;
    pnlTop: TPanel;
    pcCharInfo: TPageControl;

    // Stats
    tsStat: TTabSheet;

    cbKeepBase: TCheckBox;
    gbBaseStats: TGroupBox;
    seStrength : TSpinEditEx;  lblStrength  : TLabel;
    seDexterity: TSpinEditEx;  lblDexterity : TLabel;
    seFocus    : TSpinEditEx;  lblFocus     : TLabel;
    seVitality : TSpinEditEx;  lblVitality  : TLabel;

    seFreePoints: TSpinEditEx; lblFreePoints: TLabel;
    cbCheckPoints: TCheckBox;

    gbData: TGroupBox;
    seLevel: TSpinEditEx;  lblLevel     : TLabel;
    seFame : TSpinEditEx;  lblFame      : TLabel;
    edGold       : TEdit;  lblGold      : TLabel;
    edExperience : TEdit;  lblExperience: TLabel;
    edFameExp    : TEdit;  lblFameExp   : TLabel;
    edHealth     : TEdit;  lblHealth    : TLabel;
    edHealthBonus: TEdit;  lblHeathBonus: TLabel;
    edMana       : TEdit;  lblMana      : TLabel;
    edManaBonus  : TEdit;  lblManaBonus : TLabel;
    lblDataNote: TLabel;

    gbGlobal: TGroupBox;
    cbDifficulty: TComboBox;  lblDifficulty: TLabel;
    cbNGState   : TComboBox;  lblNGState   : TLabel;
    cbHardcore  : TCheckBox;

    // View
    tsView: TTabSheet;
    imgIcon : TImage;
    imgMorph: TImage;

    gbGender: TGroupBox;
    rbMale  : TRadioButton;
    rbFemale: TRadioButton;
    rbUnisex: TRadioButton;

    edName: TEdit;  lblName: TLabel;
    lblSuffix: TLabel;

    bbManual: TBitBtn;
    edClassId: TEdit;
    edNewClass: TEdit;
    edClass: TEdit;
    cbNewClass : TComboBox;  lblNew      : TLabel;
    cbMorph    : TComboBox;  lblCurrent  : TLabel;
    edMorphTime: TEdit;      lblMorphTime: TLabel;  lblMorphNote: TLabel;
    seScale: TFloatSpinEdit;  lblScale: TLabel;

    cbCheater: TCheckBox;

    // Wardrobe
    tsWardrobe: TTabSheet;
    edSkin: TEdit;  lblSkin: TLabel;  cbSkins: TComboBox;

    gbWardrobe: TGroupBox;

    // Action
    tsAction: TTabSheet;
    cbEnabled: TCheckBox;

    gbAction: TGroupBox;
    rbActionIdle   : TRadioButton;
    rbActionAttack : TRadioButton;
    rbActionDefence: TRadioButton;

    gbSpells: TGroupBox;
    Image1: TImage;  cbSpell1: TComboBox;  cbSpellLvl1: TComboBox;
    Image2: TImage;  cbSpell2: TComboBox;  cbSpellLvl2: TComboBox;
    Image3: TImage;  cbSpell3: TComboBox;  cbSpellLvl3: TComboBox;
    Image4: TImage;  cbSpell4: TComboBox;  cbSpellLvl4: TComboBox;

    edTownTime: TEdit;  lblTownTime: TLabel;

    // Statistic
    tsStatistic: TTabSheet;

    sgStats: TStringGrid;

    gbCoords: TGroupBox;
    edX: TEdit;  lblX: TLabel;
    edY: TEdit;  lblY: TLabel;
    edZ: TEdit;  lblZ: TLabel;

    edArea    : TEdit;  lblArea    : TLabel;
    edWaypoint: TEdit;  lblWaypoint: TLabel;

    lbModList: TListBox; lblModList: TLabel;

    // Other
    tsOtherInfo: TTabSheet;

    // Items
    tsItems: TTabSheet;
    
    procedure bbManualClick(Sender: TObject);
    procedure bbUpdateClick(Sender: TObject);
    procedure cbKeepBaseClick(Sender: TObject);
    procedure seFreePointsChange(Sender: TObject);
    procedure sgStatsEditingDone(Sender: TObject);
    procedure StatChange(Sender: TObject);
    procedure cbCheckPointsClick(Sender: TObject);
    procedure cbSpellChange   (Sender: TObject);
    procedure cbSpellLvlChange(Sender: TObject);
    procedure cbMorphChange(Sender: TObject);
    procedure cbNewClassChange(Sender: TObject);
    procedure ToSetUpdate(Sender: TObject);
    procedure rbGenderClick(Sender: TObject);
    procedure seFameChange (Sender: TObject);
    procedure seLevelChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

  private
    FEffects:TfmEffects;

    OldCheckPointsState:boolean;

    FKind:tCharInfoType;
    FConfigured:boolean;

    FSkillForm:TfmSkills;
    FItems    :TfmItems;

    FSGame:TTL2SaveFile;
    FChar :TTL2Character;

    FClasses:tClassArray;
    FPets   :tPetArray;

    HPTier       :TIntegerDynArray;
    MPTier       :TIntegerDynArray;
    FStatPerLevel:integer;

    FLevel,FFame :integer;
    FStr,FBaseStr:integer;
    FDex,FBaseDex:integer;
    FInt,FBaseInt:integer;
    FVit,FBaseVit:integer;

    FFreeStatPoints:integer;
    FUserStatPoints:integer;

    procedure DrawCharIcon(const aname: string; aImg: TImage);
    procedure DrawIconInt(const aname, adir: string; aImg: TImage);
    procedure DrawPetIcon(aclass: TRGID; aImg: TImage);
    procedure FillClassCombo();
    procedure FillPetInfo;
    procedure FillPlayerInfo;
    procedure FixPlayerInfo;
    function GetClassIndex(id: TRGID): integer;

    function GetMainFlag:boolean;
    procedure SetupVisualPart;

    procedure SetCharSpell(cb: TComboBox; idx: integer);
    procedure GetCharSpell(cb: TComboBox; idx: integer);
    procedure InitSpellBlock;
    function SearchAltGender(aclass: TRGID; out aname: string): integer;
    procedure UpdatePetInfo();
    procedure UpdatePlayerInfo();

    procedure PreCalcStat;
    procedure RecalcFreePoints;
    procedure SetConfigured(aval:boolean);

  public
    constructor Create(AOwner:TComponent; atype:tCharInfoType); overload;
    procedure FillInfo(aChar:TTL2Character; aSGame:TTL2SaveFile=nil);

    property IsMain    :boolean   read GetMainFlag;
    property Configured:boolean   read FConfigured write SetConfigured;
    property SkillForm :TfmSkills read FSkillForm  write FSkillForm;
  end;

var
  fmChar: TfmChar;

implementation

{$R *.lfm}

uses
  INIFiles,
  addons,
  formSettings,
  unitGlobal;

resourcestring
  rsStrength   = 'Strength';
  rsDexterity  = 'Dexterity';
  rsFocus      = 'Focus';
  rsVitality   = 'Vitality';

  rsCasual  = 'Casual';
  rsNormal  = 'Normal';
  rsVeteran = 'Veteran';
  rsExpert  = 'Expert';

  rsMale   = 'male';
  rsFemale = 'female';

const
  sStats       = 'Stats';
  sCheckPoints = 'checkpoints';

const
  dirSpellIcon = 'skills'; // 'spells';
  dirCharIcon  = 'characters';
  dirPetIcon   = 'pets';

//----- Support -----

function TfmChar.GetMainFlag:boolean;
begin
  result:=(FChar.Sign=$FF);
end;

procedure TfmChar.ToSetUpdate(Sender: TObject);
begin
  bbUpdate.Enabled:=true;
end;

procedure TfmChar.SetConfigured(aval:boolean);
begin
  FConfigured:=aval;
  SkillForm.Configured:=false;
end;

//--- Class change ---

procedure TfmChar.FillClassCombo();
var
  ls:string;
  i:integer;
begin
  cbNewClass.Clear;
  cbNewClass.Sorted:=true;
  cbNewClass.Items.BeginUpdate;
  cbNewClass.Items.Capacity:=Length(FClasses); //??

  for i:=0 to High(FClasses) do
  begin
    ls:=FClasses[i].title;
    if ls='' then continue;

    if (rbMale  .Checked and (FClasses[i].gender='M')) or
       (rbFemale.Checked and (FClasses[i].gender='F')) then
    begin
      cbNewClass.Items.AddObject(FClasses[i].title,TObject(IntPtr(i)));
    end
    else if rbUnisex.Checked then
    begin
      if      FClasses[i].gender='M' then ls:=ls+' ('+rsMale  +')'
      else if FClasses[i].gender='F' then ls:=ls+' ('+rsFemale+')';
      cbNewClass.Items.AddObject(ls,TObject(IntPtr(i)));
    end;
  end;
  cbNewClass.Items.EndUpdate;
end;

function TfmChar.GetClassIndex(id:TRGID):integer;
var
  i:integer;
begin
  for i:=0 to High(FClasses) do
  begin
    if FClasses[i].id=id then
    begin
      result:=i;
      exit;
    end;
  end;
  result:=-1;
end;

function TfmChar.SearchAltGender(aclass:TRGID; out aname:string):integer;
var
  ls:string;
  i,idx:integer;
begin
  result:=-1;
  // 1 - search source index
  idx:=GetClassIndex(aclass);
  if idx<0 then exit; // MUST NOT happend

  // 2 - check alter name
  aname:=FClasses[idx].name;
  i:=Length(aname);
  if (i>2) and (aname[i-1]='_') then
  begin
    if      aname[i]='F' then aname[i]:='M'
    else if aname[i]='M' then aname[i]:='F'
    else i:=-1;
  end;
  // 3 - search alter index
  if i>0 then
  begin
    for i:=0 to High(FClasses) do
    begin
      if FClasses[i].name=aname then
      begin
        result:=i;
        exit;
      end;
    end;
  end;
  // 4 - check by titles
  ls:=FClasses[idx].title;
  for i:=0 to High(FClasses) do
  begin
    if (FClasses[i].title=ls) and
       (FClasses[i].id<>aclass) then
    begin
      // really, need to check both mod list too
      aname:=FClasses[i].name;
      result:=i;
      exit;
    end;
  end;
end;

procedure TfmChar.rbGenderClick(Sender: TObject);
var
  lname:string;
  idx,i:integer;
begin
  if not FConfigured then exit;

  if cbNewClass.ItemIndex<0 then
  begin
    idx:=-1;
    lname:=FSGame.ClassString;
    i:=Length(FSGame.ClassString);
    if (i>2) and (FSGame.ClassString[i-1]='_') then
    begin
      if      rbFemale.Checked then lname[i]:='F'
      else if rbMale  .Checked then lname[i]:='M';
    end;
  end
  else
  begin
    idx:=IntPtr(cbNewClass.Items.Objects[cbNewClass.ItemIndex]);
    if (rbMale  .Checked and (FClasses[idx].gender='F')) or
       (rbFemale.Checked and (FClasses[idx].gender='M')) then
      idx:=SearchAltGender(FClasses[idx].id,lname);
  end;

  FillClassCombo();
  if idx>=0 then
    for i:=0 to cbNewClass.Items.Count-1 do
    begin
      if IntPtr(cbNewClass.Items.Objects[i])=idx then
      begin
        cbNewClass.ItemIndex:=i;
        cbNewClassChange(Sender);
        break;
      end;
    end;

  if cbNewClass.ItemIndex<0 then edNewClass.Text:=lname;


  if not rbUnisex.Checked then
    bbUpdate.Enabled:=true;
end;

procedure TfmChar.bbManualClick(Sender: TObject);
var
  i,idx:integer;
begin
  cbNewClass.ItemIndex:=-1;
   for i:=0 to cbNewClass.Items.Count-1 do
   begin
     idx:=IntPtr(cbNewClass.Items.Objects[i]);
     if FClasses[idx].name=edNewClass.Text then
     begin
       cbNewClass.ItemIndex:=i;
       break;
     end;
   end;
  cbNewClassChange(Sender);
end;

procedure TfmChar.cbNewClassChange(Sender: TObject);
var
  licon:string;
  idx:integer;
begin
  if cbNewClass.ItemIndex>=0 then
    idx:=IntPtr(cbNewClass.Items.Objects[cbNewClass.ItemIndex])
  else
    idx:=-1;

  if FChar.IsChar then
  begin

    if idx>=0 then
    begin
      edNewClass.Text:=FClasses[idx].name;
      FSkillForm.PlayerClass:=FClasses[idx].id;
      licon:=FClasses[idx].icon;
    end
    else
      licon:='';

    DrawCharIcon(licon,imgIcon);
  end;

  if FChar.IsPet then
  begin
    if idx>=0 then
    begin
      DrawPetIcon(FPets[idx].id,imgIcon);
      if cbMorph.ItemIndex=0 then
        seScale.Value:=FPets[idx].scale;
    end;
  end;

  bbUpdate.Enabled:=true;
end;

procedure TfmChar.DrawIconInt(const aname,adir:string; aImg:TImage);
var
  licon:string;
begin
  licon:=SearchForFileName(fmSettings.edIconDir.Text+'\'+adir+'\',UpCase(aname));

  if licon<>'' then
  begin
    try
      aImg.Picture.LoadFromFile(licon);
    except
      licon:='';
    end;
  end;

  if licon='' then
    try
      aImg.Picture.LoadFromFile(fmSettings.edIconDir.Text+'\unknown.png');
    except
      aImg.Picture.Clear;
    end;
end;

//--- Player ---

procedure TfmChar.DrawCharIcon(const aname:string; aImg:TImage);
begin
  DrawIconInt(aname,dirCharIcon,aImg);
end;

procedure TfmChar.StatChange(Sender: TObject);
var
  lval:integer;
  pStat:PInteger;
begin
  lval:=(Sender as TSpinEditEx).Value;

  if      Sender=seStrength  then pStat:=@FStr
  else if Sender=seDexterity then pStat:=@FDex
  else if Sender=seFocus     then pStat:=@FInt
  else{if Sender=seVitality  then}pStat:=@FVit;

  if lval=pStat^ then exit;

  bbUpdate.Enabled:=true;
  pStat^:=lval;

  RecalcFreePoints;
end;

procedure TfmChar.seFameChange(Sender: TObject);
begin
  if FFame<>seFame.Value then
  begin
    bbUpdate.Enabled:=true;
    if seFame.Value=0 then
      edFameExp.Text:='0'
    else
      edFameExp.Text:=IntToStr(FameGate[seFame.Value-1]+1);
    FFame:=seFame.Value;

    if FSkillForm<>nil then FSkillForm.Fame:=FFame;
  end;
end;

procedure TfmChar.cbCheckPointsClick(Sender: TObject);
begin
  if (FFreeStatPoints<=0) and cbCheckPoints.Checked then
  begin
    seStrength .MaxValue:=seStrength .Value;
    seDexterity.MaxValue:=seDexterity.Value;
    seFocus    .MaxValue:=seFocus    .Value;
    seVitality .MaxValue:=seVitality .Value;
  end
  else
  begin
    seStrength .MaxValue:=999;
    seDexterity.MaxValue:=999;
    seFocus    .MaxValue:=999;
    seVitality .MaxValue:=999;
  end;
end;

procedure TfmChar.seFreePointsChange(Sender: TObject);
begin
  if FFreeStatPoints<>seFreePoints.Value then
  begin
    FFreeStatPoints:=seFreePoints.Value;
    bbUpdate.Enabled:=true;
    PreCalcStat;
  end;
end;

procedure TfmChar.sgStatsEditingDone(Sender: TObject);
begin
  bbUpdate.Enabled:=true;
end;

//--- Common ---

procedure TfmChar.seLevelChange(Sender: TObject);
begin
  if FLevel<>seLevel.Value then
  begin
    bbUpdate.Enabled:=true;
    if seLevel.Value=1 then
      edExperience.Text:='0'
    else
      edExperience.Text:=IntToStr(ExpGate[seLevel.Value-2]+1);

    FLevel:=seLevel.Value;
    if FChar.IsChar then
    begin
      RecalcFreePoints;

      edHealthBonus.Text:=IntToStr((HPTier[seLevel.Value-1]+5) div 10);
      edManaBonus  .Text:=IntToStr((MPTier[seLevel.Value-1]+5) div 10);
    end;

    if FSkillForm<>nil then FSkillForm.Level:=FLevel;
  end;
end;

//--- Pet ---

procedure TfmChar.DrawPetIcon(aclass:TRGID; aImg:TImage);
begin
  DrawIconInt(GetPetIcon(aclass),dirPetIcon,aImg);
end;

procedure TfmChar.cbMorphChange(Sender: TObject);
var
  idx:integer;
begin
  idx:=IntPtr(cbMorph.Items.Objects[cbMorph.ItemIndex]);
  if idx<0 then
  begin
    imgMorph.Picture.Clear;
    idx:=IntPtr(cbNewClass.Items.Objects[cbNewClass.ItemIndex]);
  end
  else
  begin
    DrawPetIcon(FPets[idx].id,imgMorph);
  end;
  seScale.Value:=FPets[idx].scale;

  bbUpdate.Enabled:=true;
end;

//----- Spell block -----

procedure TfmChar.cbSpellChange(Sender: TObject);
var
  cb:TComboBox;
  licon:string;
  i,idx:integer;
begin
  bbUpdate.Enabled:=true;

  with (Sender as TComboBox) do
  begin
    cb:=TComboBox(Tag);
    cb.Clear;
    TImage(cb.Tag).Picture.Clear;
    if ItemIndex>0 then
    begin
      idx:=IntPtr(Items.Objects[ItemIndex]);
      if idx>=0 then
      begin
        for i:=1 to SpellList[idx].level do
          cb.Items.AddObject(IntToStr(i),TObject(IntPtr(i)));
        cb.ItemIndex:=0;

        licon:=SearchForFileName(fmSettings.edIconDir.Text+'\'+dirSpellIcon+'\',UpCase(SpellList[idx].icon));
        if licon<>'' then
          try
            TImage(cb.Tag).Picture.LoadFromFile(licon);
          except
          end;
      end;
    end;
  end;
end;

procedure TfmChar.cbSpellLvlChange(Sender: TObject);
begin
  bbUpdate.Enabled:=true;;
end;

procedure TfmChar.GetCharSpell(cb:TComboBox; idx:integer);
var
  lid:TRGID;
  lspell:TTL2Spell;
begin
  lspell:=FChar.Spells[idx];
  cb.Text:=GetTL2Skill(lspell.name,lid);
  cbSpellChange(cb);
  TComboBox(cb.Tag).Text:=IntToStr(lspell.level);
end;

procedure TfmChar.SetCharSpell(cb:TComboBox; idx:integer);
var
  lspell:TTL2Spell;
  lcb:TComboBox;
begin
  lcb:=TComboBox(cb.Tag);
  if (cb.ItemIndex>=0) and
     (IntPtr(cb.Items.Objects[cb.ItemIndex])>=0) then
  begin
    lspell.name :=SpellList[IntPtr( cb.Items.Objects[ cb.ItemIndex])].name;
    lspell.level:=          IntPtr(lcb.Items.Objects[lcb.ItemIndex]);
  end
  else
  begin
    lspell.name:=cb.Text;
    Val(lcb.Text,lspell.level);
  end;
  FChar.Spells[idx]:=lspell;
end;

procedure TfmChar.InitSpellBlock;
var
  i:integer;
begin
  cbSpell1.Clear;
  cbSpell1.Sorted:=true;
  cbSpell1.Items.BeginUpdate;
  cbSpell1.Items.Capacity:=Length(SpellList);
  cbSpell1.Items.AddObject('',TObject(-1));
  for i:=0 to High(SpellList) do
    cbSpell1.Items.AddObject(SpellList[i].title,TObject(IntPtr(i)));
  cbSpell1.Items.EndUpdate;

  cbSpell2.Items:=cbSpell1.Items;
  cbSpell3.Items:=cbSpell1.Items;
  cbSpell4.Items:=cbSpell1.Items;
{
  cbSpell2.Items.Assign(cbSpell1.Items);
  cbSpell3.Items.Assign(cbSpell1.Items);
  cbSpell4.Items.Assign(cbSpell1.Items);
}
  GetCharSpell(cbSpell1,0);
  GetCharSpell(cbSpell2,1);
  GetCharSpell(cbSpell3,2);
  GetCharSpell(cbSpell4,3);
end;

//----- Form -----

procedure TfmChar.SetupVisualPart;
var
  lChar,lPet:boolean;
begin
  lChar:=FKind=ciPlayer;
  lPet :=FKind=ciPet;

  pnlTop.Visible:=lChar or lPet;

  // Stats
  gbGlobal     .Visible:=lChar;
  gbBaseStats  .Visible:=lChar;
  seFreePoints .Visible:=lChar;
  lblFreePoints.Visible:=lChar;
  lblDataNote  .Visible:=lChar;
  cbCheckPoints.Visible:=lChar;
  cbKeepBase   .Visible:=lChar;

  gbData.Enabled:=lChar or lPet;
  seFame.Enabled:=lChar;

  bbUpdate.Visible:=lChar or lPet;

  // View
  imgIcon   .Visible:=lChar or lPet;
  cbNewClass.Visible:=lChar or lPet;
  lblNew    .Visible:=lChar or lPet;

  cbCheater .Visible:=lChar;
  edNewClass.Visible:=lChar;
  bbManual  .Visible:=lChar;

  edName    .ReadOnly:=not (lChar or lPet);
  seScale   .ReadOnly:=not (lChar or lPet);

  // Wardrobe
  gbWardrobe  .Visible:=lChar;
  edSkin      .Visible:=lPet;
  lblSkin     .Visible:=lPet;
  cbSkins     .Visible:=false;//lPet;

  // Actions
  tsAction.TabVisible:=lChar or lPet;

  cbSpell1.Tag:=PtrUInt(cbSpellLvl1); cbSpellLvl1.Tag:=PtrUInt(Image1);
  cbSpell2.Tag:=PtrUInt(cbSpellLvl2); cbSpellLvl2.Tag:=PtrUInt(Image2);
  cbSpell3.Tag:=PtrUInt(cbSpellLvl3); cbSpellLvl3.Tag:=PtrUInt(Image3);
  cbSpell4.Tag:=PtrUInt(cbSpellLvl4); cbSpellLvl4.Tag:=PtrUInt(Image4);

  cbEnabled  .Visible:=lPet;
  gbAction   .Visible:=lPet;
  edTownTime .Visible:=lPet;
  lblTownTime.Visible:=lPet;

  // Statistic
  edArea     .Visible:=lChar;
  lblArea    .Visible:=lChar;
  edWaypoint .Visible:=lChar;
  lblWaypoint.Visible:=lChar;
  sgStats.Columns[1].ReadOnly:=not lChar;

  // Items
  tsItems.TabVisible:=not (lChar or lPet);
end;

procedure TfmChar.FormDestroy(Sender: TObject);
var
  config:TIniFile;
begin
  SetLength(FPets,0);
  SetLength(FClasses,0);

  SetLength(HPTier,0);
  SetLength(MPTier,0);

  if (FKind=ciPlayer) and (OldCheckPointsState<>cbCheckPoints.Checked) then
  begin
    config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
    config.WriteBool(sStats,sCheckPoints,cbCheckPoints.Checked);

    config.UpdateFile;
    config.Free;
  end;

end;

constructor TfmChar.Create(AOwner:TComponent; atype:tCharInfoType);
var
  config:TIniFile;
begin
  inherited Create(AOwner);

  FKind:=atype;
  FConfigured:=false;
  FItems:=nil;

  FEffects:=TfmEffects.Create(Self);
  FEffects.Parent :=tsOtherInfo;
  FEffects.Align  :=alClient;
  FEffects.Visible:=true;

  SetupVisualPart;

  case FKind of

    ciPlayer: begin
      config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
      cbCheckPoints.Checked:=config.ReadBool(sStats,sCheckPoints,true);
      OldCheckPointsState:=cbCheckPoints.Checked;
      config.Free;

      cbDifficulty.Clear;
      cbDifficulty.AddItem(rsCasual ,nil);
      cbDifficulty.AddItem(rsNormal ,nil);
      cbDifficulty.AddItem(rsVeteran,nil);
      cbDifficulty.AddItem(rsExpert ,nil);

      pcCharInfo.ActivePage:=tsView;
    end;

    ciPet: begin
      pcCharInfo.ActivePage:=tsView;
    end;

    ciUnit: begin
      FItems:=TfmItems.Create(self);
      FItems.Parent :=tsItems;
      FItems.Align  :=alClient;
      FItems.Visible:=true;

      pcCharInfo.ActivePage:=tsView;
    end;
  end;
end;

//----- Fill Info -----

procedure TfmChar.PreCalcStat;
begin
  FUserStatPoints:=
      FFreeStatPoints                         // Free  points
      -((FChar.Level-1)*FStatPerLevel)        // Bonus points
      -(FBaseStr+FBaseDex+FBaseInt+FBaseVit)  // Base  points
      +(FStr+FDex+FInt+FVit);                 // Used  points
end;

procedure TfmChar.RecalcFreePoints;
begin
  FFreeStatPoints:=
      FUserStatPoints
      +((FLevel-1)*FStatPerLevel)             // Bonus points
      +(FBaseStr+FBaseDex+FBaseInt+FBaseVit)  // Base  points
      -(FStr+FDex+FInt+FVit);                 // Used  points

  seFreePoints.Value:=FFreeStatPoints;

  cbCheckPointsClick(Self);
end;

procedure TfmChar.FixPlayerInfo;
var
  i:integer;
begin
  lbModList.Clear;
  for i:=0 to High(FChar.ModIds) do
    lbModList.AddItem(GetTL2Mod(FChar.ModIds[i]),nil);
end;

procedure TfmChar.FillPlayerInfo;
var
  licon,ls,ls1:string;
  i:integer;
begin
  //--- Stat ---

  GetClassInfo(FChar.ID,licon,FBaseStr,FBaseDex,FBaseInt,FBaseVit);

  seLevel.MaxValue:=Length(ExpGate);
  seFame .MaxValue:=Length(FameGate);
  seFame .MinValue:=1;

  // Graphs

  GetClassGraphStat(FChar.ID,ls,ls1,FStatPerLevel);
  HPTier:=GetGraphArray(ls );
  MPTier:=GetGraphArray(ls1);

  if Length(HPTier)=0 then
  begin
    SetLength(HPTier,100);
    for i:=0 to 99 do
      HPTier[i]:=DefaultHPbase+i*DefaultHPperLevel;
  end;
  if Length(MPTier)=0 then
  begin
    SetLength(MPTier,100);
    for i:=0 to 99 do
      MPTier[i]:=DefaultMPbase+i*DefaultMPperLevel;
  end;

  // Stats
  lblStrength .Caption:='('+IntToStr(FBaseStr)+') '+rsStrength;
  lblDexterity.Caption:='('+IntToStr(FBaseDex)+') '+rsDexterity;
  lblFocus    .Caption:='('+IntToStr(FBaseInt)+') '+rsFocus;
  lblVitality .Caption:='('+IntToStr(FBaseVit)+') '+rsVitality;

  // keep for Up/Down changes
  FStr:=FChar.Strength ; seStrength .Value:=FStr;
  FDex:=FChar.Dexterity; seDexterity.Value:=FDex;
  FInt:=FChar.Focus    ; seFocus    .Value:=FInt;
  FVit:=FChar.Vitality ; seVitality .Value:=FVit;

  FFreeStatPoints:=FChar.FreeStatPoints;
  seFreePoints.Value:=FFreeStatPoints;

  // To prevent Statpoints negative values
  cbCheckPointsClick(Self);
  PreCalcStat;

  edGold.Text:=IntToStr(FChar.Gold);

  // global
  cbNGState   .ItemIndex:=FSGame.NewGameCycle;
  cbDifficulty.ItemIndex:=ORD(FSGame.Difficulty);
  cbHardcore  .Checked  :=FSGame.Hardcore;

  //--- View ---

  GetClassList(FClasses);

  // set gender buttons
  i:=GetClassIndex(FChar.ID);
  if i>=0 then
  begin
    rbMale  .Checked:=FClasses[i].gender='M';
    rbFemale.Checked:=FClasses[i].gender='F';
    rbUnisex.Checked:=not (FClasses[i].gender in ['F','M']);

    edClass.Text:=GetTL2Class(FChar.ID);
  end
  else
  begin
    edClass.Text:=FSGame.ClassString;
    // trying to guess
    rbUnisex.Checked:=true;
    i:=Length(FSGame.ClassString);
    if (i>2) and (FSGame.ClassString[i-1]='_') then
    begin
      rbFemale.Checked:=FSGame.ClassString[i]='F';
      rbMale  .Checked:=FSGame.ClassString[i]='M';
    end;
  end;

  FillClassCombo();

  cbNewClass.Text:=edClass.Text;

  cbCheater.Checked:=FChar.Cheater=214;

  DrawCharIcon(licon,imgIcon);

  //----- Action

  InitSpellBlock();

  //--- Statistic ---

  edArea    .Text:=FSGame.Area;
  edWaypoint.Text:=FSGame.Waypoint;

  //--- Skill related ---

  FSkillForm.Configured :=false;
  FSkillForm.PlayerClass:=FChar.ID;
  FSkillForm.Player     :=FChar;
end;

procedure TfmChar.FillPetInfo;
var
  ls:string;
  i:integer;
begin
  //--- Stats ---

  seLevel.MaxValue:=Length(ExpGate);
  seFame .MaxValue:=1;

  //--- View ---

  GetPetList(FPets);


  cbNewClass.Clear;
  cbNewClass.Sorted:=true;
  cbNewClass.Items.BeginUpdate;
  cbNewClass.Items.Capacity:=Length(FPets);
  for i:=0 to High(FPets) do
  begin
    ls:=FPets[i].title;
    if ls='' then ls:=FPets[i].name
    else ls:=ls+ ' ('+FPets[i].name+')';
    cbNewClass.Items.AddObject(ls,TObject(IntPtr(i)));
  end;
  cbNewClass.Items.EndUpdate;
  cbNewClass.ItemIndex:=-1;

  for i:=0 to cbNewClass.Items.Count-1 do
    if FPets[IntPtr(cbNewClass.Items.Objects[i])].id=FChar.ID then
    begin
      cbNewClass.ItemIndex:=i;
      break;
    end;
//  cbNewClass.Enabled:=cbNewClass.ItemIndex>=0;

  if cbMorph.Visible then
  begin
    cbMorph.Items.Assign(cbNewClass.Items);
    cbMorph.Items.InsertObject(0,'',TObject(IntPtr(-1)));

    cbMorph.ItemIndex:=0;
    if (FChar.MorphId<>RGIdEmpty) and
       (FChar.MorphId<>FChar.ID) then
    begin
      for i:=1 to cbMorph.Items.Count-1 do
        if FPets[IntPtr(cbMorph.Items.Objects[i])].id=FChar.MorphId then
        begin
          DrawPetIcon(FChar.MorphId,imgMorph);
          cbMorph.ItemIndex:=i;
          break;
        end;
    end;
    if cbMorph.ItemIndex<=0 then imgMorph.Picture.Clear;

    edMorphTime.Text:=IntToStr(Round(FChar.MorphTime));
  end;

  DrawPetIcon(FChar.ID,imgIcon);

  edClass.Text:=GetTL2Pet(FChar.ID);
  if edClass.Text=HexStr(FChar.ID,16) then
     edClass.Text:=GetTL2Mob(FChar.ID);

  //--- Wardrobe ---

  edSkin.Text:=IntToStr(ShortInt(FChar.Skin));

  //--- Action ---

  cbEnabled.Checked:=FChar.Enabled;
  edTownTime.Text:=IntToStr(round(FChar.TownTime));

  rbActionIdle   .Checked:=FChar.Action=Idle;
  rbActionAttack .Checked:=FChar.Action=Attack;
  rbActionDefence.Checked:=FChar.Action=Defence;

  if not FConfigured then
    InitSpellBlock();

  //--- Statistic ---

end;

procedure TfmChar.FillInfo(aChar:TTL2Character; aSGame:TTL2SaveFile=nil);
var
  ls:string;
  i:integer;
  lshowall,lChar,lPet:boolean;
begin
  if FConfigured and (FKind=ciPlayer) then
  begin
    FixPlayerInfo();
    exit;
  end;

  lshowall:=fmSettings.cbShowAll.Checked;
  lChar:=FKind=ciPlayer;
  lPet :=FKind=ciPet;

  // View
  edMorphTime .Visible:=lPet and lshowall;
  lblMorphTime.Visible:=lPet and lshowall;
  lblMorphNote.Visible:=lPet and lshowall;
  lblCurrent  .Visible:=lPet and lshowall;
  cbMorph     .Visible:=lPet and lshowall;
  imgMorph    .Visible:=lPet and lshowall;
  gbGender    .Visible:=lChar and lshowall;
  seScale     .Visible:=lshowall;
  lblScale    .Visible:=lshowall;
  // Wardrobe
  tsWardrobe.TabVisible:=(lChar or lPet) and lshowall;
  // Other
  tsOtherInfo.TabVisible:=lshowall;

  FSGame:=aSGame;
  FChar :=aChar;

  if      FChar.IsChar then FillPlayerInfo()
  else if FChar.IsPet  then FillPetInfo()
  else
  begin
    edClass.Text:=GetTL2Mob(FChar.ID);
    seLevel.MaxValue:=999;
    seFame .MaxValue:=1;
  end;

  //--- Stats ---

  FLevel:=FChar.Level    ; seLevel.Value:=FLevel;
  FFame :=FChar.FameLevel; seFame .Value:=FFame;

  edExperience .Text :=IntToStr(FChar.Experience);
  edFameExp    .Text :=IntToStr(FChar.FameExp);
  edHealth     .Text :=IntToStr(Round(FChar.Health));
  edHealthBonus.Text :=IntToStr(FChar.HealthBonus);
  edMana       .Text :=IntToStr(Round(FChar.Mana));
  edManaBonus  .Text :=IntToStr(FChar.ManaBonus);

  //--- View ---

  edName   .Text   :=FChar.Name;
  edClassId.Text   :=TextId(FChar.ID);
  lblSuffix.Caption:=FChar.Suffix;

  seScale.Value:=FChar.Scale;

  //--- Wardrobe ---

  //--- Action ---

  //--- Statistic ---

  edX.Text:=FloatToStrF(FChar.Coord.X,ffFixed,-8,2);
  edY.Text:=FloatToStrF(FChar.Coord.Y,ffFixed,-8,2);
  edZ.Text:=FloatToStrF(FChar.Coord.Z,ffFixed,-8,2);

  lbModList.Clear;
  for i:=0 to High(FChar.ModIds) do
    lbModList.AddItem(GetTL2Mod(FChar.ModIds[i]),nil);

  sgStats.BeginUpdate;
  sgStats.Clear;
  sgStats.RowCount:=1+Length(FChar.Stats);
  for i:=0 to High(FChar.Stats) do
  begin
    sgStats.Objects[0,i+1]:=TObject(IntPtr(i));
    sgStats.Cells[0,i+1]:=GetTL2Stat(FChar.Stats[i].id,ls);
    sgStats.Cells[1,i+1]:=IntToStr  (FChar.Stats[i].value);
    sgStats.Cells[2,i+1]:=GetTL2Mod(ls);
  end;

  sgStats.EndUpdate;

  //--- Other ---

  if tsOtherInfo.TabVisible then
    FEffects.FillInfo(FChar);

  //--- Items ---
  if tsItems.TabVisible then
    if FItems<>nil then
    begin
      FItems.FillInfo(FChar.Items, FChar);
    end;

  bbUpdate.Enabled:=false;
  FConfigured:=true;
//  seLevel.SetFocus;
end;

//----- Update -----

procedure TfmChar.UpdatePlayerInfo();
var
  i,idx:integer;
begin
  //--- Stats

  FChar.Strength  :=seStrength .Value;
  FChar.Dexterity :=seDexterity.Value;
  FChar.Focus     :=seFocus    .Value;
  FChar.Vitality  :=seVitality .Value;
  FChar.Gold      :=StrToIntDef(edGold.Text,0);

  if FFreeStatPoints>0 then
    FChar.FreeStatPoints:=FFreeStatPoints
  else
    FChar.FreeStatPoints:=0;

  // global
  FSGame.NewGameCycle:=cbNGState.ItemIndex;
  FSGame.Difficulty  :=TL2Difficulty(cbDifficulty.ItemIndex);
  FSGame.Hardcore    :=cbHardcore.Checked;

  //--- View

  if cbCheater.Checked then
    FChar.Cheater:=214
  else
    FChar.Cheater:=78;

  if cbNewClass.ItemIndex>=0 then
  begin
    i:=IntPtr(cbNewClass.Items.Objects[cbNewClass.ItemIndex]);
    FChar.ID:=FClasses[i].id;
    FSGame.ClassString:=FClasses[i].name;
  end
  else if edNewClass.Text<>'' then
    FSGame.ClassString:=edNewClass.Text;

  if FSkillForm.bbUpdate.Enabled then
    FSkillForm.bbUpdateClick(Self)
  else
  begin
    if FSkillForm.FreeSkillPoints>0 then
      FChar.FreeSkillPoints:=FSkillForm.FreeSkillPoints
    else
      FChar.FreeSkillPoints:=0;
  end;

  //--- Statistic
  if sgStats.Modified then
  begin
    for i:=1 to sgStats.RowCount-1 do
    begin
      idx:=IntPtr(sgStats.Objects[0,i]);
      Val(sgStats.Cells[1,i],FChar.Stats[idx].value);
    end;
  end;
end;

procedure TfmChar.UpdatePetInfo();
var
  idx:integer;
begin
  //--- View
  if cbNewClass.ItemIndex>=0 then
  begin
    FChar.ID:=FPets[IntPtr(cbNewClass.Items.Objects[cbNewClass.ItemIndex])].id;
  end;

  if cbMorph.Visible then
  begin
    idx:=IntPtr(cbMorph.Items.Objects[cbMorph.ItemIndex]);
    if idx>=0 then
      FChar.MorphId:=FPets[idx].id
    else
      FChar.MorphId:=RGIdEmpty;

    FChar.MorphTime:=StrToIntDef(edMorphTime.Text,0);
  end;

  //--- Wardrobe

  if tsWardrobe.TabVisible then
  begin
    FChar.Skin:=Byte(StrToIntDef(edSkin.Text,-1));
  end;

  //--- Action

  FChar.Enabled :=cbEnabled.Checked;
  FChar.TownTime:=StrToIntDef(edTownTime.Text,0);

  if      rbActionIdle   .Checked then FChar.Action:=Idle
  else if rbActionAttack .Checked then FChar.Action:=Attack
  else if rbActionDefence.Checked then FChar.Action:=Defence;

end;

procedure TfmChar.bbUpdateClick(Sender: TObject);
var
  ls:string;
begin
  ls:=Application.MainForm.Caption;
  ls[1]:='*';
  Application.MainForm.Caption:=ls;

  //--- Stat

  FChar.Level      :=seLevel.Value;
  FChar.FameLevel  :=seFame .Value;
  FChar.Experience :=StrToInt(edExperience .Text);
  FChar.FameExp    :=StrToInt(edFameExp    .Text);
  FChar.HealthBonus:=StrToInt(edHealthBonus.Text);
  FChar.ManaBonus  :=StrToInt(edManaBonus  .Text);
  FChar.Health     :=StrToIntDef(edHealth.Text,FChar.HealthBonus);
  FChar.Mana       :=StrToIntDef(edMana  .Text,FChar.ManaBonus);

  //--- View

  FChar.Name :=edName .Text;
  FChar.Scale:=seScale.Value;

  //--- Wardrobe

  //--- Action

  SetCharSpell(cbSpell1,0);
  SetCharSpell(cbSpell2,1);
  SetCharSpell(cbSpell3,2);
  SetCharSpell(cbSpell4,3);

  //--- Other

  //--- Statistic

  //--- Personal

  if FChar.IsChar then UpdatePlayerInfo();
  if FChar.IsPet  then UpdatePetInfo();

  bbUpdate.Enabled:=false;
  FChar.Changed:=true;
end;

procedure TfmChar.cbKeepBaseClick(Sender: TObject);
begin
  if cbKeepBase.Checked then
  begin
    //!! recalc value different
    seStrength .MinValue:=FBaseStr;
    seDexterity.MinValue:=FBaseDex;
    seFocus    .MinValue:=FBaseInt;
    seVitality .MinValue:=FBaseVit;
    //!! check what "OnChange" called
  end
  else
  begin
    seStrength .MinValue:=1;
    seDexterity.MinValue:=1;
    seFocus    .MinValue:=1;
    seVitality .MinValue:=1;
  end;
end;

end.
