unit uother;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils;

const
  TLNT_EOR = #239;
  TLNT_SE = #240;
  TLNT_NOP = #241;
  TLNT_DATA_MARK = #242;
  TLNT_BREAK = #243;
  TLNT_IP = #244;
  TLNT_AO = #245;
  TLNT_AYT = #246;
  TLNT_EC = #247;
  TLNT_EL = #248;
  TLNT_GA = #249;
  TLNT_SB = #250;
  TLNT_WILL = #251;
  TLNT_WONT = #252;
  TLNT_DO = #253;
  TLNT_DONT = #254;
  TLNT_IAC = #255;

function Explode(del, str: string): TStringArray;
function ExtractText(const Str: string; const Delim1, Delim2: char): string;
function GetDuration(dTime: integer): string;
function IfNull(variable: currency): string;
procedure Split(Delimiter: char; Str: string; ListOfStrings: TStrings);
function HexToString(H: string): string;

implementation

function Explode(del, str: string): TStringArray;
var
  i,ii : integer;
  lastpos : integer;
  lenstr : integer;
  lendel : integer;
  lenres : integer;
  matches : boolean;
begin;
  lastpos := 1;
  lenres := 0;
  setlength(result,lenres);
  lendel := length(del);
  lenstr := length(str);
  //  for i := 1 to lenstr do
  i := 1;
  while i <= lenstr do
  begin;
    if not ((i + lendel - 1) > lenstr) then
    begin
      matches := true;
      for ii := 1 to lendel do
        if str[i + ii - 1] <> del[ii] then
        begin
          matches := false;
          break;
        end;
      if matches then
      begin;
        inc(lenres);
        setlength(result,lenres);
        result[lenres-1] := Copy(str,lastpos,i-lastpos);
        lastpos := i+lendel;
        i := i + lendel-1;//Dirty
        if i = lenstr then //This was the trailing delimiter
          exit;
      end;
    end else //We cannot possibly find a delimiter anymore, thus copy the rest of the string and exit
      Break;
    inc(i);
  end;
  //Copy the rest of the string (if it's not a delimiter)
  inc(lenres);
  setlength(result,lenres);
  result[lenres-1] := Copy(str,lastpos,lenstr - lastpos + 1);
end;


function ExtractText(const Str: string; const Delim1, Delim2: char): string;
var
  pos1, pos2: integer;
begin
  Result := '';
  pos1 := Pos(Delim1, Str);
  pos2 := PosEx(Delim2, Str, Pos1 + 1);
  if (pos1 > 0) and (pos2 > pos1) then
    Result := Copy(Str, pos1 + 1, pos2 - pos1 - 1);
end;

function GetDuration(dTime: integer): string;
var
  t: integer;
begin
  t:=0;
  t:= Trunc(dTime / 10);
  FormatDateTime('nn:ss', t / SecsPerDay);
  result:=FormatDateTime('nn:ss', t / SecsPerDay);
end;

function IfNull(variable: currency): string;
var
  FS : TFormatSettings;
begin
  FS := DefaultFormatSettings;
  if variable = 0 then
    Result := '0.00'
  else
    Result := FormatFloat('#.##', variable, FS);
end;

procedure Split(Delimiter: char; Str: string; ListOfStrings: TStrings);
begin
  ListOfStrings.Clear;
  ListOfStrings.Delimiter := Delimiter;
  ListOfStrings.StrictDelimiter := True;
  ListOfStrings.DelimitedText := Str;
end;

function HexToString(H: string): string;
var
  I: integer;
begin
  Result := '';
  for I := 1 to length(H) div 2 do
    Result := Result + char(StrToInt('$' + Copy(H, (I - 1) * 2 + 1, 2)));
end;

end.
