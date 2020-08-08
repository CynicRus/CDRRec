unit usettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, ujson, synaser;

type
  TBaudRate = (br___110, br___300, br___600, br__1200, br__2400, br__4800,
    br__9600, br_14400, br_19200, br_38400, br_56000, br_57600,
    br115200, br128000, br230400, br256000, br460800, br921600);
  TDataBits = (db8bits, db7bits, db6bits, db5bits);
  TParity = (pNone, pOdd, pEven, pMark, pSpace);
  TFlowControl = (fcNone, fcXonXoff, fcHardware);
  TStopBits = (sbOne, sbOneAndHalf, sbTwo);

const
  Configfile = '/config/settings.ini';
  ConstsBaud: array[TBaudRate] of integer = (110,
    300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 38400, 56000, 57600,
    115200, 128000, 230400, 256000, 460800, 921600);

  ConstsBits: array[TDataBits] of integer = (8, 7, 6, 5);
  ConstsParity: array[TParity] of char = ('N', 'O', 'E', 'M', 'S');
  ConstsStopBits: array[TStopBits] of integer = (SB1, SB1AndHalf, SB2);
  BaudRateStrings: array[TBaudRate] of string = ('110', '300', '600',
    '1200', '2400', '4800', '9600', '14400', '19200', '38400', '56000', '57600',
    '115200', '128000', '230400', '256000', '460800', '921600');
  StopBitsStrings: array[TStopBits] of string = ('1', '1.5', '2');
  DataBitsStrings: array[TDataBits] of string = ('8', '7', '6', '5');
  ParityBitsStrings: array[TParity] of string = ('N', 'O', 'E',
    'M', 'S');
  FlowControlStrings: array[TFlowControl] of string = ('None',
    'Software', 'HardWare');

type

  TConnectionSettings = class
  public
    function AsJson: string; virtual; abstract;
    procedure fromJson(const Json: string); virtual; abstract;
  end;

  { TTCPIpConnectionSettings }

  TTCPIpConnectionSettings = class(TConnectionSettings)
  private
    FIP: string;
    FPort: string;
  public
    function AsJson: string; override;
    procedure fromJson(const Json: string); override;
    property IPAddr: string read FIP write FIP;
    property Port: string read FPort write FPort;
  end;

  { TRS232ConnectionSettings }

  TRS232ConnectionSettings = class(TConnectionSettings)
  private
    FBaudRate: TBaudRate;
    FComport: string;
    FDataBits: TDataBits;
    FFlowControl: TFlowControl;
    FParity: TParity;
    FStopBits: TStopBits;
  public
    function AsJson: string; override;
    procedure fromJson(const Json: string); override;
    property ComPort: string read FComport write FComport;
    property BaudRate: TBaudRate read FBaudRate write FBaudRate;
    property DataBits: TDataBits read FDataBits write FDataBits;
    property StopBits: TStopBits read FStopBits write FStopBits;
    property Parity: TParity read FParity write FParity;
    property FlowControl: TFlowControl read FFlowControl write FFLowControl;

  end;

   { TTelnetConnectionSettings }

   TTelnetConnectionSettings = class(TConnectionSettings)
  private
    FIP: string;
    FPort: string;
  public
    function AsJson: string; override;
    procedure fromJson(const Json: string); override;
    property IPAddr: string read FIP write FIP;
    property Port: string read FPort write FPort;
  end;

  { TTCPIPExportSettings }

  TTCPIPExportSettings = class(TConnectionSettings)
  private
    FIP: string;
    FKeepConnection: boolean;
    FPort: string;
  public
    function AsJson: string; override;
    procedure fromJson(const Json: string); override;
    property IP: string read FIP write FIP;
    property Port: string read FPort write FPort;
    property KeepConnection: boolean read FKeepConnection write FKeepConnection;
  end;

  { THTTPExportSettings }

  THTTPExportSettings = class(TConnectionSettings)
  private
    FURL: string;
  public
    function AsJson: string; override;
    procedure fromJson(const Json: string); override;
    property URL: string read FURL write FURL;
  end;

  { TIPCExportSettings }

  TIPCExportSettings = class(TConnectionSettings)
  private
    FIPCName: string;
  public
    function AsJson: string; override;
    procedure fromJson(const Json: string); override;
    property IPCName: string read FIPCName write FIPCName;
  end;

  { TSettings }

  TSettings = class
  private
    FConnectionSettings: TConnectionSettings;
    FConnectionType: integer;
    FExportSettings: TConnectionSettings;
    FExportType: integer;
    FId: integer;
    FLangIndex: integer;
    FScriptPath: string;
    FUseInbuiltDataDump: boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load;
    procedure Save;
    procedure ChangeConnectionSettings(const Data: string);
    procedure ChangeExportSettings(const Data: string);
    property ConnectionType: integer read FConnectionType write FConnectionType;
    property ConnectionSettings: TConnectionSettings read FConnectionSettings;
    property ExportType: integer read FExportType write FExportType;
    property ExportSettings: TConnectionSettings read FExportSettings;
    property DataProcessingScript: string read FScriptPath write FScriptPath;
    property UseInbuiltDataDump: boolean read FUseInbuiltDataDump
      write FUseInbuiltDataDump;
    property LangIndex: integer read FLangIndex write FLangIndex;
    property Id: integer read FId write FId;
  end;



