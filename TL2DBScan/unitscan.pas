{$I-}
unit unitscan;

interface

uses
  sqlite3
  ,TL2Mod
  ,RGGlobal
  ;

{not necessary to call them manually}
// amul is scale (which value must be multiplied to get integer with required precision)
function ScanGraph   (ams:pointer; const aname:string; amul:integer):integer;
procedure LoadDefaultGraphs(ams:pointer);

{scanning type}
function ScanPath(adb:PSQLite3; const apath:string; aLogLvl:integer=1):integer;

procedure ScanAll(ams:pointer);

function ScanClasses  (ams:pointer):integer;
function ScanInventory(ams:pointer):integer;
function ScanItems    (ams:pointer):integer;
function ScanMobs     (ams:pointer):integer;
function ScanMovies   (ams:pointer):integer;
function ScanPets     (ams:pointer):integer;
function ScanProps    (ams:pointer):integer;
function ScanQuests   (ams:pointer):integer;
function ScanRecipes  (ams:pointer):integer;
function ScanSkills   (ams:pointer):integer;
function ScanStats    (ams:pointer):integer;
function ScanWardrobe (ams:pointer):integer;

{main single mod scanning}
// prepare SINGLE mod file/unpacked directory
function Prepare(
         adb:PSQLite3;
         const apath:string;
         out ams:pointer;
         aLogLvl:integer=1;
         aupdateall:boolean=false):boolean;

procedure Finish(ams:pointer);

{Load DB to memory/save back to disk}
function RGOpenBase (out adb:PSQLite3; const fname:string=TL2DataBase):boolean;
function RGSaveBase (    adb:PSQLite3; const fname:string=TL2DataBase):integer;
function RGCloseBase(var adb:PSQLite3; const fname:string=''):boolean;


implementation

uses
  awkSQLite3
  ,sysutils
  ,Logging
  ,RGScan
  ,rgPAK
  ,rgio.DAT
  ,rgio.Text
  ,RGDict
  ,RGNode
  ;

{$R ..\TL2Lib\dicttag.rc}

type
  PModScanner = ^TModScanner;
  TModScanner = object
    FDoUpdate:boolean;  // update data or not if it was found | CheckForMod only
    FModId   :string;   // current mod id                     | Add*ToBase, AddTheMod
    FModMask :string;   // mod id mask (optimization)         | ' '+FModId+' '
    scan     :pointer;  // PScanObj from RGScan
    db       :PSQLite3;
    FRootLen :integer;  // Root dir name length
    FLogLevel:integer;
  end;
type
  PScanDir = ^TScanDir;
  TScanDir = record
    db  :PSQLite3;
    path:string;
    log :integer;
  end;
{
const
  h_NAME        = 6688229;
  h_DISPLAYNAME = 2200927350;
  h_DESCRIPTION = 330554530;
  h_BASEFILE    = 3799132101;
  h_UNIT_GUID   = 3990071814;
  h_UNITTYPE    = 392914174;
  h_ICON        = 6653358;
}

function FixedText(const astr:string):string;
begin
  result:=#39+StringReplace(astr,#39,#39#39,[rfReplaceAll])+#39;
end;

procedure LoadFile(ams:pointer; const aname:string; out anode:pointer);
var
  lbuf:pointer;
begin
  if GetRGScan(PModScanner(ams)^.scan,aname,lbuf)>0 then
  begin
    anode:=ParseTextMem(lbuf);
    if anode=nil then
      anode:=ParseDatMem(lbuf);
    
    FreeMem(lbuf);
  end
  else
    anode:=nil;
end;

{$i scan_mod.inc}

{$i scan_adds.inc}
{$i scan_classes.inc}
{$i scan_inventory.inc}
{$i scan_items.inc}
{$i scan_mobs.inc}
{$i scan_movies.inc}
{$i scan_pet.inc}
{$i scan_props.inc}
{$i scan_recipes.inc}
{$i scan_quest.inc}
{$i scan_skills.inc}
{$i scan_stat.inc}
{$i scan_wardrobe.inc}

{%REGION Scan single mod}

procedure ScanAll(ams:pointer);
begin
  LoadDefaultGraphs(ams);
//  ScanAdds    (ams);
  ScanClasses  (ams);
  ScanInventory(ams);
  ScanItems    (ams);
  ScanMobs     (ams);
  ScanMovies   (ams);
  ScanPets     (ams);
  ScanProps    (ams);
  ScanQuests   (ams);
  ScanRecipes  (ams);
  ScanSkills   (ams);
  ScanStats    (ams);
  ScanWardrobe (ams);
end;


function Prepare(
    adb:PSQLite3;
    const apath:string;
    out ams:pointer;
    aLogLvl:integer=1;
    aupdateall:boolean=false):boolean;
var
  lmod:TTL2ModInfo;
  lscan:pointer;
  lmodid:Int64;
  lver:integer;
