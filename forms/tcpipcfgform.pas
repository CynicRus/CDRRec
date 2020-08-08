unit tcpipcfgform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, MaskEdit,
  Spin, usettings;

type

  { TTCPIPForm }

  TTCPIPForm = class(TForm)
    KeepConnectionBox: TCheckBox;
    ipAddrEdit: TEdit;
    okBtn: TButton;
    IpAddrLbl: TLabel;
    PortLbl: TLabel;
    PortEdt: TSpinEdit;
  private

  public

  end;


procedure EditTCPIpConnection(Cfg: TTCPIpConnectionSettings);
procedure EditTelnetConnection(Cfg: TTelnetConnectionSettings);
procedure EditTCPIpExport(Cfg: TTCPIPExportSettings);

var
  TCPIPForm: TTCPIPForm;

implementation

procedure EditTCPIpConnection(Cfg: TTCPIpConnectionSettings);
begin
  with TCPIPForm do
  begin
    KeepConnectionBox.Visible := False;
    ipAddrEdit.Text := Cfg.ipaddr;
    PortEdt.Value := StrToInt(Cfg.Port);


    if ShowModal = mrOk then
    begin
      Cfg.IPaddr := ipAddrEdit.Text;
      cfg.Port := IntToStr(PortEdt.Value);
    end;
    Close;
  end;
end;

procedure EditTelnetConnection(Cfg: TTelnetConnectionSettings);
begin
  with TCPIPForm do
  begin
    KeepConnectionBox.Visible := False;
    ipAddrEdit.Text := Cfg.ipaddr;
    PortEdt.Value := StrToInt(Cfg.Port);


    if ShowModal = mrOk then
    begin
      Cfg.IPaddr := ipAddrEdit.Text;
      cfg.Port := IntToStr(PortEdt.Value);
    end;
    Close;
  end;
end;

procedure EditTCPIpExport(Cfg: TTCPIPExportSettings);
begin
  with TCPIPForm do
  begin
    KeepConnectionBox.Visible := True;
    ipAddrEdit.Text := Cfg.ip;
    PortEdt.Value := StrToInt(Cfg.Port);
    KeepConnectionBox.Checked := Cfg.KeepConnection;


    if ShowModal = mrOk then
    begin
      Cfg.IP := ipAddrEdit.Text;
      cfg.Port := IntToStr(PortEdt.Value);
      Cfg.KeepConnection := KeepConnectionBox.Checked;
    end;
    Free;
  end;
end;

{$R *.lfm}

end.