function StrToBaudRate(Str: string): TBaudRate;
function StrToStopBits(Str: string): TStopBits;
function StrToDataBits(Str: string): TDataBits;
function StrToParity(Str: string): TParity;
function StrToFlowControl(Str: string): TFlowControl;
function BaudRateToStr(BaudRate: TBaudRate): string;
function StopBitsToStr(StopBits: TStopBits): string;
function DataBitsToStr(DataBits: TDataBits): string;
function ParityToStr(Parity: TParity): string;
function FlowControlToStr(FlowControl: TFlowControl): string;

var
  AppPath: string;
  Settings: TSettings;

implementation

procedure StringArrayToList(AList: TStrings; const AStrings: array of string);
var
  Cpt: integer;
begin
  for Cpt := Low(AStrings) to High(AStrings) do
    AList.Add(AStrings[Cpt]);
end;



// string to baud rate
function StrToBaudRate(Str: string): TBaudRate;
var
  I: TBaudRate;
begin
  I := Low(TBaudRate);
  while (I <= High(TBaudRate)) do
  begin
    if UpperCase(Str) = UpperCase(BaudRateToStr(TBaudRate(I))) then
      Break;
    I := Succ(I);
  end;
  if I > High(TBaudRate) then
    Result := br__9600
  else
    Result := I;
end;

// string to stop bits
function StrToStopBits(Str: string): TStopBits;
var
  I: TStopBits;
begin
  I := Low(TStopBits);
  while (I <= High(TStopBits)) do
  begin
    if UpperCase(Str) = UpperCase(StopBitsToStr(TStopBits(I))) then
      Break;
    I := Succ(I);
  end;
  if I > High(TStopBits) then
    Result := sbOne
  else
    Result := I;
end;

// string to data bits
function StrToDataBits(Str: string): TDataBits;
var
  I: TDataBits;
begin
  I := Low(TDataBits);
  while (I <= High(TDataBits)) do
  begin
    if UpperCase(Str) = UpperCase(DataBitsToStr(I)) then
      Break;
    I := Succ(I);
  end;
  if I > High(TDataBits) then
    Result := db8bits
  else
    Result := I;
end;

// string to parity
function StrToParity(Str: string): TParity;
var
  I: TParity;
begin
  I := Low(TParity);
  while (I <= High(TParity)) do
  begin
    if UpperCase(Str) = UpperCase(ParityToStr(I)) then
      Break;
    I := Succ(I);
  end;
  if I > High(TParity) then
    Result := pNone
  else
    Result := I;
end;

