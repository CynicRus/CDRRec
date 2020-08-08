unit udataworker;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uconnector, lptypes, lpvartypes, lpparser, lpcompiler, lputils, lpeval, lpinterpreter, lpmessages,
  typinfo, ffi, lpffi, ulpclasses, udatadumper, uother, udataexporter, usettings, ucommandlist, uplugins;

type
  { TDataWorker }
  PDataWorker = ^TDataWorker;

  TDataWorker = class(TThread)
  private
    FCompiler: TLapeCompiler;
    FConnector: TAbstractConnector;
    FDisplayString: string;
    FExporter: TDataExporter;
    FParser: TLapeTokenizerBase;
    FRawData: string;
    FProcessedData: string;
    FUsedPlugins: TMPluginsList;
  protected
    procedure Execute; override;
    function Import(): boolean;
    function Compile():boolean;
    function getRecorderId():integer;
    procedure OnHint(Sender: TLapeCompilerBase; Hint: lpString);
    procedure HandleException(e: Exception);
    function OnHandleDirective(Sender: TLapeCompiler; Directive, Argument: lpString;
      InPeek, InIgnore: boolean): boolean;
  public
    constructor Create(CreateSuspended: boolean);
    destructor Destroy; override;
    procedure Display;
    procedure RunScript();
    property Connector: TAbstractConnector read FConnector;
    property Exporter: TDataExporter read FExporter;
    property Parser: TLapeTokenizerBase read FParser;
    property Compiler: TLapeCompiler read FCompiler;
    property DisplayString: string read FDisplayString write FDisplayString;
    property RawData: string read FRawData write FRawData;
    property ProcessedData: string read FProcessedData write FProcessedData;
  end;

var
  DataWorker: TDataWorker;

implementation

uses umain;

procedure Log(Params: PParamArray); cdecl;
begin
  TDataWorker(Params^[0]).DisplayString := PlpString(Params^[1])^;
  TDataWorker(Params^[0]).Display;
end;

procedure lpSendCommand(Params: PParamArray); cdecl;
begin
  TDataWorker(Params^[0]).Connector.SendData(PString(Params^[1])^);
end;

procedure MyWriteLn(Params: PParamArray);  cdecl;
begin
  //WriteLn();
end;

procedure lpExtractText(const Params: PParamArray; const result: Pointer); cdecl;
begin
  PString(result)^ := ExtractText(Pstring(Params^[0])^, PChar(Params^[1])^, PChar(Params^[2])^);
end;

procedure lpExplode(const Params: PParamArray; const result: Pointer); cdecl;
type
  PlpStringArray = ^TStringArray;
begin
  PlpStringArray(result)^ := Explode(PString(Params^[0])^, PString(Params^[1])^);
end;

procedure lpDumpData(const Params: PParamArray); cdecl;
begin
  DumpCustomData(PString(Params^[0])^, PString(Params^[1])^);
end;

procedure lpGetRecorderId(const Params: PParamArray; const result: Pointer); cdecl;
begin
  PInteger(result)^ := TDataWorker(Params^[0]).getRecorderId();
end;

procedure getJustText(const Params: PParamArray; const result: Pointer); cdecl;
begin
  PString(result)^ := TDataWorker(Params^[0]).RawData;
end;

procedure SetJustText(Params: PParamArray); cdecl;
begin
  TDataWorker(Params^[0]).ProcessedData := PString(Params^[1])^;
end;

{ TDataWorker }

procedure TDataWorker.Execute;
var
  i: integer;
