unit formSaveGame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, StdCtrls, ExtCtrls,
  Menus, ActnList, ComCtrls, tl2save, formMovies, formRecipes, formQuests,
  formButtons, formKeyBinding, formStatistic, formSettings,
  formChar, formStat, formMap, formUnits, formSkills, formItems, formEffects;

type

  { TfmSaveFile }

  TfmSaveFile = class(TForm)
    actFileExit: TAction;
    actFileOpen: TAction;
    actFileSave: TAction;
    actExport  : TAction;
    actImport  : TAction;
    actFileReload: TAction;
    ActionList: TActionList;
    ImageList: TImageList;
    MainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mnuFileOpen: TMenuItem;
    mnuFileSave: TMenuItem;
    mnuFileSep1: TMenuItem;
    mnuFileExit: TMenuItem;
    MainPanel: TPanel;
    LeftPanel: TPanel;
    Splitter: TSplitter;
    tvSaveGame: TTreeView;

    procedure actFileExitExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure actFileReloadExecute(Sender: TObject);
    procedure actFileSaveExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure tvSaveGameSelectionChanged(Sender: TObject);
  private
    FFileName:string;

    FSettings  :TfmSettings;
    FMovies    :TfmMovies;
    FRecipes   :TfmRecipes;
    FKeyBinding:TfmKeyBinding;
    FQuests    :TfmQuests;
    FStatistic :TfmStatistic;
    FMaps      :TfmMap;
    FChar      :TfmChar;
    FPet       :TfmChar;
    FStats     :TfmStat;
    FUnits     :TfmUnits;
    FSkills    :TfmSkills;
    FItems     :TfmItems;
    
    SGame:TTL2SaveFile;

    procedure ChangeTree;
    procedure CreateTree;
    function GetTVIndex: integer;
  public

  end;

var
  fmSaveFile: TfmSaveFile;

implementation

{$R *.lfm}

uses
  tl2db,
  unitGlobal,
  tl2base;

resourcestring
  rsSaveGameOpen = 'Open Savegame';
  rsSaveGameSave = 'Save Savegame';

  rsSettings   = 'Settings';
  rsSavegame   = 'Savegame';
  rsMovies     = 'Movies';
  rsModList    = 'Mod list';
  rsKeyMapping = 'KeyMapping';
  rsCharacter  = 'Character';
  rsPlayerStat = 'Player statistic';
  rsPets       = 'Pets and allies';
  rsMaps       = 'Maps';
  rsQuests     = 'Quests';
  rsRecipes    = 'Recipes';
  rsStatistic  = 'Global statistic';

  rsSkills = 'Skills';
  rsItems  = 'Items';
  rsUnits  = 'Units';
  rsProps  = 'Props';
  rsQItem  = 'Quest items';

const
  DefaultExt = '.dmp';

const
  idxSettings   =  0;
  idxSavegame   =  1;

  idxMovies     =  0;
  idxModList    =  1;
  idxKeyMapping =  2;
  idxCharacter  =  3;
  idxPlayerStat =  4;
  idxPets       =  5;
  idxMaps       =  6;
  idxQuests     =  7;
  idxRecipes    =  8;
  idxStatistic  =  9;

  { TfmSaveFile }

//===== Tree =====

procedure TfmSaveFile.CreateTree;
var
  lroot,lNode:TTreeNode;
begin
  with tvSaveGame do
  begin
    Items.Clear;
    Items.AddFirst(nil,rsSettings);
    lroot:=Items.AddChild(nil,rsSavegame);
    lroot.Visible:=false;
    Items.AddChild(lroot,rsMovies);
    Items.AddChild(lroot,rsModList);
    Items.AddChild(lroot,rsKeyMapping);
    lNode:=Items.AddChild(lroot,rsCharacter);
    Items.AddChild(lNode,rsSkills);
    Items.AddChild(lNode,rsItems);
    Items.AddChild(lroot,rsPlayerStat);
    Items.AddChild(lroot,rsPets);
    Items.AddChild(lroot,rsMaps);
    Items.AddChild(lroot,rsQuests);
    Items.AddChild(lroot,rsRecipes);
    Items.AddChild(lroot,rsStatistic);
    lroot.Expanded:=true;
  end;
end;

procedure TfmSaveFile.ChangeTree;
var
  lNode,lSubNode:TTreeNode;
  ls:string;
  i,lcnt: integer;
