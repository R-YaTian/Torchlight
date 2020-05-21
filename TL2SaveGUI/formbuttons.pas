unit formButtons;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  tl2base;

type

  { TfmButtons }

  TfmButtons = class(TForm)
    btnExport: TButton;
    btnImport: TButton;
    btnDelete: TButton;
    lblOffset: TLabel;
    procedure btnExportClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
  private
    FClass:TL2BaseClass;
    FName :string;
    FExt  :string;

    procedure SetOffset(aofs:integer);

  public
    property SClass:TL2BaseClass read FClass write FClass;
    property Name:string         read FName  write FName;
    property Ext:string          read FExt   write FExt;

    property Offset:integer write SetOffset;
  end;

var
  fmButtons: TfmButtons;

implementation

{$R *.lfm}

uses
  tl2stream;

{ TfmButtons }

resourcestring
  rsExportData   = 'Export data';
  rsImportData   = 'Import data';

procedure TfmButtons.SetOffset(aofs:integer);
begin
  if aofs<0 then
    lblOffset.Caption:=''
  else
    lblOffset.Caption:='0x'+HexStr(aofs,8);
end;

procedure TfmButtons.btnExportClick(Sender: TObject);
var
  ldlg:TSaveDialog;
  ls:string;
  lidx:integer;
begin
  ldlg:=TSaveDialog.Create(nil);
  try
    ldlg.FileName  :=FName;
    ldlg.DefaultExt:=FExt;
    ldlg.Title     :=rsExportData;
    ldlg.Options   :=ldlg.Options+[ofOverwritePrompt];
    if ldlg.Execute then
      FClass.SaveToFile(ldlg.FileName);
  finally
    ldlg.Free;
  end;
end;

procedure TfmButtons.btnImportClick(Sender: TObject);
var
  ldlg:TOpenDialog;
  lstrm:TTL2Stream;
  ls:string;
begin

  ldlg:=TOpenDialog.Create(nil);
  try
    ldlg.FileName  :='';
    ldlg.DefaultExt:=FExt;
    ldlg.Title     :=rsImportData;
    ldlg.Options   :=ldlg.Options;
    if ldlg.Execute then
    begin
      lstrm:=TTL2Stream.Create;
      lstrm.LoadFromFile(ldlg.FileName);
      lstrm.Position:=0;
      FClass.Clear;
      FClass.LoadFromStream(lstrm);
      lstrm.Free;

//!!!!!!!      tvSaveGameSelectionChanged(Self);
    end;
  finally
    ldlg.Free;
  end;
end;

end.

