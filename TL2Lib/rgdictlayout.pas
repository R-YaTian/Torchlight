﻿unit RGDictLayout;

interface

type
  TRGObject = object
  private
    FLastObject:pointer;
    FLastScene :pointer;
    FDict      :pointer;

    FLastSceneName:PWideChar;
    FLastObjId:dword;
    FVersion:integer;

    procedure SetVersion(aver:integer);
  public
    procedure Init;
    procedure Clear;

    function SelectScene(aname:PWideChar):pointer;
    function GetObjectById  (aid:dword):pointer;
    function GetObjectByName(aname:PWideChar):pointer;

    function GetObjectName():PWideChar;
    function GetObjectName(aid:dword):PWideChar;

    function GetObjectId(aname:PWideChar):dword;

    function GetPropsCount:integer;

    function GetProperty(aid:dword):pointer;
    function GetPropInfoByIdx (idx:integer; var aid:dword; var aname:PWideChar):integer;
    function GetPropInfoById  (aid:dword; var aname:PWideChar):integer;
    function GetPropInfoByName(aname:PWideChar; var aid:dword):integer;
    function GetPropInfoByName(aname:PWideChar; atype:integer; var aid:dword):integer;

    property Version:integer read FVersion write SetVersion;
  end;


function LoadLayoutDict(abuf:PWideChar; aver:integer; aUseThis:boolean=false):boolean;
function LoadLayoutDict(const resname:string; restype:PChar; aver:integer):boolean;
function LoadLayoutDict(const fname:AnsiString; aver:integer):boolean;


implementation

uses
  rgglobal;

const
  SIGN_UNICODE = $FEFF;
  SIGN_UTF8    = $BFBBEF;

type
  PPropInfo = ^TPropInfo;
  TPropInfo = record
    name   :PWideChar;
    id     :dword;
    ptype  :integer;
  end;
type
  PObjInfo = ^TObjInfo;
  TObjInfo = record
    name   :PWideChar;
    start  :integer;
    count  :integer;
    id     :dword;
  end;
type
  PSceneInfo = ^TSceneInfo;
  TSceneInfo = record
    name   :PWideChar;
    start  :integer;
    count  :integer;
    id     :dword;
  end;
type
  PLayoutInfo = ^TLayoutInfo;
  TLayoutInfo = record
    scenes :array [0..3] of TSceneInfo;
    objects:array of TObjInfo;
    props  :array of TPropInfo;
    buf    :PWideChar;
  end;

var
  DictObjTL1:TLayoutInfo;
  DictObjTL2:TLayoutInfo;
  DictObjHob:TLayoutInfo;
  DictObjRG :TLayoutInfo;
  DictObjRGO:TLayoutInfo;

//----- Objects -----

procedure TRGObject.Init;
begin
  FVersion   :=verUnk;
  FDict      :=nil;
  FLastObject:=nil;
  FLastObjId :=dword(-1);

  FLastScene :=nil;
  FLastSceneName:=nil;
end;

procedure TRGObject.Clear;
begin
  Init;
end;

procedure TRGObject.SetVersion(aver:integer);
begin
  Init;
  case ABS(aver) of
    verTL1: FDict:=@DictObjTL1;
    verTL2: FDict:=@DictObjTL2;
    verRG : FDict:=@DictObjRG ;
    verRGO: FDict:=@DictObjRGO;
    verHob: FDict:=@DictObjHob;
  else
    exit;
  end;
  FVersion:=aver;
end;

function TRGObject.SelectScene(aname:PWideChar):pointer;
var
  i:integer;
