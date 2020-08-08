unit udatadumper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, StrUtils;

type

  { TDataDumper }

  TDataDumper = class
  private
    FCurrentFileName: string;
    FOldDate: TDateTime;
    FNewDate: TDateTime;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DumpCustomData(Filename: string; Data: string);
    procedure DumpData(const Data: string);
    property CurrentFileName: string read FCurrentFileName write FCurrentFileName;
  end;




var
  DataDumper: TDataDumper;


procedure DumpCustomData(FileName: string; Data: string);
implementation

procedure DumpCustomData(FileName: string; Data: string);
begin
  DataDumper.DumpCustomData(FileName,Data);
end;

{ TDataDumper }

constructor TDataDumper.Create;
begin
  FOldDate := Now();
  FNewDate := Now();
  CurrentFileName := ExtractFilePath(ParamStr(0)) + '/data/' +
    FormatDateTime('yyyy-mm-dd', Now) + '.sec';
end;

destructor TDataDumper.Destroy;
begin
  inherited Destroy;
end;

procedure TDataDumper.DumpCustomData(Filename: string; Data: string);
var
  Stm: TFileStream;
  str,f_name: string;
  S: ansistring;
  Buf: Pointer;
  BufSize: integer;
begin
  try
    Stm := TFileStream.Create(Filename, fmOpenReadWrite or fmShareDenyNone);
  except
    Stm := TFileStream.Create(Filename, fmCreate or fmShareDenyNone);
  end;
  try
    Stm.Position := Stm.Size;
    Str := Data + #13#10;
    BufSize := Length(Str);
    if SizeOf(char) = 1 then
      Buf := @Str[1]
    else
    begin
      S := Str;
      Buf := @S[1];
    end;

    if BufSize > 0 then
      Stm.Write(Buf^, BufSize);

  finally
    Stm.Free;
  end;

end;

procedure TDataDumper.DumpData(const Data: string);
var
  Stm: TFileStream;
  str: string;
  S: ansistring;
  Buf: Pointer;
  BufSize: integer;
begin
  FNewDate := Now;
  if (CompareDate(FOldDate, FNewDate) < 0) then
  begin
    CurrentFileName := ExtractFilePath(ParamStr(0)) + 'data/' +
      FormatDateTime('yyyy-mm-dd', Now) + '.sec';
  end;
  try
    Stm := TFileStream.Create(CurrentFileName, fmOpenReadWrite or fmShareDenyNone);
  except
    Stm := TFileStream.Create(CurrentFileName, fmCreate or fmShareDenyNone);
  end;
  try
    Stm.Position := Stm.Size;
    Str := Data + #13#10;
    BufSize := Length(Str);
    if SizeOf(char) = 1 then
      Buf := @Str[1]
    else
    begin
      S := Str;
      Buf := @S[1];
    end;

    if BufSize > 0 then
      Stm.Write(Buf^, BufSize);

  finally
    Stm.Free;
  end;

end;

initialization
 DataDumper := TDataDumper.Create;

finalization
 if DataDumper <> nil then
    DataDumper.Free;

end.

