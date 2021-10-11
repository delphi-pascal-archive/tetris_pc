program Tetris;

uses
  Forms,
  Tetris_Unit in 'Tetris_Unit.pas' {MainForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
