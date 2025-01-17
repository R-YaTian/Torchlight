{
  Quests Done crosses with Statistic Block!!!

QUESTS = lists all quests
QUESTSHOWACTIVE = Shows all the players active quests
QUESTSCOMPLETE = Lists all the quests complete

QUESTACTIVE questName = sets a quest to active
QUESTCOMPLETE questName = sets a quest to complete
QUESTRESET questName = resets a quest to not be active or complete

}
unit TL2Quest;

interface

uses
  Classes,
  rgglobal,
  TL2Base,
  TL2Common,
  rgstream;


type
  TTL2QuestData = record
    id  :TRGID;
    q1  :TRGID;
    d1  :TRGInteger;
    d2  :TRGInteger;
    len :integer;
    data:PByte;

    ofs :integer;
  end;
  TTL2QuestList = array of TTL2QuestData;

type
  TTL2Quest = class(TL2BaseClass)
  private
    procedure InternalClear;

  public
    constructor Create;
    destructor  Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TStream); override;
    procedure SaveToStream  (AStream: TStream); override;

  private
    FQuestsDone  :TL2IdList;
    FQuestsUnDone:TTL2QuestList;

    function GetQuestsDoneNum  :integer;
    function GetQuestsUnDoneNum:integer;
  public
    property QuestsDoneNum  :integer read GetQuestsDoneNum;
    property QuestsUnDoneNum:integer read GetQuestsUnDoneNum;

    property QuestsDone  :TL2IdList     read FQuestsDone;
    property QuestsUnDone:TTL2QuestList read FQuestsUnDone;
  end;


function ReadQuests(AStream:TStream):TTL2Quest;


implementation


constructor TTL2Quest.Create;
begin
  inherited;

  DataType:=dtQuest;
end;

destructor TTL2Quest.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Quest.InternalClear;
var
  i:integer;
begin
  SetLength(FQuestsDone,0);

  for i:=0 to High(FQuestsUnDone) do
    FreeMem(FQuestsUnDone[i].data);
  SetLength(FQuestsUnDone,0);
end;

procedure TTL2Quest.Clear;
begin
  InternalClear;

  inherited;
end;

//----- Property methods -----

function TTL2Quest.GetQuestsDoneNum:integer;
begin
  result:=Length(FQuestsDone);
end;

function TTL2Quest.GetQuestsUnDoneNum:integer;
begin
  result:=Length(FQuestsUnDone);
end;

//----- Save / load -----

procedure TTL2Quest.LoadFromStream(AStream: TStream);
var
  i,lcnt:integer;
  loffset:integer;
begin
  DataSize  :=AStream.ReadDWord;
  DataOffset:=AStream.Position;

  //--- Finished quests

  FQuestsDone:=AStream.ReadIdList;

  //--- Active quests

  lcnt:=AStream.ReadDWord;
  SetLength(FQuestsUnDone,lcnt);
  for i:=0 to lcnt-1 do
  begin
    loffset:=AStream.ReadDWord; // Offset to next quest from quests block start
    with FQuestsUnDone[i] do
    begin
      ofs:=AStream.Position;

      id:=TRGID(AStream.ReadQWord);
      q1:=TRGID(Check(AStream.ReadQWord,'quest_8_'+HexStr(AStream.Position,8),QWord(RGIdEmpty)));
      d1:=AStream.ReadDWord;
      d2:=TRGInteger(Check(AStream.ReadDWord,'quest_4_'+HexStr(AStream.Position,8),$FFFFFFFF));

      len :=(DataOffset+loffset)-AStream.Position;
      data:=AStream.ReadBytes(len);
    end;
  end;

  LoadBlock(AStream);
end;

procedure TTL2Quest.SaveToStream(AStream: TStream);
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

  //--- Finished quests

  AStream.WriteIdList(FQuestsDone);

  //--- Active quests

  AStream.WriteDWord(Length(FQuestsUnDone));
  for i:=0 to High(FQuestsUnDone) do
  begin
    with FQuestsUnDone[i] do
    begin
      AStream.WriteDWord(
          (AStream.Position-DataOffset+SizeOf(DWord))+
          len+SizeOf(QWord)*2+SizeOf(DWord)*2);
      AStream.WriteQWord(QWord(id));
      AStream.WriteQWord(QWord(q1));
      AStream.WriteDWord(DWord(d1));
      AStream.WriteDWord(DWord(d2));
      AStream.Write(data^,len);
    end;
  end;

  //--- Update data size and internal buffer

  LoadBlock(AStream);
  FixSize  (AStream);
end;

(*
    [+0]1b=1 => [+12] have dialogs?
    [+1]1b=? => [6][A][C] "a2-Find_Djinni"
    =1: [6]=1; [8]=1 not always
    [+2]4b=? non-zero usually
    7 - [E=1 usually]

    [+6]4b=?
    [+A]2b=?
    [+C]2b=?
    [+E]4b=? 0 usually. can be 1
    [+12]=cnt [PASSIVE] "dialog count" (words) addr. cnt+words+16 = next quest
    [+16??]
    if [e]=1 and [12]=0 =>$16(22) from [E]
    // GLOBAL_TRILLBOT:
+0  01
+1  01
+2  0F 00 00 00
+6  00 00 00 00
+A  00 00
+C  00 00
+E  01 00 00 00
+12 00 00
+14 00 00 00 00
+18 05 00 00 00 - max parts?
    01
    01
    01 00 00 00
    01 00 00 00  
    ---
    06 00 00 00
    ID=TRILLBOT ARM (QUEST ITEM)
    00 00 00 00
    00
    01          - found?
    01 00 00 00 - amount?
    00 00 00 00
    ---
    07 00 00 00
    ...
    0A 00 00 00
    ID
    00 00 00 00
    00 00 00 00
    00 00 00 00
*)

function ReadQuests(AStream:TStream):TTL2Quest;
begin
  result:=TTL2Quest.Create;
  try
    result.LoadFromStream(AStream);
  except
    AStream.Position:=result.DataOffset+result.DataSize;
  end;
end;

end.
