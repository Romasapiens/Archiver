program Archiver;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  ArchiveUnit in 'ArchiveUnit.pas' {ArchiveForm},
  ProcessUnit in 'ProcessUnit.pas',
  ProgressUnit in 'ProgressUnit.pas' {ProgressForm},
  Huffman in 'Huffman.pas',
  LZ77 in 'LZ77.pas',
  LZW in 'LZW.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
