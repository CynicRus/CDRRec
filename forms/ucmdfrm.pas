unit ucmdfrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, ucommandlist;

type

  { TCmdForm }

  TCmdForm = class(TForm)
    AfterConnectingBox: TGroupBox;
    BeforeDisconnectBox: TGroupBox;
    AfterConnectionMemo: TMemo;
    BeforeDisconnectionMemo: TMemo;
    Ok: TButton;
    CancelBtn: TButton;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  CmdForm: TCmdForm;

procedure EditCommands();

implementation

procedure EditCommands();
begin
  with CmdForm do
  begin
   CommandList.Load;
   AfterConnectionMemo.Lines.Clear;
   BeforeDisconnectionMemo.Lines.Clear;
   AfterConnectionMemo.Lines.AddStrings(CommandList.AfterConnectCommands);
   BeforeDisconnectionMemo.Lines.AddStrings(CommandList.BeforeDisconnectCommands);
   if ShowModal = mrOk then
    begin
      CommandList.AfterConnectCommands.AddStrings(AfterConnectionMemo.Lines);
      CommandList.BeforeDisconnectCommands.AddStrings(BeforeDisconnectionMemo.Lines);
      CommandList.Save;
    end;
   Close();
  end;
end;


{$R *.lfm}


{ TCmdForm }


end.