begin
  FConnector.Connect;
  if FConnector.LastError <> 0 then
  begin
    FDisplayString := format('Connection error: %d - %s', [FConnector.LastError, FConnector.LastErrorDesc]);
    Synchronize(@Display);
    Synchronize(@MainForm.OnErrorClick);
  end
  else
  begin
    FDisplayString := 'Connection: OK';
    Synchronize(@Display);
  end;
  if CommandList.AfterConnectCommands.Count > 0 then
    for i := 0 to CommandList.AfterConnectCommands.Count - 1 do
    begin
      FConnector.SendData(CommandList.AfterConnectCommands[i]);
      Sleep(100);
    end;
  while not (terminated) do
  begin
    try
      frawdata := '';
      ProcessedData := '';
      frawdata := FConnector.GetData();
      if FConnector.LastError <> 0 then
      begin
        FDisplayString := format('Connection error: %d - %s', [FConnector.LastError, FConnector.LastErrorDesc]);
        Synchronize(@Display);
        Synchronize(@MainForm.OnErrorClick);
      end;
      if FRawData <> '' then
      begin
        if Settings.UseInbuiltDataDump then
          DataDumper.DumpData(FRawData);
        Synchronize(@RunScript);
        //FDisplayString := ProcessedData;
        //Synchronize(@ Display);
        FRawData := '';
        if FProcessedData <> '' then
        begin
          Exporter.ExportData(FProcessedData);
          if Exporter.LastError <> 0 then
          begin
            FDisplayString := format('Export error: %d - %s', [FConnector.LastError, FConnector.LastErrorDesc]);
            Synchronize(@Display);
          end;
        end;
      end;
    except
      On E: Exception do
        HandleException(E);
    end;
    sleep(100);
  end;
end;

function TDataWorker.Import(): boolean;
begin
  result := false;
  try
    Compiler.StartImporting();
    Compiler.addBaseDefine('LAPE');
    Compiler.addGlobalVar(ExtractFilePath(ParamStr(0)), 'WorkingDirectory');
    Compiler.addGlobalMethod('function GetData():string;', @getJustText, self);
    Compiler.addGlobalMethod('procedure SetData(s: string);', @SetJustText, self);
    Compiler.addGlobalMethod('procedure _write(s: string); override;', @Log, self);
    Compiler.addGlobalMethod('procedure _writeln; override;', @MyWriteLn, self);
    RegisterLCLClasses(Compiler);
    with DefaultFormatSettings do
    begin
      Compiler.addGlobalVar(DateSeparator, 'DateSeparator');
      Compiler.addGlobalVar(TimeSeparator, 'TimeSeparator');
    end;
    Compiler.addGlobalFunc('function ExtractText(Str: string;Delim1, Delim2: char): string;', @lpExtractText);
    Compiler.addGlobalFunc('function Explode(del, str: string): TStringArray;', @lpExplode);
    Compiler.addGlobalFunc('procedure DumpData(FileName: string; Data: string);', @lpDumpData);
    Compiler.addGlobalFunc('procedure SendCommand(const Data: string);', @lpSendCommand);
    Compiler.addGlobalFunc('function GetRecorderID():integer;',@lpGetRecorderID);
    Compiler.EndImporting;
    result := true;
  except
    On E: Exception do
      HandleException(E);
  end;
end;

function TDataWorker.Compile(): boolean;
var
  T: Int64;
begin
  Result := False;

  try
    T := GetTickCount64();

    if FCompiler.Compile() then
    begin
      FDisplayString := 'Compiled successfully in ' + IntToStr(GetTickCount64() - T) + ' ms.';
      Synchronize(@Display);
      Result := True;
    end;
  except
    on e: Exception do
      HandleException(e);
  end;
end;

function TDataWorker.getRecorderId(): integer;
begin
  result := settings.Id;
end;

procedure TDataWorker.OnHint(Sender: TLapeCompilerBase; Hint: lpString);
begin
  FDisplayString := Hint;
  Synchronize(@Display);
end;

procedure TDataWorker.HandleException(e: Exception);
begin
  if (e is lpException) then
    with (e as lpException) do
      FDisplayString := format('col: %d, pos %d: %s', [DocPos.Col, DocPos.Line, Message])
  else
    FDisplayString := 'ERROR: ' + e.ClassName + ' :: ' + e.Message;
  Synchronize(@Display);
  Synchronize(@MainForm.OnErrorClick);
  //Display;
end;


