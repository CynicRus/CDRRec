unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Menus, ComCtrls, ExtCtrls,LCLType,ucmdfrm, usettings, usettingform, uabout, udatadumper;

type

  { TMainForm }

  TMainForm = class(TForm)
    GroupBox1: TGroupBox;
    BtnImg: TImageList;
    MainMenu1: TMainMenu;
    LogMemo: TMemo;
    AppMenuItem: TMenuItem;
    ConnectMenuItem: TMenuItem;
    ExitMenu: TMenuItem;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    SettingsMenuItem: TMenuItem;
    MenuItem3: TMenuItem;
    MenuSeparator: TMenuItem;
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    TrayIcon1: TTrayIcon;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure OpenPortButtonClick(Sender: TObject);
    procedure TaggedToolButtonClick(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
  private
    { private declarations }
  public
    procedure OnErrorClick();
    { public declarations }
  end;

var
  MainForm: TMainForm;
  IsWorking: boolean;

implementation

uses umultilang, udataworker, uversionsupport;

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
var
  i: integer;
begin
  ToolButton1.Tag := PtrUint(1);
  ToolButton1.OnClick := @OpenPortButtonClick;
  for i := 1 to ToolBar1.ButtonList.Count - 1 do
    ToolBar1.Buttons[i].OnClick := @TaggedToolButtonClick;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caNone;
  MainForm.Hide;
  MainForm.ShowInTaskBar := stNever;
  TrayIcon1.Show;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if MainForm.LogMemo.Lines.Count > 0 then
  begin
  DumpCustomData(ExtractFilePath(ParamStr(0))+'logs\log.txt',MainForm.LogMemo.Lines.Text);
    MainForm.LogMemo.Lines.Clear;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  //Lang: TLanguage;
  LangManager: TLanguageManager;
begin
  LanguageManager.ApplyLanguage(Settings.LangIndex);
 { Lang := TLanguage.Create;
  try
 Lang.LangName:='Esperanto';
 Lang.Author:='Cynic';
 Lang.AuthorsMail:= 'CynicRus@gmail.com';

 Lang.FormToLang(Self);
 Lang.FormToLang(CmdForm);
 Lang.FormToLang(CfgFrm);
    Lang.LoadFromXML('russian');
    Lang.LangToForm(Self);
    Lang.LangToForm(CmdForm);
    Lang.LangToForm(CfgFrm);
    Lang.SaveToXML('russian');

  finally
    Lang.Free
  end; }
end;

procedure TMainForm.FormWindowStateChange(Sender: TObject);
begin

end;

procedure TMainForm.OpenPortButtonClick(Sender: TObject);
begin
  case TToolButton(Sender).Tag of
    1:
    begin
      IsWorking := True;
      TToolButton(Sender).ImageIndex := 1;
      DataWorker := TDataWorker.Create(False);
      TToolButton(Sender).Tag := 2;
      ConnectMenuItem.Tag := 2;
    end;
    2:
    begin
      DataWorker.Terminate;
      IsWorking := False;
      TToolButton(Sender).ImageIndex := 0;
      TToolButton(Sender).Tag := 1;
      ConnectMenuItem.Tag := 1;
    end;
  end;
end;

procedure TMainForm.TaggedToolButtonClick(Sender: TObject);
var
  CmdString: string;
begin
  if (Sender is TToolButton) or (Sender is TMenuItem) then
  begin
    if TToolButton(Sender).Tag = 3 then
    begin
      if not IsWorking then
      begin
        ShowMessage('Before action, the connect must be opened!');
        Exit;
      end;
      if InputQuery('Send command', 'Command', False, CmdString) then
      begin
        //Manager.SendPacket(CmdString);

        exit;
      end;
    end;

    case TMenuItem(Sender).Tag of
      1:
      begin
        IsWorking := True;
        TMenuItem(Sender).ImageIndex := 1;
        DataWorker := TDataWorker.Create(False);
        TMenuItem(Sender).Tag := 2;
        ToolButton1.ImageIndex := 1;
        ToolButton1.tag := 2;
        exit;
      end;
      2:
      begin
        TMenuItem(Sender).ImageIndex := 0;
        DataWorker.Terminate;
        DataWorker.Free;
        IsWorking := False;
        TMenuItem(Sender).Tag := 1;
        ToolButton1.ImageIndex := 0;
        ToolButton1.tag := 1;
        exit;
      end;
    end;

    if IsWorking then
    begin
      ShowMessage('Before action, the connect must be closed!');
      Exit;
    end;
    case TMenuItem(Sender).Tag of
      4: EditCommands();
      5: EditSettings();
      6: ShowAbout('CynicRus@gmail.com','CynicRus',1,5,2019);
      100:
      begin
        if Application.MessageBox('Do you really want to exit? ',
          'Attention!', mb_YesNo + mb_IconExclamation) = idYes then
          Application.Terminate;

      end;
    end;

  end;

end;

procedure TMainForm.TrayIcon1Click(Sender: TObject);
begin
  TrayIcon1.Visible := False;
  MainForm.Show;
end;

procedure TMainForm.OnErrorClick();
begin
  ToolButton1.Click;
end;

//procedure TMainForm.OnThreadLog(var aMessage: TLMessage);
//var
//  Str, Tmp: string;
//begin
//  LogMemo.Lines.Clear;
//  try
//    Str := PChar(aMessage.LParam);
//    if (CompareText(Str, #13#10) = 0) then
//      exit;
//    if Config.StringCompression then
//      Str := UnpackString(DecodeStringBase64(Copy(Str, 1, Length(Str) - 2)));
//    if Config.Encryption then
//      Str := Decrypt(Copy(Str, 1, Length(Str) - 2), Config.EncryptionKey);
//    LogMemo.Lines.Add(str);

//  except
//    on E: Exception do
//      Log(ERROR, E.Message);
//  end;
//end;

end.
