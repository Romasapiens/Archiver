unit ProgressUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.GIFImg, Vcl.ExtCtrls, ProcessUnit;

type
  TProgressForm = class(TForm)
    ProgressImage: TImage;
    DeferredExecution: TTimer;
    procedure FormShow(Sender: TObject);
    procedure DeferredExecutionTimer(Sender: TObject);
  private
    _ProcessType: integer;
    _InputFileName: string;
    _OutputFileName: string;
    _OutputDirectory: string;
    _Algorithm: integer;
    { Private declarations }
  public
    property ProcessType: integer read _ProcessType write _ProcessType;
    property InputFileName: string read _InputFileName write _InputFileName;
    property OutputFileName: string read _OutputFileName write _OutputFileName;
    property OutputDirectory: string read _OutputDirectory write _OutputDirectory;
    property Algorithm: integer read _Algorithm write _Algorithm;
    { Public declarations }
  end;

var
  ProgressForm: TProgressForm;

implementation

{$R *.dfm}

procedure TProgressForm.FormShow(Sender: TObject);
begin
  (ProgressImage.Picture.Graphic as TGIFImage).Animate := True;
  DeferredExecution.Interval := 500;
  DeferredExecution.Enabled := true;
end;

procedure TProgressForm.DeferredExecutionTimer(Sender: TObject);
begin
  DeferredExecution.Enabled := False;
  try
    if ProcessType = 0 then Archive(InputFileName, OutputFileName, Algorithm)
    else Unarchive(InputFileName, OutputDirectory);
  finally
    self.Close();
  end;
end;
end.
