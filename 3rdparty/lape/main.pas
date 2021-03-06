unit Main;

{$I lape.inc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, SynEdit, SynHighlighterPas, lptypes, lpvartypes;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnRun: TButton;
    btnMemLeaks: TButton;
    btnEvalRes: TButton;
    btnEvalArr: TButton;
    btnDisassemble: TButton;
    e: TSynEdit;
    m: TMemo;
    pnlTop: TPanel;
    Splitter1: TSplitter;
    PasSyn: TSynPasSyn;
    procedure btnDisassembleClick(Sender: TObject);
    procedure btnMemLeaksClick(Sender: TObject);
    procedure btnEvalResClick(Sender: TObject);
    procedure btnEvalArrClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
  private
    FJustText: string;
    procedure WriteHint(Sender: TLapeCompilerBase; Msg: lpString);
  public
    property justtext: string read FJustText write FJustText;
  end; 

var
  Form1: TForm1;

implementation

uses
  lpparser, lpcompiler, lputils, lpeval, lpinterpreter, lpdisassembler, {_lpgenerateevalfunctions,}
  LCLIntf, typinfo, ffi, lpffi, lpffiwrappers, ulpclasses;

{$R *.lfm}

{ TForm1 }

procedure IntTest(Params: PParamArray); {$IFDEF Lape_CDECL}cdecl;{$ENDIF}
begin
  PInt32(Params^[0])^ := PInt32(Params^[0])^ + 1;
end;

procedure MyWrite(Params: PParamArray); {$IFDEF Lape_CDECL}cdecl;{$ENDIF}
begin
  with TForm1(Params^[0]) do
    m.Text := m.Text + {$IF DEFINED(Lape_Unicode)}UTF8Encode(PlpString(Params^[1])^){$ELSE}PlpString(Params^[1])^{$IFEND};
  Write(PlpString(Params^[1])^);
end;

procedure getJustText(const Params: PParamArray; const Result: Pointer);
begin
   PLPString(Result)^ := TForm1(Params^[0]).justtext;
end;

procedure SetJustText(Params: PParamArray);
begin
  TForm1(Params^[0]).justtext:=PlpString(Params^[1])^;
end;


procedure MyWriteLn(Params: PParamArray); {$IFDEF Lape_CDECL}cdecl;{$ENDIF}
begin
  with TForm1(Params^[0]) do
    Form1.m.Append('');
  WriteLn();
end;

procedure MyStupidProc(Params: PParamArray; const Result: Pointer); {$IFDEF Lape_CDECL}cdecl;{$ENDIF}
var
  x: TIntegerArray;
begin
  SetLength(x, 5);
  TIntegerArray(Result^) := x;
end;

function StupidProc(abc: TIntegerArray): TIntegerArray; cdecl;
begin
  SetLength(Result, 5);
end;

procedure Compile(Run, Disassemble: Boolean);

  function CombineDeclArray(a, b: TLapeDeclArray): TLapeDeclArray;
  var
    i, l: Integer;
  begin
    Result := a;
    l := Length(a);
    SetLength(Result, l + Length(b));
    for i := High(b) downto 0 do
      Result[l + i] := b[i];
  end;

var
  t: UInt64;
  Parser: TLapeTokenizerBase;
  Compiler: TLapeCompiler;
begin
  Parser := nil;
  Compiler := nil;
  with Form1 do
    try
      justtext := 'text from form!';
      Parser := TLapeTokenizerString.Create({$IF DEFINED(Lape_Unicode)}UTF8Decode(e.Lines.Text){$ELSE}e.Lines.Text{$IFEND});
      Compiler := TLapeCompiler.Create(Parser);
      Compiler.OnHint := @WriteHint;

      InitializeFFI(Compiler);
      InitializePascalScriptBasics(Compiler, [psiTypeAlias]);
      ExposeGlobals(Compiler);

      Compiler.StartImporting();
      Compiler.addGlobalType('UInt32', 'DWord');

      Compiler.addGlobalType('Integer', 'TColor');
      Compiler.addGlobalType('record R, T: extended; end', 'PPoint');
      Compiler.addGlobalType('array of string', 'TStringArray');
      Compiler.addGlobalType('array of TStringArray', 'T2DStringArray');
      Compiler.addGlobalType('array of Integer', 'TIntegerArray');
      Compiler.addGlobalType('array of TIntegerArray', 'T2DIntegerArray');
      Compiler.addGlobalType('array of TIntegerArray', 'T2DIntArray');
      Compiler.addGlobalType('array of T2DIntegerArray', 'T3DIntegerArray');
      Compiler.addGlobalType('array of Cardinal', 'TCardinalArray');
      Compiler.addGlobalType('array of TCardinalArray', 'T2DCardinalArray');
      Compiler.addGlobalType('array of Char', 'TCharArray');
      Compiler.addGlobalType('array of TCharArray', 'T2DCharArray');
      Compiler.addGlobalType('array of byte', 'TByteArray');
      Compiler.addGlobalType('array of TByteArray', 'T2DByteArray');
      Compiler.addGlobalType('array of extended', 'TExtendedArray');
      Compiler.addGlobalType('array of TExtendedArray', 'T2DExtendedArray');
      Compiler.addGlobalType('array of T2DExtendedArray', 'T3DExtendedArray');
      Compiler.addGlobalType('array of boolean', 'TBoolArray');
      Compiler.addGlobalType('array of variant', 'TVariantArray');
      Compiler.addGlobalType('record X, Y: integer; end', 'TPoint');
      Compiler.addGlobalType('array of TPoint', 'TPointArray');

      Compiler.addGlobalMethod('procedure _write(s: string); override;', @MyWrite, Form1);
      Compiler.addGlobalMethod('procedure _writeln; override;', @MyWriteLn, Form1);
      Compiler.addGlobalMethod('function getText():string;',@getJustText,form1);
      Compiler.addGlobalMethod('procedure setText(s: string);', @SetJustText, Form1);
      Compiler.addGlobalFunc('function MyStupidProc: array of integer', @MyStupidProc);
      RegisterLCLClasses(Compiler);
      try
        t := getTickCount;
        if Compiler.Compile() then
          m.Append('Compiling Time: ' + IntToStr(getTickCount - t) + 'ms.')
        else
          m.Append('Error!');
      except
        on E: Exception do
        begin
          m.Append('Compilation error: "' + E.Message + '"');
          Exit;
        end;
      end;

      try
        if Disassemble then
          DisassembleCode(Compiler.Emitter.Code, CombineDeclArray(Compiler.ManagedDeclarations.getByClass(TLapeGlobalVar, bTrue), Compiler.GlobalDeclarations.getByClass(TLapeGlobalVar, bTrue)));

        if Run then
        begin
          t := GetTickCount64();
          m.Append(LineEnding);
          RunCode(Compiler.Emitter.Code, Compiler.Emitter.CodeLen);
          m.Append('Running Time: ' + IntToStr(GetTickCount64() - t) + 'ms.');
        end;
      except
        on E: Exception do
          m.Append(E.Message);
      end;
    finally
      if (Compiler <> nil) then
        Compiler.Free()
      else if (Parser <> nil) then
        Parser.Free();
      Form1.m.Lines.Add('from form1: ' + Form1.justtext);
    end;
end;

procedure TForm1.btnRunClick(Sender: TObject);
begin
  Compile(True, False);
end;

procedure TForm1.WriteHint(Sender: TLapeCompilerBase; Msg: lpString);
begin
  m.Append(Msg);
end;

procedure TForm1.btnDisassembleClick(Sender: TObject);
begin
  Compile(True, True);
end;

procedure TForm1.btnMemLeaksClick(Sender: TObject);
var
  i: Integer;
begin
  WriteLn(Ord(Low(opCode)), '..', Ord(High(opCode)));
  {$IFDEF Lape_TrackObjects}
  for i := 0 to lpgList.Count - 1 do
    WriteLn('unfreed: ', TLapeBaseClass(lpgList[i]).ClassName, ' -- [',  PtrInt(lpgList[i]), ']');
  {$ENDIF}
end;

procedure TForm1.btnEvalResClick(Sender: TObject);
begin
  e.ClearAll;
  //LapePrintEvalRes;
end;

type
  ttest = array of string;

function testHoi(a: string): ttest; cdecl;
begin
  SetLength(Result, 3);
  Result[0] := 'Hello ' + a;
end;

const
  header = 'function testHoi(a: string): array of string;';

procedure testCall;
var
  Compiler: TLapeCompiler;
  Cif: TFFICifManager;
  Arg1: string;
  Res: ttest;
begin
  Arg1 := 'hoi';
  //Res := testHoi(Arg1);
  //Dec(PPtrInt(PtrInt(Arg1) - SizeOf(Pointer))^);
  //res := 'hoi';

  Compiler := TLapeCompiler.Create(nil);
  try
    Cif := LapeHeaderToFFICif(Compiler, header);
    try
      Cif.Call(@testHoi, @res, [@arg1]);
      WriteLn('Result: ', Res[0], ' :: ', Arg1, ' :: ');
      WriteLn(Res[0], PPtrInt(PtrInt(Res) - SizeOf(Pointer)*2)^);
    finally
      Cif.Free();
    end;
  finally
    Compiler.Free();
  end;
end;

procedure TForm1.btnEvalArrClick(Sender: TObject);
begin
  //m.Clear;
  //LapePrintEvalArr;

  testCall();
end;

{$IF DEFINED(MSWINDOWS) AND DECLARED(LoadFFI)}
initialization
  if (not FFILoaded()) then
    LoadFFI(
    {$IFDEF Win32}
    'extensions\ffi\bin\win32'
    {$ELSE}
    'extensions\ffi\bin\win64'
    {$ENDIF}
    );
{$IFEND}
end.

