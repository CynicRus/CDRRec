unit ucommandlist;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ujson;

const
  CommandsFile = '/config/commands.pkg';

type

  { TCommandList }

  TCommandList = class
  private
    FAfterConnectCommands: TStringList;
    FBeforeDisconnectCommands: TStringList;
    function AsJson(): string;
    procedure FromJson(const Data: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Save;
    procedure Load;
    property AfterConnectCommands: TStringList read FAfterConnectCommands;
    property BeforeDisconnectCommands: TStringList read FBeforeDisconnectCommands;

  end;

var
  CommandList: TCommandList;

implementation

{ TCommandList }

constructor TCommandList.Create;
begin
  FAfterConnectCommands := TStringList.Create;
  FBeforeDisconnectCommands := TStringList.Create;
end;

destructor TCommandList.Destroy;
begin
  FAfterConnectCommands.Free;
  FBeforeDisconnectCommands.Free;
  inherited Destroy;
end;

procedure TCommandList.Save;
var
   F: TFileStream;
   Str: string;
   Size: integer;
begin
   F := TFileStream.Create(ExtractFilePath(ParamStr(0))+CommandsFile, fmCreate);
   try
     Str := AsJson();
     Size := Length(Str);
      F.WriteBuffer(Size,SizeOf(Integer));
      F.WriteBuffer(Pointer(Str)^,Length(Str));
   finally
      F.Free;
   end;
end;

procedure TCommandList.Load;
var
F: TFileStream;
Str: String;
Size: Integer;
begin
Size := 0;
F:=TFileStream.Create(ExtractFilePath(ParamStr(0))+CommandsFile,fmOpenRead);
try
  F.ReadBuffer(Size,SizeOf(Integer));
  SetLength(Str,Size);
  F.ReadBuffer(Pointer(Str)^,Size);
  fromJson(Str);
finally
  F.Free;
end;
end;

function TCommandList.AsJson(): string;
var
  Obj: TJsonObject;
  ConnectStream, DisconnectStream: TStringStream;
begin
  Obj := TJsonObject.Create();
  ConnectStream := TStringStream.Create('');
  DisconnectStream := TStringStream.Create('');
  try
    AfterConnectCommands.SaveToStream(ConnectStream);
    BeforeDisconnectCommands.SaveToStream(DisconnectStream);
    Obj.put('connect', ConnectStream.DataString);
    Obj.put('disconnect', DisconnectStream.DataString);
    Result := Obj.toString();
  finally
    ConnectStream.Free;
    DisconnectStream.Free;
    Obj.Free;
  end;

end;

procedure TCommandList.FromJson(const Data: string);
var
  Obj: TJsonObject;
  ConnectStream, DisconnectStream: TStringStream;
begin
  Obj := TJsonObject.Create(Data);
  try
    ConnectStream := TStringStream.Create(Obj.optString('connect'));
    DisconnectStream := TStringStream.Create(Obj.optString('disconnect'));
    if ConnectStream.size > 0 then
      AfterConnectCommands.LoadFromStream(ConnectStream);
    if DisconnectStream.size > 0 then
      BeforeDisconnectCommands.SaveToStream(DisconnectStream);
  finally
    ConnectStream.Free;
    DisconnectStream.Free;
    Obj.Free;
  end;

end;

initialization
  CommandList := TCommandList.Create;


finalization
  if CommandList <> nil then
    CommandList.Free;
end.