begin
  // Get Default (if one scene only)
  if (aname=nil) or (aname^=#0) or
     (PLayoutInfo(FDict)^.scenes[1].id=dword(-1)) then
  begin
    FLastScene:=@(PLayoutInfo(FDict)^.scenes[0]);
    FLastSceneName:=PSceneInfo(FLastScene)^.name;
    exit(FLastScene);
  end;

  if CompareWide(FLastSceneName,aname)=0 then
    exit(FLastScene);

  FLastObject:=nil;
  FLastObjId :=dword(-1);

  i:=0;
  repeat
    FLastScene:=@(PLayoutInfo(FDict)^.scenes[i]);
    FLastSceneName:=PSceneInfo(FLastScene)^.name;
    if  CompareWide(PSceneInfo(FLastScene)^.name,aname)=0 then
      exit(FLastScene);
    inc(i);
  until (i=Length(PLayoutInfo(FDict)^.scenes)) or
                 (PLayoutInfo(FDict)^.scenes[i].id=dword(-1));

  FLastScene    :=nil;
  FLastSceneName:=nil;
  result        :=nil;
end;

function TRGObject.GetObjectByName(aname:PWideChar):pointer;
var
  i:integer;
begin
  if FLastScene<>nil then
    for i:=0 to PSceneInfo(FLastScene)^.count-1 do
    begin
      FLastObject:=@(PLayoutInfo(FDict)^.Objects[PSceneInfo(FLastScene)^.start+i]);
      if CompareWide(PObjInfo(FLastObject)^.name,aname)=0 then
        exit(FLastObject);
    end;

  FLastObject:=nil;
  FLastObjId :=dword(-1);
  result     :=nil;
end;

function TRGObject.GetObjectById(aid:dword):pointer;
var
  i:integer;
begin
  if FLastObjId=aid then
    exit(FLastObject);

  if FLastScene<>nil then
    for i:=0 to PSceneInfo(FLastScene)^.count-1 do
    begin
      FLastObject:=@(PLayoutInfo(FDict)^.Objects[PSceneInfo(FLastScene)^.start+i]);
      if PObjInfo(FLastObject)^.id=aid then
      begin
        FLastObjId:=aid;
        exit(FLastObject);
      end;
    end;
{
  if RGTags.Tag[aid]<>nil then
    RGLog.Add('!!!!! Got it '+HexStr(aid,8));
}  
  
  FLastObject:=nil;
  FLastObjId :=dword(-1);
  result     :=nil;
  RGLog.Add('Object with id=0x'+HexStr(aid,8)+' was not found');
end;

function TRGObject.GetObjectId(aname:PWideChar):dword;
begin
  if GetObjectByName(aname)<>nil then
    result:=PObjInfo(FLastObject)^.id
  else
    result:=dword(-1);
end;

function TRGObject.GetObjectName():PWideChar;
begin
  if FLastObject<>nil then
    result:=PObjInfo(FLastObject)^.name
  else
    result:=nil;
end;

function TRGObject.GetObjectName(aid:dword):PWideChar;
begin
  if GetObjectById(aid)<>nil then
    result:=GetObjectName()
  else
    result:=nil;
end;

function TRGObject.GetPropsCount:integer;
begin
  if FLastObject<>nil then
    result:=PObjInfo(FLastObject)^.count
  else
    result:=0;
end;

function TRGObject.GetProperty(aid:dword):pointer;
var
  lprop:PPropInfo;
  i:integer;
begin
  if FLastObject<>nil then
    for i:=0 to PObjInfo(FLastObject)^.count-1 do
    begin
      lprop:=@(PLayoutInfo(FDict)^.Props[PObjInfo(FLastObject)^.start+i]);
      if lprop^.id=aid then
        exit(lprop);
    end;

  result:=nil;
end;

function TRGObject.GetPropInfoByIdx(idx:integer; var aid:dword; var aname:PWideChar):integer;
begin
  if FLastObject<>nil then
  begin
    if (idx>=0) and (idx<PObjInfo(FLastObject)^.count) then
    begin
      with PLayoutInfo(FDict)^.Props[PObjInfo(FLastObject)^.start+idx] do
      begin
        aid  :=id;
        aname:=name;
        exit(ptype);
      end;
    end;
  end;

  aid   :=dword(-1);
  aname :=nil;
  result:=rgUnknown;
end;

function TRGObject.GetPropInfoById(aid:dword; var aname:PWideChar):integer;
var
  lprop:PPropInfo;
//  ls:string;
begin
  lprop:=GetProperty(aid);
  if lprop<>nil then
  begin
    aname :=lprop^.name;
    result:=lprop^.ptype;
  end
  else
  begin
    aname :=nil;
    result:=rgUnknown;
  end;
{
  if result<=0 then
  begin
    Str(aid,ls);
    RGLog.Add('Unknown PROPERTY type '+HexStr(aid,8)+' '+ls);
  end;
}
end;

function TRGObject.GetPropInfoByName(aname:PWideChar; var aid:dword):integer;
var
  lprop:PPropInfo;
  i,l:integer;
begin
  if FLastObject<>nil then
  begin
    l:=Length(aname)-1;
    if l>=0 then
      for i:=0 to PObjInfo(FLastObject)^.count-1 do
      begin
        lprop:=@(PLayoutInfo(FDict)^.Props[PObjInfo(FLastObject)^.start+i]);

        if lprop^.ptype in [rgVector2, rgVector3, rgVector4] then
        begin
          if ((lprop^.ptype=rgVector2) and (aname[l] in ['X','x','Y','y'])) or
             ((lprop^.ptype=rgVector3) and (aname[l] in ['X','x','Y','y','Z','z'])) or
             ((lprop^.ptype=rgVector4) and (aname[l] in ['X','x','Y','y','Z','z','W','w'])) then
    
            if (CompareWide(aname,lprop^.name,l)=0) then
            begin
              aid:=lprop^.id;
              result:=lprop^.ptype;//rgFloat;
              exit;
            end;
        end
        else
        begin
          if CompareWide(aname,lprop^.name)=0 then
          begin
            aid:=lprop^.id;
            result:=lprop^.ptype;
            exit;
          end;
        end;

      end;
  end;

  result:=rgUnknown;
end;

function TRGObject.GetPropInfoByName(aname:PWideChar; atype:integer; var aid:dword):integer;
var
  lprop:PPropInfo;
  i,l:integer;
begin
  if FLastObject<>nil then
  begin
    l:=Length(aname)-1;
    if l>=0 then
      for i:=0 to PObjInfo(FLastObject)^.count-1 do
      begin
        lprop:=@(PLayoutInfo(FDict)^.Props[PObjInfo(FLastObject)^.start+i]);

        if (atype=rgFloat) and (lprop^.ptype in [rgVector2, rgVector3, rgVector4]) then
        begin
          if ((lprop^.ptype=rgVector2) and (aname[l] in ['X','x','Y','y'])) or
             ((lprop^.ptype=rgVector3) and (aname[l] in ['X','x','Y','y','Z','z'])) or
             ((lprop^.ptype=rgVector4) and (aname[l] in ['X','x','Y','y','Z','z','W','w'])) then
    
            if (CompareWide(aname,lprop^.name,l)=0) then
            begin
              aid:=lprop^.id;
              result:=lprop^.ptype;//atype;
              exit;
            end;
        end
        else
        begin
          if (lprop^.ptype=atype) and (CompareWide(aname,lprop^.name)=0) then
          begin
            aid:=lprop^.id;
            result:=lprop^.ptype;//atype;
            exit;
          end;
        end;

      end;
  end;

  result:=rgUnknown;
end;


//----- Init/Clear -----

procedure InitLayoutDict(var alay:TLayoutInfo);
begin
  alay.scenes[0].id:=dword(-1);
  alay.objects:=nil;
  alay.props  :=nil;
  alay.buf    :=nil;
end;

procedure ClearLayoutDict(var alay:TLayoutInfo);
begin
  SetLength(alay.objects,0);
  SetLength(alay.props  ,0);
  FreeMem  (alay.buf);
end;


//----- Processed -----

{$I-}
function LoadLayoutDict(abuf:PWideChar; aver:integer; aUseThis:boolean=false):boolean;
var
  ltype:array [0..31] of WideChar;
  pc,lname:PWideChar;
  layptr:PLayoutInfo;
  pscene:PSceneInfo;
  pobj  :PObjInfo;
  pprop :PPropInfo;
  lid:dword;
  lobj,lprop,lscene,i:integer;
begin
  result:=false;

  case ABS(aver) of
    verTL1: layptr:=@DictObjTL1;
    verTL2: layptr:=@DictObjTL2;
    verRG : layptr:=@DictObjRG;
    verRGO: layptr:=@DictObjRGO;
    verHob: layptr:=@DictObjHob;
  else
    RGLog.Add('Wrong layout dictionary version '+HexStr(aver,8));
    exit;
  end;

  if layptr^.buf<>nil then
  begin
    RGLog.Add('Trying to reload layout dictionary for v.'+HexStr(aver,8));
    exit;
  end;

  //-----------------------------

  result:=true;

  if aUseThis then
    layptr^.buf:=abuf
  else
    layptr^.buf:=CopyWide(abuf);

  //-----------------------------

  SetLength(layptr^.objects,1024);
  SetLength(layptr^.props  ,8192);

  lscene:=0;
  lobj  :=0;
  lprop :=0;

  pc:=layptr^.buf;
  if ORD(pc^)=SIGN_UNICODE then inc(pc);
  repeat
    while pc^ in [#9,' ',#13,#10] do inc(pc);

    case pc^ of
      // scene
      '>': begin
        inc(pc);

        lid:=0;
        // ID
        while pc^ in ['0'..'9'] do
        begin
          lid:=lid*10+ORD(pc^)-ORD('0');
          inc(pc);
        end;
        // separator
        inc(pc);
        // name
        lname:=pc;
        while not (pc^ in [#10,#13]) do inc(pc);
        pc^:=#0;
        inc(pc);

        pscene:=@(layptr^.scenes[lscene]);
        inc(lscene);
        pscene^.id     :=lid;
        pscene^.name   :=lname;
        pscene^.start  :=lobj;
        pscene^.count  :=0;
      end;

      // object
      '*': begin
        inc(pc);
        lid:=0;
        // ID
        while pc^ in ['0'..'9'] do
        begin
          lid:=lid*10+ORD(pc^)-ORD('0');
          inc(pc);
        end;
        // separator
        inc(pc);
        // name
        lname:=pc;
        while not (pc^ in [#10,#13,':']) do inc(pc);
        pc^:=#0;
        inc(pc);
        // skip the rest: original ID or property name if presents
        while not (pc^ in [#0,#10,#13]) do inc(pc);

        pobj:=@(layptr^.objects[lobj]);
        inc(pscene^.count);
        inc(lobj);
        pobj^.id     :=lid;
        pobj^.name   :=lname;
        pobj^.start  :=lprop;
        pobj^.count  :=0;
      end;

      // property
      '0'..'9': begin
        lid:=0;
        // ID
        while pc^ in ['0'..'9'] do
        begin
          lid:=lid*10+ORD(pc^)-ORD('0');
          inc(pc);
        end;
        // separator
        inc(pc);
        // type
        i:=0;
        while not (pc^ in [#10,#13,':']) do
        begin
          ltype[i]:=pc^;
          inc(i);
          inc(pc);
        end;
        ltype[i]:=#0;
        inc(pc);
        // name
        lname:=pc;
        while not (pc^ in [#10,#13,':']) do inc(pc);
        pc^:=#0;
        inc(pc);
        // skip the rest: original ID or property name if presents
        while not (pc^ in [#0,#10,#13]) do inc(pc);

        pprop:=@(layptr^.props[lprop]);
        inc(pobj^.count);
        inc(lprop);
        pprop^.id   :=lid;
        pprop^.name :=lname;
        pprop^.ptype:=TextToType(ltype);
      end;

      #0: break;
    else
      while not (pc^ in [#0,#10,#13]) do inc(pc);
    end;

  until false;

  if lscene<Length(layptr^.scenes) then layptr^.scenes[lscene].id:=dword(-1);
end;

function LoadLayoutDict(const resname:string; restype:PChar; aver:integer):boolean;
var
  res:TFPResourceHandle;
  Handle:THANDLE;
  buf:PWideChar;
  lptr:PByte;
  lsize:integer;
begin
  result:=false;

  res:=FindResource(hInstance, PChar(resname), restype);
  if res<>0 then
  begin
    Handle:=LoadResource(hInstance,Res);
    if Handle<>0 then
    begin
      lptr :=LockResource(Handle);
      lsize:=SizeOfResource(hInstance,res);

      GetMem(buf,lsize+SizeOf(WideChar));

      move(lptr^,buf^,lsize);

      UnlockResource(Handle);
      FreeResource(Handle);

      buf[lsize div SizeOf(WideChar)]:=#0;

      result:=LoadLayoutDict(buf,aver,true);

      if not result then FreeMem(buf);
    end;
  end;

end;

function LoadLayoutDict(const fname:AnsiString; aver:integer):boolean;
var
  f:file of byte;
  buf:PWideChar;
  i:integer;
begin
  result:=false;
  
  Assign(f,fname);
  Reset(f);
  if IOResult<>0 then exit;

  i:=FileSize(f);
  GetMem(buf,i+SizeOf(WideChar));
  BlockRead(f,buf^,i);
  Close(f);
  buf[i div SizeOf(WideChar)]:=#0;

  result:=LoadLayoutDict(buf,aver,true);

  if not result then FreeMem(buf);
end;


initialization

  InitLayoutDict(DictObjTL1);
  InitLayoutDict(DictObjTL2);
  InitLayoutDict(DictObjRG );
  InitLayoutDict(DictObjRGO);
  InitLayoutDict(DictObjHob);

finalization

  ClearLayoutDict(DictObjTL1);
  ClearLayoutDict(DictObjTL2);
  ClearLayoutDict(DictObjRG );
  ClearLayoutDict(DictObjRGO);
  ClearLayoutDict(DictObjHob);

end.
