unit cfgeditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Spin, uconfig;

type

  { TCfgFrm }

  TCfgFrm = class(TForm)
    CfgCancel: TButton;
    CfgOk: TButton;
    LangBox: TComboBox;
    CompressionBox: TCheckBox;
    langlbl: TLabel;
    lpathed: TEdit;
    EncryptBox: TCheckBox;
    dpathed: TEdit;
    GroupBox1: TGroupBox;
    hosted: TEdit;
    ported: TEdit;
    ConnBox: TGroupBox;
    Hostlbl: TLabel;
    dpathlbl: TLabel;
    EncryptKeyLbl: TLabel;
    logplbl: TLabel;
    portlbl: TLabel;
    EncKeyEd: TSpinEdit;
    DirDlg: TSelectDirectoryDialog;
    procedure FormShow(Sender: TObject);
    procedure SelectDlgClick(Sender: TObject);
    procedure ApplyCfg(Sender: TObject);
    procedure CancelClk(Sender: TObject);
    procedure ChangeLanguage(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  CfgFrm: TCfgFrm;

implementation
   uses umultilang;
{$R *.lfm}

{ TCfgFrm }

procedure TCfgFrm.FormShow(Sender: TObject);
begin
  hosted.Text:=Config.Server;
  ported.Text:=Config.Port;
  dpathed.Text:=Config.DataPath;
  lpathed.Text:=Config.LogPath;
  EncryptBox.Checked:=Config.Encryption;
  if (Config.EncryptionKey > EncKeyEd.MaxValue) then
    Config.EncryptionKey:=EncKeyEd.MaxValue else
  if (Config.EncryptionKey < EncKeyEd.MinValue) then
    Config.EncryptionKey:=EncKeyEd.MinValue;
  EncKeyEd.Value:=Config.EncryptionKey;
  CompressionBox.Checked:= Config.StringCompression;
  dpathed.OnClick:=@SelectDlgClick;
  lpathed.OnClick:=@SelectDlgClick;
  LanguageManager.FillComboBox(LangBox);
  CfgOk.OnClick:=@ApplyCfg;
  CfgCancel.OnClick:=@CancelClk;
  LangBox.ItemIndex:=Config.CurrentLangIndex;
  LangBox.OnChange:=@ChangeLanguage;
end;

procedure TCfgFrm.SelectDlgClick(Sender: TObject);
begin
  case TEdit(Sender).Tag of
   0:
   begin
     if  DirDlg.Execute then
       begin
         dPathEd.Text := DirDlg.FileName;
         Config.DataPath:=DirDlg.FileName;
       end;
   end;
   1:
   begin
     if  DirDlg.Execute then
       begin
         lPathEd.Text := DirDlg.FileName;
         Config.LogPath:=DirDlg.FileName;
       end;
   end;
  end;
end;

procedure TCfgFrm.ApplyCfg(Sender: TObject);
begin
  Config.Server:=hosted.Text;
  Config.Port:=ported.Text;
  Config.DataPath:=dpathed.Text;
  Config.LogPath:=lpathed.Text;
  Config.Encryption:=EncryptBox.Checked;
  if (Config.EncryptionKey > EncKeyEd.MaxValue) then
    Config.EncryptionKey:=EncKeyEd.MaxValue else
  if (Config.EncryptionKey < EncKeyEd.MinValue) then
    Config.EncryptionKey:=EncKeyEd.MinValue;

  Config.EncryptionKey:=EncKeyEd.Value;
  Config.StringCompression:=CompressionBox.Checked;
  Config.CurrentLangIndex:=LangBox.ItemIndex;
  Config.Save;
  Close;
end;

procedure TCfgFrm.CancelClk(Sender: TObject);
begin
  Close;
end;

procedure TCfgFrm.ChangeLanguage(Sender: TObject);
begin
  Config.CurrentLangIndex:= LangBox.ItemIndex;
  LanguageManager.ApplyLanguage(Config.CurrentLangIndex);
end;

end.