begin
  lNode:=tvSaveGame.Items[idxSavegame];
  lNode.Visible:=true;
  lNode.Items[idxCharacter].Data:=pointer(SGame.CharInfo);
  lNode.Items[idxPets     ].Data:=pointer(SGame.PetInfo[0]);
  lNode.Items[idxMaps     ].Data:=pointer(SGame.Maps[0]);
  lNode.Items[idxQuests   ].Data:=pointer(SGame.Quests);
  lNode.Items[idxStatistic].Data:=pointer(SGame.Stats);

  lcnt:=SGame.PetCount;
  lNode:=tvSaveGame.Items[idxSavegame].Items[idxPets];
  lNode.DeleteChildren;
  for i:=0 to lcnt-1 do
  begin
    lSubNode:=tvSaveGame.Items.AddChild(lNode,SGame.PetInfo[i].Name);
    lSubNode.Data:=pointer(SGame.PetInfo[i]);
    tvSaveGame.Items.AddChild(lSubNode,rsItems);
  end;

  lcnt:=SGame.MapCount;
  lNode:=tvSaveGame.Items[idxSavegame].Items[idxMaps];
  lNode.DeleteChildren;
  for i:=0 to lcnt-1 do
  begin
    ls:=SGame.Maps[i].Name;
    if SGame.Maps[i].Number>0 then
      ls:=ls+' ['+IntToStr(SGame.Maps[i].Number)+']';
    lSubNode:=tvSaveGame.Items.AddChild(lNode,ls);
    lSubNode.Data:=pointer(SGame.Maps[i]);
    tvSaveGame.Items.AddChild(lSubNode,rsUnits);
    tvSaveGame.Items.AddChild(lSubNode,rsProps);
    if Length(SGame.Maps[i].QuestItems)>0 then
      tvSaveGame.Items.AddChild(lSubNode,rsQItem);
  end;

  tvSaveGame.Items[idxSavegame].Visible:=true;
  tvSaveGame.Select(tvSaveGame.Items[idxSavegame]);
end;

//===== Form =====

procedure TfmSaveFile.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ClearGameGlobals;
  SGame.Free;
end;

procedure TfmSaveFile.FormCreate(Sender: TObject);
begin
  fmButtons  :=TfmButtons   .Create(Self); fmButtons  .Parent:=MainPanel;
  fmEffects  :=TfmEffects   .Create(Self);

  FSettings  :=TfmSettings  .Create(Self); FSettings  .Parent:=MainPanel;
  LoadBases(FSettings.edDBFile.Text);

  FMovies    :=TfmMovies    .Create(Self); FMovies    .Parent:=MainPanel;
  FRecipes   :=TfmRecipes   .Create(Self); FRecipes   .Parent:=MainPanel;
  FKeyBinding:=TfmKeyBinding.Create(Self); FKeyBinding.Parent:=MainPanel;
  FQuests    :=TfmQuests    .Create(Self); FQuests    .Parent:=MainPanel;
  FStatistic :=TfmStatistic .Create(Self); FStatistic .Parent:=MainPanel;
  FStats     :=TfmStat      .Create(Self); FStats     .Parent:=MainPanel;
  FMaps      :=TfmMap       .Create(Self); FMaps      .Parent:=MainPanel;
  FUnits     :=TfmUnits     .Create(Self); FUnits     .Parent:=MainPanel;
  FSkills    :=TfmSkills    .Create(Self); FSkills    .Parent:=MainPanel;
  FItems     :=TfmItems     .Create(Self); FItems     .Parent:=MainPanel;

  FChar:=TfmChar.Create(Self,ciPlayer); FChar.Parent:=MainPanel;
  FPet :=TfmChar.Create(Self,ciPet   ); FPet .Parent:=MainPanel;

  fmButtons.Visible:=true;

  CreateTree;
end;

//===== Actions =====

procedure TfmSaveFile.actFileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  //!! check if savegame already opened and changed

  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.Title  :=rsSaveGameOpen;
    OpenDialog.Options:=[ofFileMustExist];

    if OpenDialog.Execute then
    begin
      FFileName:=OpenDialog.FileName;

      actFileReloadExecute(Sender);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TfmSaveFile.actFileReloadExecute(Sender: TObject);
begin
  ClearGameGlobals;
  SGame.Free;

  SGame:=TTL2SaveFile.Create;
  SGame.LoadFromFile(FFileName);
  SGame.Parse();
  ChangeTree;

  LoadGameGlobals;

  FSkills.Configured:=false;
end;

