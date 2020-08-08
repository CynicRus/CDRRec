unit lpTObject;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, lpcompiler, lptypes, ulpClassHelper;

procedure Register_TObject(Compiler: TLapeCompiler);

implementation

type
  PObject = ^TObject;

procedure TObject_Init(const Params: PParamArray);
begin
  PObject(Params^[0])^ := TObject.Create();
end;

procedure TObject_Free(const Params: PParamArray);
begin
  PObject(Params^[0])^.Free();
end;

procedure TObject_ToString(const Params: PParamArray; const Result: Pointer);
begin
  PlpString(Result)^ := PObject(Params^[0])^.ToString();
end;

procedure Register_TObject(Compiler: TLapeCompiler);
begin
  with Compiler do
  begin
    addClass('TObject', 'Pointer');

    addGlobalFunc('procedure TObject.Init();', @TObject_Init);
    addGlobalFunc('procedure TObject.Free(); constref;', @TObject_Free);
    addGlobalFunc('function TObject.ToString(): string; constref;', @TObject_ToString);
  end;
end;

end.

