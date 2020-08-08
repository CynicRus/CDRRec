unit udataexporter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, blcksock, fphttpclient, simpleipc, uother, usettings;

type

  { TDataExporter }

  TDataExporter = class
  private
    FConnected: boolean;
    FKeepConnection: boolean;
    FLastError: integer;
    FLastErrorDesc: string;
  public
    procedure ExportData(const Data: string); virtual; abstract;
    property KeepConnection: boolean read FKeepConnection write FKeepConnection;
    property Connected: boolean read FConnected write FConnected;
    property LastError: integer read FLastError write FLastError;
    property LastErrorDesc: string read FLastErrorDesc write FLastErrorDesc;
  end;

  { TTCPDataExporter }

  TTCPDataExporter = class(TDataExporter)
  private
    FConnector: TTCPBlockSocket;
    FIP: string;
    FPort: string;
    procedure Connect;
    procedure Disconnect;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ExportData(const Data: string); override;
    property KeepConnection;
    property Connected;
    property LastError;
    property LastErrorDesc;
  end;

  { THTTPDataExporter }

  THTTPDataExporter = class(TDataExporter)
  private
    FURL: string;
  public
    Constructor Create;
    procedure ExportData(const Data: string); override;
    property KeepConnection;
    property Connected;
    property LastError;
    property LastErrorDesc;
  end;

  { TIPCDataExporter }

  TIPCDataExporter = class(TDataExporter)
  private
    FIPCName: string;
    FDataSender: TSimpleIPCClient;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ExportData(const Data: string); override;
    property KeepConnection;
    property Connected;
    property LastError;
    property LastErrorDesc;
  end;

  { TExporterFactory }

  TExporterFactory = class
  public
    class function GetInstance(ExportType: integer): TDataExporter;
  end;

//procedure ExportData();

implementation

{ TTCPDataExporter }

procedure TTCPDataExporter.Connect;

begin
  FConnector.Connect(FIP, FPort);
  if FConnector.LastError <> 0 then
  begin
    self.LastError := LastError;
    Self.LastErrorDesc := LastErrorDesc;
  end
  else
    Connected := True;
end;

procedure TTCPDataExporter.Disconnect;
begin
  if Connected then
  begin
    FConnector.CloseSocket;
    Connected := False;
  end;

end;

constructor TTCPDataExporter.Create;
var
  ConCfg: TTCPIPExportSettings;
begin
  FConnector := TTCPBlockSocket.Create;
  ConCfg := TTCPIPExportSettings(Settings.ExportSettings);
  KeepConnection := ConCfg.KeepConnection;
  FIP := ConCfg.IP;
  FPort := ConCfg.Port;

end;

destructor TTCPDataExporter.Destroy;
begin
  if FConnector <> nil then
    FConnector.Free;
  inherited Destroy;
end;

procedure TTCPDataExporter.ExportData(const Data: string);
begin
  if not Connected then
    Connect;
  FConnector.SendString(Data + CRLF);
  if FConnector.LastError <> 0 then
  begin
    Self.LastError := FConnector.LastError;
    Self.LastErrorDesc := FConnector.LastErrorDesc;
    exit;
  end;
  if not KeepConnection then
    Disconnect;
end;

{ THTTPDataExporter }

constructor THTTPDataExporter.Create;
begin
  FURL := THTTPExportSettings(Settings.ExportSettings).URL;
end;

procedure THTTPDataExporter.ExportData(const Data: string);
var
  httpClient: TFPHTTPClient;
begin
  try
    httpClient := TFPHTTPClient.Create(nil);
    try
      httpClient.FormPost(FURL, Data);
      //httpClient.Post();
    except
      on E: Exception do
      begin
        self.LastError := 1;
        self.LastErrorDesc := E.Message;
      end;
    end;
  finally
    httpClient.Free;
  end;

end;

{ TIPCDataExporter }

constructor TIPCDataExporter.Create;
begin
  FDataSender := TSimpleIPCClient.Create(nil);
  FIPCName := TIPCExportSettings(Settings.ExportSettings).IPCName;
end;

destructor TIPCDataExporter.Destroy;
begin
  if (FDataSender <> nil) then
  begin
    FDataSender.Free;
  end;
  inherited Destroy;
end;

procedure TIPCDataExporter.ExportData(const Data: string);
begin
  FDataSender.ServerID := FIPCName;
  FDataSender.Connect;
  try
    with FDataSender do
    begin
      SendStringMessage(Data);
      Disconnect;
    end;
  except
    on E: Exception do
    begin
      self.LastError := 1;
      self.LastErrorDesc := E.Message;
    end;
  end;

end;

{ TExporterFactory }

class function TExporterFactory.GetInstance(ExportType: integer): TDataExporter;
begin
  case ExportType of
    0: Result := TTCPDataExporter.Create;
    1: Result := THTTPDataExporter.Create;
    2: Result := TIPCDataExporter.Create;
  end;
end;



end.



