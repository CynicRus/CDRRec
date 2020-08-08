unit usettingform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  ExtCtrls, Spin, usettings, serialcfgform, tcpipcfgform, urlipccfgform, umultilang;

type

  { TSettingsFrm }

  TSettingsFrm = class(TForm)
    cnclBtn: TButton;
    idRecorderLbl: TLabel;
    ScriptEdt: TEdit;
    okBtn: TButton;
    InbuiltDumper: TCheckBox;
    OpenDialog1: TOpenDialog;
    OverallGBox: TGroupBox;
    LanguageBox: TComboBox;
    LanguageGroupBox: TGroupBox;
    SetScriptBtn: TButton;
    ExportSettingsBtn: TButton;
    ExportTypeBox: TComboBox;
    ConnSettingsBtn: TButton;
    ConnectionTypeBox: TComboBox;
    ConnectionGBox: TGroupBox;
    ConnectionTypeLbl: TLabel;
    ExportTypeGBox: TGroupBox;
    ExportTypeLbl: TLabel;
    ScriptBoxLbl: TLabel;
    ScriptSettingsBox: TGroupBox;
    idRecorderValue: TSpinEdit;
    procedure ConnectionTypeBoxChange(Sender: TObject);
    procedure ConnSettingsBtnClick(Sender: TObject);
    procedure ExportSettingsBtnClick(Sender: TObject);
    procedure ExportTypeBoxChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LanguageBoxChange(Sender: TObject);
    procedure SetScriptBtnClick(Sender: TObject);
  private

  public

  end;


procedure EditSettings();
var
SettingsFrm: TSettingsFrm;
implementation

{$R *.lfm}

procedure EditSettings();
var
  i: integer;

begin
  with SettingsFrm do
  begin
    ConnectionTypeBox.ItemIndex := Settings.ConnectionType;
    ExportTypeBox.ItemIndex := Settings.ExportType;
    InbuiltDumper.Checked := Settings.UseInbuiltDataDump;
    ScriptEdt.Text := Settings.DataProcessingScript;
    for i := 0 to ComponentCount - 1 do
      if Components[i] is TComboBox then
        TComboBox(Components[i]).ReadOnly := True;
    LanguageManager.FillComboBox(LanguageBox);
    LanguageBox.ItemIndex := Settings.LangIndex;
    idRecorderValue.Value:=Settings.Id;
    //Show;
    if ShowModal = mrOk then
    begin
      Settings.ConnectionType := ConnectionTypeBox.ItemIndex;
      Settings.ExportType := ExportTypeBox.ItemIndex;
      Settings.LangIndex := LanguageBox.ItemIndex;
      Settings.UseInbuiltDataDump := InbuiltDumper.Checked;
      Settings.DataProcessingScript:=ScriptEdt.Text;
      Settings.Id:=idRecorderValue.Value;
      Settings.Save;
      //Free();
    end;
    Close();
  end;

end;



{ TSettingsFrm }

procedure TSettingsFrm.ConnSettingsBtnClick(Sender: TObject);
begin
  case Settings.ConnectionType of
    0: EditTCPIpConnection(TTCPIpConnectionSettings(Settings.ConnectionSettings));
    1: EditComPort(TRS232ConnectionSettings(Settings.ConnectionSettings));
    2: EditTelnetConnection(TTelnetConnectionSettings(Settings.ConnectionSettings));
  end;

end;

procedure TSettingsFrm.ExportSettingsBtnClick(Sender: TObject);
begin
  case Settings.ExportType of
    0: EditTCPIpExport(TTCPIPExportSettings(Settings.ExportSettings));
    1: EditHttpExport(THTTPExportSettings(Settings.ExportSettings));
    2: EditIPCExport(TIPCExportSettings(Settings.ExportSettings));
  end;
end;

procedure TSettingsFrm.ExportTypeBoxChange(Sender: TObject);
var
  s: string;
begin
  Settings.ExportType := ExportTypeBox.ItemIndex;
  case Settings.ExportType of
    0: s := '{"ip":"127.0.0.1","port":"5050","keep_connection":false}';
    1: s:= '{"url":""}';
    2: s := '{"ipcname":''}';
  end;
  Settings.ChangeExportSettings(s);
end;

procedure TSettingsFrm.FormCreate(Sender: TObject);
begin

end;

procedure TSettingsFrm.FormShow(Sender: TObject);
begin

end;

procedure TSettingsFrm.LanguageBoxChange(Sender: TObject);
begin
  Settings.LangIndex := LanguageBox.ItemIndex;
  LanguageManager.ApplyLanguage(Settings.LangIndex);
  LanguageManager.FillComboBox(LanguageBox);
  LanguageBox.ItemIndex:=Settings.LangIndex;
end;

procedure TSettingsFrm.SetScriptBtnClick(Sender: TObject);
begin
 if OpenDialog1.Execute then
  ScriptEdt.Text := OpenDialog1.FileName;
end;


procedure TSettingsFrm.ConnectionTypeBoxChange(Sender: TObject);
var
  s: string;
begin
  Settings.ConnectionType := ConnectionTypeBox.ItemIndex;
  case Settings.ConnectionType of
  0,2: s := '{"ip":"127.0.0.1","port":"5050"}';
  1: s := '{}';
  end;
  Settings.ChangeConnectionSettings(s);
  //Settings.
end;


end.