procedure TfmSaveFile.actFileSaveExecute(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
  SaveDialog:=TSaveDialog.Create(nil);
  try
    SaveDialog.Title     :=rsSaveGameSave;
    SaveDialog.Options   :=SaveDialog.Options+[ofOverwritePrompt];
    SaveDialog.DefaultExt:='.SVB';
    if SaveDialog.Execute then
    begin
      SGame.Prepare;
      SGame.SaveToFile(SaveDialog.FileName);
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TfmSaveFile.actFileExitExecute(Sender: TObject);
begin
  Close;
end;

function TfmSaveFile.GetTVIndex:integer;
begin
  result:=-1;

  if tvSaveGame.Selected=nil then
    exit;

  case tvSaveGame.Selected.level of
    0: if tvSaveGame.Selected.Index<>idxSettings then
      result:=0;
    1: result:=tvSaveGame.Selected.Index;
    2: result:=tvSaveGame.Selected.Parent.Index;
    3: result:=tvSaveGame.Selected.Parent.Parent.Index;
  else
  end;
end;

procedure TfmSaveFile.tvSaveGameSelectionChanged(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=GetTVIndex;

  fmButtons.btnExport.Enabled:=(tvSaveGame.Selected<>nil) and (tvSaveGame.Selected.Data<>nil);
  fmButtons.btnImport.Enabled:=false;
  fmButtons.Offset:=-1;
  fmButtons.Ext   :=DefaultExt;
  if (tvSaveGame.Selected<>nil) then
  begin
    fmButtons.Name  :=tvSaveGame.Selected.Text;
    fmButtons.SClass:=TL2BaseClass(tvSaveGame.Selected.Data);
  end
  else
  begin
    fmButtons.Name  :='';
    fmButtons.SClass:=nil;
  end;

  FSettings  .Visible:=false;
  FMovies    .Visible:=false;
  FMaps      .Visible:=false;
  FRecipes   .Visible:=false;
  FKeyBinding.Visible:=false;
  FQuests    .Visible:=false;
  FStatistic .Visible:=false;
  FChar      .Visible:=false;
  FPet       .Visible:=false;
  FStats     .Visible:=false;
  FUnits     .Visible:=false;
  FSkills    .Visible:=false;
  FItems     .Visible:=false;

  case lidx of
    -1: begin
      FSettings.Visible:=true;
    end;

    idxMovies: begin
      FMovies.FillInfo(SGame);
      FMovies.Visible:=true;
    end;

    idxModList: begin
    end;

    idxKeyMapping: begin
      FKeyBinding.FillInfo(SGame);
      FKeyBinding.Visible:=true;
    end;

    idxPlayerStat: begin
      FStatistic.FillInfo(SGame);
      FStatistic.Visible:=true;
    end;

    idxCharacter: begin
      case tvSaveGame.Selected.level of
        2: lidx:=tvSaveGame.Selected.Index;
        3: lidx:=tvSaveGame.Selected.Parent.Index;
      else
        lidx:=0;
      end;
      case tvSaveGame.Selected.level of
        1: begin
          FChar.FillInfo(SGame.CharInfo, SGame);
          FChar.Visible:=true;
        end;
        2: begin
          case lidx of
            0: begin
              FSkills.FillInfo(SGame.CharInfo);
              FSkills.Visible:=true;
            end;
            1: begin
              FItems.FillInfo(SGame.CharInfo.Items);
              FItems.Visible:=true;
            end;
          end;
        end;
      end;
    end;

    idxPets: begin
      fmButtons.btnImport.Enabled:=true;
      case tvSaveGame.Selected.level of
        2: lidx:=tvSaveGame.Selected.Index;
        3: lidx:=tvSaveGame.Selected.Parent.Index;
      else
        lidx:=0;
      end;
      case tvSaveGame.Selected.level of
        1,2: begin
          FPet.FillInfo(SGame.PetInfo[lidx]);
          actImport.Enabled:=FPet.IsMain;
          FPet.Visible:=true;
        end;
        3: begin
          FItems.FillInfo(SGame.PetInfo[lidx].Items);
          FItems.Visible:=true;
        end;
      end;
    end;

    idxMaps: begin
      case tvSaveGame.Selected.level of
        2: lidx:=tvSaveGame.Selected.Index;
        3: lidx:=tvSaveGame.Selected.Parent.Index;
      else
        lidx:=0;
      end;
      case tvSaveGame.Selected.level of
        1,2: begin
          FMaps.FillInfo(SGame,lidx);
          FMaps.Visible:=true;
        end;
        3: begin
          case tvSaveGame.Selected.Index of
            0: begin
              FUnits.FillInfo(SGame,lidx);
              FUnits.Visible:=true;
            end;
            1: begin
              FItems.FillInfo(SGame.Maps[lidx].PropList);
              FItems.Visible:=true;
            end;
            2: begin
              FItems.FillInfo(SGame.Maps[lidx].QuestItems);
              FItems.Visible:=true;
            end;
          end;
        end;
      end;
    end;

    idxQuests: begin
      fmButtons.Offset:=SGame.Quests.DataOffset;
      FQuests.FillInfo(SGame);
      FQuests.Visible:=true;
    end;

    idxRecipes: begin
      FRecipes.FillInfo(SGame);
      FRecipes.Visible:=true;
    end;

    idxStatistic: begin
      FStats.FillInfo(SGame);
      FStats.Visible:=true;
    end;
  end;
end;

end.