// string to flow control
function StrToFlowControl(Str: string): TFlowControl;
var
  I: TFlowControl;
begin
  I := Low(TFlowControl);
  while (I <= High(TFlowControl)) do
  begin
    if UpperCase(Str) = UpperCase(FlowControlToStr(I)) then
      Break;
    I := Succ(I);
  end;
  if I > High(TFlowControl) then
    Result := fcNone
  else
    Result := I;
end;

// baud rate to string
function BaudRateToStr(BaudRate: TBaudRate): string;
begin
  Result := BaudRateStrings[BaudRate];
end;

// stop bits to string
function StopBitsToStr(StopBits: TStopBits): string;
begin
  Result := StopBitsStrings[StopBits];
end;

// data bits to string
function DataBitsToStr(DataBits: TDataBits): string;
begin
  Result := DataBitsStrings[DataBits];
end;

// parity to string
function ParityToStr(Parity: TParity): string;
begin
  Result := ParityBitsStrings[Parity];
end;

// flow control to string
function FlowControlToStr(FlowControl: TFlowControl): string;
begin
  Result := FlowControlStrings[FlowControl];
end;

{ TTelnetConnectionSettings }

function TTelnetConnectionSettings.AsJson: string;
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create();
  try
    Obj.put('ip', ipaddr);
    Obj.put('port', port);

    Result := Obj.toString();
  finally
    Obj.Free;
  end;

end;

procedure TTelnetConnectionSettings.fromJson(const Json: string);
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create(Json);
  try
    IpAddr := Obj.optString('ip');
    Port := Obj.optString('port');
  finally
    Obj.Free;
  end;

end;

{ TSettings }

constructor TSettings.Create;
begin

end;

destructor TSettings.Destroy;
begin

end;

procedure TSettings.Load;
var
  Ini: TIniFile;
begin
  Ini := nil;
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + Configfile);
  try
    ConnectionType := Ini.ReadInteger('Connection', 'ConnectionType', 0);
    ChangeConnectionSettings(Ini.ReadString('Connection','Configuration','{"ip":"127.0.0.1","port":"5050"}'));
    ExportType := Ini.ReadInteger('Export', 'ExportType', 0);
    ChangeExportSettings(Ini.ReadString('Export','Configuration','{"ip":"127.0.0.1","port":"5050","keep_connection":false}'));
    DataProcessingScript := Ini.ReadString('Application', 'Script', ExtractFilePath(ParamStr(0))+'scripts\script.lp');
    UseInbuiltDataDump := Ini.ReadBool('Application', 'DataDump', True);
    LangIndex := Ini.ReadInteger('Application', 'Lang', 0);
    Id := Ini.ReadInteger('Application','ID',1);
  finally
    Ini.Free;
  end;
end;

procedure TSettings.Save;
var
  Ini: TIniFile;
begin
  Ini := nil;
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + Configfile);
  try
    Ini.WriteInteger('Connection', 'ConnectionType', ConnectionType);
    Ini.WriteString('Connection', 'Configuration', ConnectionSettings.AsJson);
    Ini.WriteInteger('Export', 'ExportType', ExportType);
    Ini.WriteString('Export', 'Configuration', ExportSettings.AsJson);
    //DataProcessingScriptIndex := Ini.ReadInteger('Application','Script',0);
    //UseInbuildDataDump:= Ini.ReadBool('Application','DataDump',true);
    //LangIndex := Ini.ReadInteger('Application','Lang',0);
    Ini.WriteString('Application', 'Script', DataProcessingScript);
    Ini.WriteBool('Application', 'DataDump', UseInbuiltDataDump);
    Ini.WriteInteger('Application', 'Lang', LangIndex);
    Ini.WriteInteger('Application','ID',id);
  finally
    Ini.Free;
  end;
end;

procedure TSettings.ChangeConnectionSettings(const Data: string);
begin
  ConnectionSettings.Free;
  case ConnectionType of
      0:FConnectionSettings := TTCPIPConnectionSettings.Create;
      1: FConnectionSettings := TRS232ConnectionSettings.Create;
      2: FConnectionSettings := TTelnetConnectionSettings.Create;
  end;
  ConnectionSettings.fromJson(data);
