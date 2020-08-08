unit uconnector;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Synaser, blcksock, synautil, uother, usettings;

type

  { TAbstractConnector }

  TAbstractConnector = class
  private
    FConnected: boolean;
    FLastError: integer;
    FLastErrorDesc: string;
    FAnswerTimeout: integer;
    FRecievedData: string;
    // FWaitingData: integer;
  public
    constructor Create;
    procedure Connect; virtual; abstract;
    procedure SendData(const Data: string); virtual; abstract;
    function GetData(): string; virtual; abstract;
    function GetByte(): byte; virtual; abstract;
    //procedure OnDataRecieve(Data: string); virtual; abstract;
    property Connected: boolean read FConnected write FConnected;
    property LastError: integer read FLastError write FLastError;
    property LastErrorDesc: string read FLastErrorDesc write FLastErrorDesc;
    property AnswerTimeout: integer read FAnswerTimeout write FAnswerTimeout;
    property RecievedData: string read FRecievedData write FRecievedData;
    //property WaitingData: integer read FWaitingData;

  end;

  { TRS232Connector }

  TRS232Connector = class(TAbstractConnector)
  private
    FConnector: TBlockSerial;
    FPortNo: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Connect; override;
    procedure SendData(const Data: string); override;
    function GetData(): string; override;
    function GetByte(): byte; override;
    //property Connector: TBlockSerial read FConnector;
    //property WaitingData;
    property Connected;
    property LastError;
    property LastErrorDesc;
    property RecievedData;
  end;


  { TEthernetConnector }

  TEthernetConnector = class(TAbstractConnector)
  private
    FConnector: TTCPBlockSocket;
    FIP: string;
    FPort: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Connect; override;
    procedure SendData(const Data: string); override;
    function GetData(): string; override;
    function GetByte(): byte; override;
    //property Connector: TTCPBlockSocket read FConnector;
    //property WaitingData;
    property Connected;
    property LastError;
    property LastErrorDesc;
    property RecievedData;
  end;

  { TTelnetConnector }
  {:@abstract(State of telnet protocol). Used internaly by TTelnetSend.}
  TTelnetState = (tsDATA, tsIAC, tsIAC_SB, tsIAC_WILL, tsIAC_DO, tsIAC_WONT,
    tsIAC_DONT, tsIAC_SBIAC, tsIAC_SBDATA, tsSBDATA_IAC);

  TTelnetConnector = class(TAbstractConnector)
  private
    FConnector: TTCPBlockSocket;
    FIP: string;
    FPort: string;
    FState: TTelnetState;
    FTermType: string;
    FSubNeg: string;
    FSubType: char;
    function TelnetNegotiate(const Buf: string): string;
    procedure TelnetSend(const Value: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Connect; override;
    procedure SendData(const Data: string); override;
    function GetData(): string; override;
    function GetByte(): byte; override;
    property Connected;
    property LastError;
    property LastErrorDesc;
    property RecievedData;
  end;

  { TConnectorFactory }

  TConnectorFactory = class
  public
    class function GetInstance(ConnectorType: integer): TAbstractConnector;
  end;



implementation

{ TTelnetConnector }

function TTelnetConnector.TelnetNegotiate(const Buf: string): string;
var
  n: integer;
  c: Ansichar;
  Reply: ansistring;
  SubReply: ansistring;
begin
  Result := '';
  for n := 1 to Length(Buf) do
  begin
    c := Buf[n];
    Reply := '';
    case FState of
      tsData:
        if c = TLNT_IAC then
          FState := tsIAC
        else
          Result := Result + c;

      tsIAC:
        case c of
          TLNT_IAC:
          begin
            FState := tsData;
            Result := Result + TLNT_IAC;
          end;
          TLNT_WILL:
            FState := tsIAC_WILL;
          TLNT_WONT:
            FState := tsIAC_WONT;
          TLNT_DONT:
            FState := tsIAC_DONT;
          TLNT_DO:
            FState := tsIAC_DO;
          TLNT_EOR:
            FState := tsDATA;
          TLNT_SB:
          begin
            FState := tsIAC_SB;
            FSubType := #0;
            FSubNeg := '';
          end;
          else
            FState := tsData;
        end;

      tsIAC_WILL:
      begin
        case c of
          #3:  //suppress GA
            Reply := TLNT_DO;
          else
            Reply := TLNT_DONT;
        end;
        FState := tsData;
      end;

      tsIAC_WONT:
      begin
        Reply := TLNT_DONT;
        FState := tsData;
      end;

      tsIAC_DO:
      begin
        case c of
          #24:  //termtype
            Reply := TLNT_WILL;
          else
            Reply := TLNT_WONT;
        end;
        FState := tsData;
      end;

      tsIAC_DONT:
      begin
        Reply := TLNT_WONT;
        FState := tsData;
      end;

      tsIAC_SB:
      begin
        FSubType := c;
        FState := tsIAC_SBDATA;
      end;

      tsIAC_SBDATA:
      begin
        if c = TLNT_IAC then
          FState := tsSBDATA_IAC
        else
          FSubNeg := FSubNeg + c;
      end;

      tsSBDATA_IAC:
        case c of
          TLNT_IAC:
          begin
            FState := tsIAC_SBDATA;
            FSubNeg := FSubNeg + c;
          end;
          TLNT_SE:
          begin
            SubReply := '';
            case FSubType of
              #24:  //termtype
              begin
                if (FSubNeg <> '') and (FSubNeg[1] = #1) then
                  SubReply := #0 + FTermType;
              end;
            end;
            FConnector.SendString(TLNT_IAC + TLNT_SB + FSubType + SubReply +
              TLNT_IAC + TLNT_SE);
            FState := tsDATA;
          end;
          else
            FState := tsDATA;
        end;

      else
        FState := tsData;
    end;
    if Reply <> '' then
      FConnector.SendString(TLNT_IAC + Reply + c);
  end;

end;

procedure TTelnetConnector.TelnetSend(const Value: string);
begin
  FConnector.SendString(ReplaceString(Value, TLNT_IAC, TLNT_IAC + TLNT_IAC));
end;

constructor TTelnetConnector.Create;
begin
  FConnector := TTCPBlockSocket.Create;
  fTermType := 'TELNET';
end;

destructor TTelnetConnector.Destroy;
begin
  if Connected then
    FConnector.CloseSocket;
  FConnector.Free;
  inherited Destroy;
end;

procedure TTelnetConnector.Connect;
var
  ConCfg: TTelnetConnectionSettings;
begin
  ConCfg := TTelnetConnectionSettings(Settings.ConnectionSettings);
  FState := tsDATA;
  FConnector.LineBuffer := '';
  FConnector.Connect(ConCfg.IPAddr, ConCfg.Port);
  if FConnector.LastError <> 0 then
  begin
    self.LastError := FConnector.LastError;
    Self.LastErrorDesc := FConnector.LastErrorDesc;
  end
  else
    Connected := True;

end;

procedure TTelnetConnector.SendData(const Data: string);
begin
  TelnetSend(Data);
end;

function TTelnetConnector.GetData(): string;
var
  data: string;
begin
  data := '';
  while Length(Data) = 0 do
  if FConnector.CanRead(1000) then
        Data :=  TelnetNegotiate(FConnector.RecvPacket(1000));
  result := data;

end;

function TTelnetConnector.GetByte(): byte;
begin
  result := FConnector.RecvByte(1000);
end;

{ TConnectorFactory }

class function TConnectorFactory.GetInstance(ConnectorType: integer): TAbstractConnector;
begin
  case ConnectorType of
    0: Result := TEthernetConnector.Create;
    1: Result := TRS232Connector.Create;
    2: Result := TTelnetConnector.Create;
  end;
end;

{ TEthernetConnector }

constructor TEthernetConnector.Create;
begin
  FConnector := TTCPBlockSocket.Create;
  //FWaitingData := FConnector.WaitingData;
end;

destructor TEthernetConnector.Destroy;
begin
  if Connected then
    FConnector.CloseSocket;
  FConnector.Free;
  inherited Destroy;
end;

procedure TEthernetConnector.Connect;
var
  ConCfg: TTCPIPConnectionSettings;
begin
  ConCfg := TTCPIPConnectionSettings(Settings.ConnectionSettings);
  FConnector.Connect(ConCfg.IPAddr, ConCfg.Port);
  if FConnector.LastError <> 0 then
  begin
    self.LastError := FConnector.LastError;
    Self.LastErrorDesc := FConnector.LastErrorDesc;
  end
  else
    Connected := True;
end;


procedure TEthernetConnector.SendData(const Data: string);
begin
  FConnector.SendString(Data);
  if FConnector.LastError <> 0 then
  begin
    Self.LastError := FConnector.LastError;
    Self.LastErrorDesc := FConnector.LastErrorDesc;
    //exit;
  end;
end;

function TEthernetConnector.GetData(): string;
const
  recvTimeout = 200;
var
  waiting: integer;
  i: integer;
  output: string;
begin
  waiting := 0;
  output := '';

  waiting := FConnector.WaitingData;

  for i := 0 to waiting - 1 do
    output += IntToHex(FConnector.RecvByte(1000), 2);

  output := HexToString(output);
  //output := StringReplace(output, ' ', '', [rfReplaceAll]);
  //output := StringReplace(output, '#13#10', '', [rfReplaceAll]);
  Result := output;

end;

function TEthernetConnector.GetByte(): byte;
begin
  Result := FConnector.RecvByte(500);
end;

{ TRS232Connector }

constructor TRS232Connector.Create;
begin
  FConnector := TBlockSerial.Create;
  // FWaitingData := FConnector.WaitingData;
  inherited;
end;

destructor TRS232Connector.Destroy;
begin
  if Connected then
    FConnector.CloseSocket;
  FConnector.Free;
  inherited Destroy;
end;

procedure TRS232Connector.Connect;
var
  ConCfg: TRS232ConnectionSettings;
  Softflow, HardFlow: boolean;
begin
  with FConnector do
  begin
    ConCfg := TRS232ConnectionSettings(Settings.ConnectionSettings);
    Connect(ConCfg.ComPort);
    LinuxLock := False;
    sleep(1000);
    if ConCfg.FlowControl = fcNone then
    begin
      Softflow := False;
      Hardflow := False;
    end
    else if ConCfg.FlowControl = fcXonXoff then
    begin
      Softflow := True;
      Hardflow := False;
    end
    else if ConCfg.FlowControl = fcHardware then
    begin
      Softflow := False;
      Hardflow := True;
    end;
    Config(ConstsBaud[ConCfg.BaudRate],
      ConstsBits[ConCfg.DataBits],
      ConstsParity[ConCfg.Parity],
      ConstsStopBits[ConCfg.StopBits],
      Softflow, Hardflow);
    Sleep(1000);
    self.LastError := LastError;
    Self.LastErrorDesc := LastErrorDesc;
    if self.LastError = 0 then
      Connected := True;
  end;

end;

//function TRS232Connector.Configure(const ConnectionString: string): boolean;
//var
//  St: TStringList;
//begin
//  Result := False;
//  St := TStringList.Create;
//  try
//    Split('=', ConnectionString, St);
//    if St.Count > 0 then
//    begin
//      FPortNo := UpperCase(St[1]);
//      Configured := True;
//      Result := True;
//    end;
//  finally
//    St.Free;
//  end;
//end;

procedure TRS232Connector.SendData(const Data: string);
begin
  FConnector.SendString(Data);
  if FConnector.LastError <> 0 then
  begin
    Self.LastError := FConnector.LastError;
    Self.LastErrorDesc := FConnector.LastErrorDesc;
  end;
  sleep(500);
end;

function TRS232Connector.GetData(): string;
const
  recvTimeout = 200;
var
  waiting: integer;
  i: integer;
  output: string;
begin
  waiting := 0;
  output := '';

  waiting := FConnector.WaitingData;

  for i := 0 to waiting - 1 do
    output += IntToHex(FConnector.RecvByte(2000), 2);

  output := HexToString(output);
  //output := StringReplace(output, ' ', '', [rfReplaceAll]);
  //output := StringReplace(output, '#13#10', '', [rfReplaceAll]);
  Result := output;

end;

function TRS232Connector.GetByte(): byte;
begin
  Result := FConnector.RecvByte(500);
end;

{ TAbstractConnector }

constructor TAbstractConnector.Create;
begin
  FConnected := False;
  FLastError := 0;
  LastErrorDesc := '';
end;

end.