begin
  result:=false;
  ams:=nil;
  if adb=nil then exit;

  lver:=verUnk;

  if (apath[Length(apath)] in ['/','\']) or DirectoryExists(apath) then
  begin
    result:=LoadModConfiguration(PChar(apath+'\MOD.DAT'),lmod);
    if result then lver:=verTL2Mod;
  end
  else if FileExists(apath) then
  begin
    lver:=RGPAKGetVersion(apath);
    if      lver=verTL2Mod then result:=ReadModInfo(PChar(apath),lmod)
    else if lver=verTL2    then result:=true;
  end;

  if result then
  begin
    if lver=verTL2Mod then
    begin
      AddTheMod(adb,lmod);
      lmodid:=lmod.modid;
      ClearModInfo(lmod);
    end
    else
      lmodid:=0;

    GetMem  (ams ,SizeOf(TModScanner));
    FillChar(ams^,SizeOf(TModScanner),0);

    PModScanner(ams)^.FRootLen:=PrepareRGScan(lscan, apath, ['.DAT'], ams);
    if lscan<>nil then
    begin

      with PModScanner(ams)^ do
      begin
        db       :=adb;
        scan     :=lscan;
        FDoUpdate:=aupdateall;
        Str(lmodid,FModId);
        FModMask :=' '+FModId+' ';
        FLogLevel:=aLogLvl;
      end;

    end
    else
    begin
//      EndRGScan(lscan);
      FreeMem(ams);
      ams:=nil;
    end;
  end;
end;

procedure Finish(ams:pointer);
begin
  if ams<>nil then
  begin
    with PModScanner(ams)^ do
    begin
      EndRGScan(scan);
{
      FModId  :='';
      FModMask:='';
}
    end;
    Finalize(PModScanner(ams)^);

    FreeMem(ams);
    ams:=nil;
  end;
end;

{%ENDREGION Scan single mod}

{%REGION Scan dirs}

procedure ProcessSingleMod(adb:PSQLite3; const aname:string; aLogLvl:integer);
var
  lms:pointer;
begin
  if not Prepare(adb,aname,lms,aLogLvl) then
  begin
    RGLog.Add('Can''t prepare "'+aname+'" scanning');
    exit;
  end;

  ScanAll(lms);

  Finish(lms);
end;

function DoCheck(const adir,aname:string; aparam:pointer):integer;
var
  lext:string;
begin
  result:=1;
  lext:=UpCase(ExtractFileExt(aname));
  if (lext='.MOD') or
     (lext='.PAK') then
  begin
    with PScanDir(aparam)^ do
      ProcessSingleMod(db,path+'\'+adir+'\'+aname,log);
  end
  else if (UpCase(aname)='MOD.DAT') then
  begin
    with PScanDir(aparam)^ do
      if (adir='\') or (adir='/') then
        ProcessSingleMod(db,path,log)
      else
        ProcessSingleMod(db,path+'\'+adir,log);
  end
  else
    exit(0);
end;

function ScanPath(adb:PSQLite3; const apath:string; aLogLvl:integer=1):integer;
var
  lsd:TScanDir;
begin
  result:=0;
  lsd.db  :=adb;
  lsd.path:=apath;
  lsd.log :=aLogLvl;
  result:=MakeRGScan(apath,'',['.PAK','.MOD','.DAT'],nil,@lsd,@DoCheck);
end;

{%ENDREGION Scan dirs}

{%REGION Base}

function CreateTables(adb:PSQLite3):boolean;
begin
  result:=CreateModTable      (adb);

  result:=CreateAddsTable     (adb);
  result:=CreateClassesTable  (adb);
  result:=CreateGraphTable    (adb);
  result:=CreateInventoryTable(adb);
  result:=CreateItemsTable    (adb);
  result:=CreateMobsTable     (adb);
  result:=CreateMoviesTable   (adb);
  result:=CreatePetsTable     (adb);
  result:=CreatePropsTable    (adb);
  result:=CreateQuestsTable   (adb);
  result:=CreateRecipesTable  (adb);
  result:=CreateSkillsTable   (adb);
  result:=CreateStatsTable    (adb);
  result:=CreateWardrobeTable (adb);
end;

function RGOpenBase(out adb:PSQLite3; const fname:string=TL2DataBase):boolean;
begin
  result:=sqlite3_open(':memory:',@adb)=SQLITE_OK;
  if result then
  begin
    if (fname='') or (CopyFromFile(adb,PChar(fname))<>SQLITE_OK) then
      result:=CreateTables(adb);
  end;
end;

function RGSaveBase(adb:PSQLite3; const fname:string=TL2DataBase):integer;
begin
  result:=CopyToFile(adb,PChar(fname));
end;

function RGCloseBase(var adb:PSQLite3; const fname:string=''):boolean;
begin
  if fname<>'' then
    result:=RGSaveBase(adb,fname)=SQLITE_OK
  else
    result:=true;

  result:=result and (sqlite3_close(adb)=SQLITE_OK);
  adb:=nil;
end;

{%ENDREGION Base}

initialization
  RGTags.Import('RGDICT','TEXT');

end.
