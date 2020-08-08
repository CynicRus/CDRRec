unit urlipccfgform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, usettings;

type

  { TRulIpcForm }

  TRulIpcForm = class(TForm)
    okBtn: TButton;
    textEdt: TEdit;
    textLbl: TLabel;
  private

  public

  end;


procedure EditHttpExport(Cfg: THttpExportSettings);
procedure EditIpcExport(Cfg: TIpcExportSettings);

var
  RulIpcForm: TRulIpcForm;

implementation

procedure EditHttpExport(Cfg: THttpExportSettings);
begin
  with RulIpcForm do
  begin
    textEdt.Text := cfg.URL;

    if ShowModal = mrOk then
    begin
      Cfg.URL := textEdt.Text;
    end;
    Close;
  end;
end;

procedure EditIpcExport(Cfg: TIpcExportSettings);
begin
  with RulIpcForm do
  begin
    textEdt.Text := cfg.IPCname;

    if ShowModal = mrOk then
    begin
      Cfg.IPCname := textEdt.Text;
    end;
    Free;
  end;
end;

{$R *.lfm}

end.