end;

procedure TSettings.ChangeExportSettings(const Data: string);
begin
  ExportSettings.Free;
  case ExportType of
      0: FExportSettings := TTCPIPExportSettings.Create;
      1: FExportSettings := THTTPExportSettings.Create;
      2: FExportSettings := TIPCExportSettings.Create;
    end;
  ExportSettings.fromJson(data);

end;

{ TTCPIPExportSettings }

function TTCPIPExportSettings.AsJson: string;
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create();
  try
    Obj.put('ip', ip);
    Obj.put('port', port);
    Obj.put('keep_connection', KeepConnection);

    Result := Obj.toString();
  finally
    Obj.Free;
  end;

end;

procedure TTCPIPExportSettings.fromJson(const Json: string);
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create(Json);
  try
    IP := Obj.optString('ip', '127.0.0.1');
    Port := Obj.optString('port', '5050');
    KeepConnection := Obj.optBoolean('keep_connection');
  finally
    Obj.Free;
  end;

end;

{ TIPCExportSettings }

function TIPCExportSettings.AsJson: string;
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create();
  try
    Obj.put('ipcname', ipcname);

    Result := Obj.toString();
  finally
    Obj.Free;
  end;

end;

procedure TIPCExportSettings.fromJson(const Json: string);
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create(Json);
  try
    ipcname := Obj.optString('ipcname', 'ats_rec');
  finally
    Obj.Free;
  end;

end;

{ THTTPExportSettings }

function THTTPExportSettings.AsJson: string;
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create();
  try
    Obj.put('url', url);

    Result := Obj.toString();
  finally
    Obj.Free;
  end;

end;

procedure THTTPExportSettings.fromJson(const Json: string);
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create(Json);
  try
    url := Obj.optString('url', 'localhost');
  finally
    Obj.Free;
  end;

end;

{ TRS232ConnectionSettings }

function TRS232ConnectionSettings.AsJson: string;
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create();
  try
    Obj.put('com', ComPort);
    Obj.put('baudrate', BaudRateToStr(BaudRate));
    Obj.put('databits', DataBitsToStr(DataBits));
    Obj.put('stopbits', StopBitsToStr(StopBits));
    Obj.put('parity', ParityToStr(Parity));
    Obj.put('flow', FlowControlToStr(FlowControl));
    Result := Obj.toString();
  finally
    Obj.Free;
  end;

end;

procedure TRS232ConnectionSettings.fromJson(const Json: string);
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create(Json);
  try
    Comport := Obj.optString('com', 'COM1');
    BaudRate := StrToBaudRate(Obj.optString('baudrate', '115200'));
    DataBits := StrToDataBits(Obj.optString('databits', '8'));
    StopBits := StrToStopBits(Obj.optString('stopbits', '1'));
    Parity := StrToParity(Obj.optString('parity', 'N'));
    FlowControl := StrToFlowControl(Obj.optString('flow', 'None'));
  finally
    Obj.Free;
  end;

end;


{ TTCPIpConnectionSettings }

function TTCPIpConnectionSettings.AsJson: string;
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create();
  try
    Obj.put('ip', ipaddr);
    Obj.put('port', port);

    Result := Obj.toString();
  finally
    Obj.Free;
  end;

end;

procedure TTCPIpConnectionSettings.fromJson(const Json: string);
var
  Obj: TJsonObject;
begin
  Obj := TJsonObject.Create(Json);
  try
    IpAddr := Obj.optString('ip');
    Port := Obj.optString('port');
  finally
    Obj.Free;
  end;

end;

initialization
  AppPath := ExtractFilePath(ParamStr(0));
  Settings := TSettings.Create;
  Settings.Load;
  //Settings.Save;

finalization
  if Settings <> nil then
    Settings.Free;

end.
