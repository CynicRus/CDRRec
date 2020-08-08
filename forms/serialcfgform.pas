(******************************************************
 * lazSerialSetup                                     *
 *                                                    *
 * written by Jurassic Pork  O3/2013                  *
 * based on TComport TcomSetupFrm                     *
 *****************************************************)

unit serialcfgform;

{$mode objfpc}{$H+}



interface

uses
  LCLIntf, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Buttons, LResources, synaser, usettings;

type


  { TComSetupFrm }

  TComSetupFrm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    ComComboBox1: TComboBox;
    ComComboBox2: TComboBox;
    ComComboBox3: TComboBox;
    ComComboBox4: TComboBox;
    ComComboBox5: TComboBox;
    ComComboBox6: TComboBox;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

procedure EditComPort(ComPort: TRS232ConnectionSettings);
var
  ComSetupFrm: TComSetupFrm;
implementation




procedure EditComPort(ComPort: TRS232ConnectionSettings);
begin
  with ComSetupFrm do
  begin
    ComComboBox1.Text := ComPort.ComPort;
    ComComboBox2.Text := BaudRateToStr(ComPort.BaudRate);
    ComComboBox3.Text := DataBitsToStr(ComPort.DataBits);
    ComComBoBox4.Text := StopBitsToStr(ComPort.StopBits);
    ComComBoBox5.Text := ParityToStr(ComPort.Parity);
    ComComBoBox6.Text := FlowControlToStr(ComPort.FlowControl);

    if ShowModal = mrOk then
    begin
      ComPort.ComPort := ComComboBox1.Text;
      ComPort.BaudRate := StrToBaudRate(ComComboBox2.Text);
      ComPort.DataBits := StrToDataBits(ComComboBox3.Text);
      ComPort.StopBits := StrToStopBits(ComComboBox4.Text);
      ComPort.Parity := StrToParity(ComComboBox5.Text);
      ComPort.FlowControl := StrToFlowControl(ComComboBox6.Text);
    end;
    Close;
  end;
end;

procedure StringArrayToList(AList: TStrings; const AStrings: array of string);
var
  Cpt: integer;
begin
  for Cpt := Low(AStrings) to High(AStrings) do
    AList.Add(AStrings[Cpt]);
end;

{ TComSetupFrm }


procedure TComSetupFrm.FormCreate(Sender: TObject);
begin
  ComComboBox1.Items.CommaText := GetSerialPortNames();
  ComComboBox1.ItemIndex:=0;
  StringArrayToList(ComComboBox2.Items, BaudRateStrings);
  StringArrayToList(ComComboBox3.Items, DataBitsStrings);
  StringArrayToList(ComComboBox4.Items, StopBitsStrings);
  StringArrayToList(ComComboBox5.Items, ParityBitsStrings);
  StringArrayToList(ComComboBox6.Items, FlowControlStrings);
end;

procedure TComSetupFrm.Button1Click(Sender: TObject);
begin

end;


initialization
  {$i serialcfgform.lrs}
end.
