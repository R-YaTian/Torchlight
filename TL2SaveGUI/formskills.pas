unit formSkills;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  Buttons, Types,
  tl2char, tl2types, tl2db;

type

  { TfmSkills }

  TfmSkills = class(TForm)
    bbUpdate: TBitBtn;
    btnReset: TButton;

    cbCheckLevel : TCheckBox;
    cbCheckPoints: TCheckBox;
    cbSaveFull   : TCheckBox;

    lblCurrent: TLabel;

    lblName : TLabel;
    memDesc: TMemo;

    sgSkills: TStringGrid;

    procedure bbUpdateClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure cbSaveFullClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure sgSkillsDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure sgSkillsEditButtonClick(Sender: TObject);
    procedure sgSkillsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  private
    FConfigured:boolean;

    FChar  :TTL2Character;  // reference to player (char level, free points, skills)
    FClass :TL2ID;          // class id (to change skill list)
    FSkills:tSkillArray;    // skills: id, title, maxlevel, tier, icon
    FIcons :array of array [boolean] of TPicture; // skill icons learned/not
    FTiers :tTierArray;     // tier array (!!must be global for mod build)
    FPoints:integer;        // free points for current (unsaved) skill build
    FLevel  :integer;
    FFame   :integer;
    FSkLevel:integer;
    FSkFame :integer;

    procedure ClearData;
    procedure CreateIconList();
    function  CheckTier(aval,aidx:integer):boolean;
  public
    procedure FillInfo(aChar:TTL2Character);

    property Configured:boolean read FConfigured write FConfigured;
  end;


implementation

{$R *.lfm}

uses
  INIFiles,
  formsettings;

resourcestring
  rsFreePoints = 'Free skill points';

const
  sSkills      = 'Skills';
  sCheckLevel  = 'checklevel';
  sCheckPoints = 'checkpoints';
  sSaveFull    = 'savefulllist';

const
  colIcon    = 0;
  colName    = 1;
  colPassive = 2;
  colMinus   = 3;
  colLevel   = 4;
  colPlus    = 5;

procedure TfmSkills.FormCreate(Sender: TObject);
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
  cbCheckLevel .Checked:=config.ReadBool(sSkills,sCheckLevel ,true);
  cbCheckPoints.Checked:=config.ReadBool(sSkills,sCheckPoints,true);
  cbSaveFull   .Checked:=config.ReadBool(sSkills,sSaveFull   ,true);

  config.Free;

  LoadTiers(FTiers); //!! by mod so maybe make global
end;

procedure TfmSkills.FormDestroy(Sender: TObject);
var
  config:TIniFile;
  i:integer;
begin
  ClearData;

  for i:=0 to High(FTiers) do
    SetLength(FTiers[i].levels,0);
  SetLength(FTiers,0);

  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
  config.WriteBool(sSkills,sCheckLevel ,cbCheckLevel .Checked);
  config.WriteBool(sSkills,sCheckPoints,cbCheckPoints.Checked);
  config.WriteBool(sSkills,sSaveFull   ,cbSaveFull   .Checked);

  config.UpdateFile;
  config.Free;
end;

procedure TfmSkills.sgSkillsDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  lRect:TRect;
  bmp:TBitmap;
  idx:integer;
  isgray:boolean;
begin
  if (aCol=colIcon) and (aRow>0) then
  begin
    idx:=IntPtr(sgSkills.Objects[0,aRow]);
    isgray:=sgSkills.Cells[colLevel,aRow]='0';
    bmp:=FIcons[idx,isgray].Bitmap;
    if (bmp=nil) and isgray then bmp:=FIcons[idx,false].Bitmap;
    if bmp<>nil then
    begin
      lRect:=aRect;
      InflateRect(lRect,-1,-1);
      sgSKills.Canvas.StretchDraw(lRect,bmp);
    end;
  end;
end;

function TfmSkills.CheckTier(aval,aidx:integer):boolean;
var
  i,llevel:integer;
begin
  result:=true;
  llevel:=FChar.Level;
  for i:=0 to High(FTiers) do
  begin
    if FSkills[aidx].tier=FTiers[i].name then
    begin
      if (aval<Length(FTiers[i].levels)) and
         (FTiers[i].levels[aval]>llevel) then
        result:=false;
      break;
    end;
  end;
end;

procedure TfmSkills.sgSkillsEditButtonClick(Sender: TObject);
var
  lval,idx:integer;
  lchanged:boolean;
begin
  lchanged:=false;
  lval:=StrToInt(sgSkills.Cells[colLevel,sgSkills.Row]);

  if sgSkills.Col=colMinus then
  begin
    if lval>0 then
    begin
      dec(lval);
      inc(FPoints);
      lchanged:=true;
    end;
  end

  else if sgSkills.Col=colPlus then
  begin
    if ((FPoints>0) or not (cbCheckPoints.Checked)) then
    begin
      idx:=IntPtr(sgSkills.Objects[0,sgSkills.Row]);
      if (lval<FSkills[idx].level) and
         ((not cbCheckLevel.Checked) or CheckTier(lval,idx)) then
      begin
        inc(lval);
        dec(FPoints);
        lchanged:=true;
      end;
    end;
  end;

  if lchanged then
  begin
    sgSkills.Cells[colLevel,sgSkills.Row]:=IntToStr(lval);
    lblCurrent.Caption:=rsFreePoints+': '+IntToStr(FPoints);
    bbUpdate.Enabled:=true;
  end;
end;