function TDataWorker.OnHandleDirective(Sender: TLapeCompiler; Directive, Argument: lpString;
  InPeek, InIgnore: boolean): boolean;
var
  Arguments: TStringArray;
  Plugin: TMPlugin;
  i: integer;
begin
  if (UpperCase(Directive) = 'LOADLIB') or (UpperCase(Directive) = 'ERROR') then
  begin
    if InPeek or (Argument = '') then
      exit(true);

    try
      case UpperCase(Directive) of
        'ERROR': if (not InIgnore) then
            raise Exception.Create('User defined error: "' + Argument + '"');

        'LOADLIB':
        begin
          if InIgnore then
            exit;


          Plugin := Plugins.Get(Sender.Tokenizer.FileName, Argument, true);
          FDisplayString := Format('Loading plugin....%s',[ExtractFileName(Plugin.FilePath)]);
          Synchronize(@Display);
          for i := 0 to Plugin.Declarations.Size - 1 do
            Plugin.Declarations[i].Import(Sender);

          FUsedPlugins.PushBack(Plugin);
          FDisplayString:='Done.';
          Synchronize(@Display);
        end;

      end;
    except
      on e: Exception do
        raise lpException.Create(e.Message, Sender.DocPos);
    end;

    exit(true);
  end;

  exit(false);
end;

constructor TDataWorker.Create(CreateSuspended: boolean);
var
  St: TStringList;
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate := true;
  St := TStringList.Create;
  FUsedPlugins := TMPluginsList.Create();
  try
    St.LoadFromFile(Settings.DataProcessingScript);
    FConnector := TConnectorFactory.GetInstance(Settings.ConnectionType);
    FExporter := TExporterFactory.GetInstance(Settings.ExportType);
    FParser := TLapeTokenizerString.Create(st.Text);
    FCompiler := TLapeCompiler.Create(Parser);
    FCompiler.OnHandleDirective := @OnHandleDirective;
    FCompiler.OnHint := @OnHint;
    InitializeFFI(Compiler);
    InitializePascalScriptBasics(Compiler);
    ExposeGlobals(Compiler);
    Import;
    st.Free;
    Compile;
  except
    on E: Exception do
    begin
      HandleException(E);
      exit;
    end;
  end;
end;

destructor TDataWorker.Destroy;
var
  i,j: integer;
begin
  for i := 0 to CommandList.BeforeDisconnectCommands.Count - 1 do
  begin
    FConnector.SendData(CommandList.BeforeDisconnectCommands[i]);
    sleep(100);
  end;

    if (FUsedPlugins <> nil) then
  begin
    for j := 0 to FUsedPlugins.Size - 1 do
      FUsedPlugins[i].Free;

    FreeAndNil(FUsedPlugins);
  end;
  FDisplayString := 'Stopped.';
  Synchronize(@Display);
  if (Compiler <> nil) then
    Compiler.Free()
  else if (Parser <> nil) then
    Parser.Free();
  if (FConnector <> nil) then
    FConnector.Free;
  if (FExporter <> nil) then
    FExporter.Free;
  inherited Destroy;
end;

procedure TDataWorker.Display;
begin
  if MainForm.LogMemo.Lines.Count > 100 then
  begin
    DumpCustomData(ExtractFilePath(ParamStr(0)) + 'logs\log.txt', MainForm.LogMemo.Lines.Text);
    MainForm.LogMemo.Lines.Clear;
  end;
  MainForm.LogMemo.Lines.Add(FDisplayString);
end;

procedure TDataWorker.RunScript();
begin
  RunCode(Compiler.Emitter.Code, Compiler.Emitter.CodeLen);
end;

{$IF DEFINED(MSWINDOWS) AND DECLARED(LoadFFI)}
initialization
  if (not FFILoaded()) then
    LoadFFI(
    {$IFDEF Win32}
    'ffi\bin\win32'
    {$ELSE}
    'ffi\bin\win64'
    {$ENDIF}
    );
{$IFEND}

end.

