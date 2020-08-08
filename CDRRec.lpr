program CDRRec;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, umain, udataworker, uconnector, ulpclasshelper, ulpclasses, lpxml,
  uxml, ulptypes, udataexporter, udatadumper, usettingform, usettings, ucmdfrm,
  tcpipcfgform, urlipccfgform, serialcfgform, ucommandlist, uabout,
  uversionsupport, uplugins;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TCmdForm, CmdForm);
  Application.CreateForm(TSettingsFrm, SettingsFrm);
  Application.CreateForm(TComSetupFrm,ComSetupFrm);
  Application.CreateForm(TTCPIPForm, TCPIPForm);
  Application.CreateForm(TRulIpcForm, RulIpcForm);
  Application.Run;
end.