procedure TfmSkills.sgSkillsSelectCell(Sender: TObject;
          aCol, aRow: Integer; var CanSelect: Boolean);
var
  licon,ltier:string;
  idx:integer;
begin
  if aRow>0 then
  begin
    idx:=IntPtr(sgSkills.Objects[0,aRow]);

    lblName.Caption:=FSkills[idx].title;
    memDesc.Text   :=GetSkillInfo(FSkills[idx].id,ltier,licon);
  end;
end;

procedure TfmSkills.btnResetClick(Sender: TObject);
var
  i:integer;
begin
  for i:=1 to sgSkills.RowCount-1 do
  begin
    inc(FPoints,StrToInt(sgSkills.Cells[colLevel,i]));
    sgSkills.Cells[colLevel,i]:='0';
  end;
  lblCurrent.Caption:=rsFreePoints+': '+IntToStr(FPoints);
  bbUpdate.Enabled:=true;
end;

procedure TfmSkills.cbSaveFullClick(Sender: TObject);
begin
  bbUpdate.Enabled:=true;
end;

procedure TfmSkills.ClearData;
var
  i:integer;
begin
  SetLength(FSkills,0);

  for i:=0 to High(FIcons) do
  begin
    FIcons[i,false].Free;
    FIcons[i,true ].Free;
  end;
  SetLength(FIcons,0);
end;

procedure TfmSkills.CreateIconList();
var
  i:integer;
begin
  SetLength(FIcons,Length(FSkills));
  for i:=0 to High(FIcons) do
  begin
    FIcons[i,false]:=TPicture.Create;
    FIcons[i,true ]:=TPicture.Create;
    try
      FIcons[i,false].LoadFromFile('icons\skills\'+FSkills[i].icon+'.png');
      FIcons[i,true ].LoadFromFile('icons\skills\'+FSkills[i].icon+'_gray.png');
    except
    end;
  end;
end;

procedure TfmSkills.FillInfo(aChar:TTL2Character);
var
  ls:string;
  i,j,idx,dl,df:integer;
begin
  sgSkills.BeginUpdate;

  //--- new class

  if FClass<>aChar.ClassId then
  begin
    ClearData;

    FClass:=aChar.ClassId;

    sgSkills.Clear;
    sgSkills.RowCount:=1;

    CreateSkillList(FClass,FSkills);
    CreateIconList();
    if FSkills<>nil then
    begin
      sgSkills.RowCount:=1+Length(FSkills);
      j:=1;
      for i:=0 to High(FSkills) do
      begin
        // skip unlearnabled
        if (FSkills[i].tier<>'') and
           (FSkills[i].tier[1]<>',') then
        begin
          sgSkills.Objects[0,j]:=TObject(IntPtr(i));

          sgSkills.Cells[colName   ,j]:=FSkills[i].title;
          sgSkills.Cells[colPassive,j]:=FSkills[i].passive;
          sgSkills.Cells[colMinus  ,j]:='-';
          sgSkills.Cells[colLevel  ,j]:='0';
          sgSkills.Cells[colPlus   ,j]:='+';
          inc(j);
        end;
      end;
      sgSkills.RowCount:=j;
    end;
  end;

  //--- new build

  if not FConfigured then
  begin
    FChar:=aChar;
    FPoints:=aChar.FreeSkillPoints;
{
  total:=
    FSettings.seSkillPerLvl .Value*(FChar.Level-1);
    FSettings.seSkillPerFame.Value*(FChar.Fame -1);
  current - calcs from skills OR stat
}
    for i:=1 to sgSkills.RowCount-1 do
    begin
      idx:=IntPtr(sgSkills.Objects[0,i]);

      ls:='0';
      for j:=0 to High(aChar.Skills) do
      begin
        if aChar.Skills[j].id=FSkills[idx].id then
        begin
          Str(aChar.Skills[j].value,ls);
          break;
        end;
      end;
      sgSkills.Cells[colLevel,i]:=ls;
    end;

    GetClassGraphSkill(aChar.ClassId,FSkLevel,FSkFame);
    FConfigured:=true;
    bbUpdate.Enabled:=false;
  end

  //--- Every activation
  else
  begin
    dl:=(aChar.Level    -FLevel)*FSkLevel;
    df:=(aChar.FameLevel-FFame )*FSkFame;
    inc(FPoints,dl+df);
  end;
  FFame :=aChar.FameLevel;
  FLevel:=aChar.Level;

  lblCurrent.Caption:=rsFreePoints+': '+IntToStr(FPoints);

  sgSkills.EndUpdate;
end;

procedure TfmSkills.bbUpdateClick(Sender: TObject);
var
  lskills:TL2IdValList;
  lcnt,i:integer;
begin
  lskills:=FChar.Skills;
  SetLength(lskills,sgSkills.RowCount-1);
  lcnt:=0;
  for i:=1 to sgSkills.RowCount-1 do
  begin
    lskills[lcnt].value:=StrToInt(sgSkills.Cells[colLevel,i]);
    if cbSaveFull.Checked or (lskills[lcnt].value>0) then
    begin
      lskills[lcnt].id:=FSkills[IntPtr(sgSkills.Objects[0,i])].id;
      inc(lcnt);
    end;
  end;
  SetLength(lskills,lcnt);
  FChar.Skills:=lskills;
  if FPoints>=0 then
    FChar.FreeSkillPoints:=FPoints
  else
    FChar.FreeSkillPoints:=0;
  //!! what about statistic? need to check!
  //!! what about STAT (history?) need to clear!
  FChar.Changed:=true;

  bbUpdate.Enabled:=false;
end;

end.
