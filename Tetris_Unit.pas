{*******************************************************************************
Projet :      Tetris
Description : Application basée sur le grand classique Tetris.
Auteur :      Link Aran
Version :     1.0, version de base, 11.07.06
*******************************************************************************}
unit Tetris_Unit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Menus, ExtCtrls, jpeg, MPlayer;

type
  TMainForm = class(TForm)
    ImageJeu: TImage;
    MainMenu: TMainMenu;
    Jeu: TMenuItem;
    GBInformations: TGroupBox;
    ImageIndice: TImage;
    LbIndication1: TLabel;
    LbNiveau: TLabel;
    LbLignes: TLabel;
    LbIndication2: TLabel;
    LbPoints: TLabel;
    Nouvelle_Partie: TMenuItem;
    Affichage: TMenuItem;
    Indice: TMenuItem;
    TimerAnimations: TTimer;
    TimerJeu: TTimer;
    MediaPlayerJeu: TMediaPlayer;
    procedure FormCreate(Sender: TObject);
    procedure NewGame;
    procedure DrawIndice(Indice:Word);
    procedure WriteOnScreen(Composant:TImage;Position:TPoint;
      Couleur:TColor;Epaisseur:byte;Texte:string);
    function VerifPart(Piece:Word;Orientation:Word;Position:TPoint):Word;
    procedure TimerAnimationsTimer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Nouvelle_PartieClick(Sender: TObject);
    procedure TimerJeuTimer(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure IndiceClick(Sender: TObject);
    procedure ImageJeuMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var //déclaration des variables globales
  MainForm : TMainForm;
  GPieceUse, //définit la pièce qui doit être affichée
  GPieceIndice : Word; //définit la pièce qui sera utilisée au prochain coup
  GLignes, GNiveau, GScore : integer; //pour la gestion des scores
  GPiecePosition : TPoint; //définit la position de la pièce en cours
  GAnimation, //pour gérer l'animation d'un début de partie
  GOrientationPiece,  //pour l'orientation des pièces
  GCaseOccupees, //pour savoir combien de cases sont occupées dans le tableau
  GNbLignes, //pour la destion des lignes accomplies
  GClignote, //variable pour faire clignoter des pièces
  GKey : word; //contient la dernière touche tapée
  GDiversBool1, GDiversBool2, //variables boolean pour diverses utilisations
  GEnd, //définit si la partie est perdue
  GStopMouv : boolean; //définit si la pièce s'est posée ou pas
  GBackGround : string; //définit l'image qui va être affichée en fond d'écran

  //déclaration des tableaux
  GLigne : array[1..4] of Integer; //contient les lignes complètées
  GTemp : array of TPoint; //pour gérer le jeu après disparition d'une ligne
  GTempColor : array of TColor; //complète GReste pour gérer les couleurs

  GJeuColor : array[1..108] of TColor; //contient les couleurs des cases prises
  GJeu : array[1..108] of TPoint; //contient les cases occupées du jeu
  GPiece : array[1..4] of TPoint; //contient les cases occupées par la pièce
                                  //en cours

const //déclaration des constantes
  CouleurDef = clBlack; //définit la couleur par défault
  BgJeu = 'Images\Tetris_BG00.bmp'; //pour l'image de fond au début
  BgIndice = 'Images\Tetris_Indice00.bmp'; //pour l'image de fond de l'indice

implementation

{$R *.DFM}

//Initialisations des éléments globaux
procedure TMainForm.FormCreate(Sender: TObject);
begin
  //Initialisation du random
  Randomize;

  //Initialisation des varaibles globales
  GKey := 0;

  //Lancement de la procédure d'initialisation d'une partie
  NewGame;
end;

//Timer qui gère le déplacement des pièces
procedure TMainForm.TimerJeuTimer(Sender: TObject);
var //déclaration des variables
  i, j : integer; //pour l'itération des boucles for
  GestionPiece, //pour savoir si la pièce peut être affichée
  CarresParLigne, //pour gérer si il y a une ligne
  IncChute : Word; //gestion de la vitesse de chute au sein du même niveau
  Pos : TPoint; //pour utiliser la procédure WriteOnScreen
  ErreurCorrige : boolean; //pour la correction gauche/droite
begin
  //Initialisation des variables
  IncChute := 10;
  ErreurCorrige := False;

  //Mise à jour du niveau
  if Trunc(GLignes / 10) > GNiveau
    then
      GNiveau := GNiveau + Trunc(GLignes / 10);
  case GNiveau of
    0..9 : TimerJeu.Interval := 500 - 50 * GNiveau;
    10..20 :TimerJeu.Interval := 100 - 5 * (GNiveau - 9);
  else
    GNiveau := 20;
  end;
  LbNiveau.Caption := 'Level : ' + IntToStr(GNiveau);

  //gestion d'une pièce qui tombe
  if GStopMouv = False
    then
      begin
        //effacement de la pièce dans l'ancienne position
        ImageJeu.Canvas.Pen.Color := clWhite;
        ImageJeu.Canvas.Brush.Color := clWhite;
        for i := 1 to 4 do
          ImageJeu.Canvas.Rectangle(GPiece[i].x,GPiece[i].y,
            GPiece[i].x + 30,GPiece[i].y + 30);

        //récupération des éléments saisis par l'utilisateur
        case GKey of
          VK_RIGHT :
            begin
              GPiecePosition.x := GPiecePosition.x + 30;
              for i := 1 to 4 do
                for j := 1 to GCaseOccupees do
                  if ((GPiece[i].x + 30 = GJeu[j].x) and
                    ((GPiece[i].y = GJeu[j].y) or
                    (GPiece[i].y + 30 = GJeu[j].y) or
                    (GPiece[i].y + 30 = GJeu[j].y + 10) or
                    (GPiece[i].y + 30 = GJeu[j].y + 20))) and
                    (ErreurCorrige = False)
                    then
                      begin
                        GPiecePosition.x := GPiecePosition.x - 30;
                        ErreurCorrige := True;
                      end;
              GKey := 0;
            end;
          VK_LEFT :
            begin
              GPiecePosition.x := GPiecePosition.x - 30;
              for i := 1 to 4 do
                for j := 1 to GCaseOccupees do
                  if ((GPiece[i].x - 30 = GJeu[j].x) and
                    ((GPiece[i].y = GJeu[j].y) or
                    (GPiece[i].y  + 30 = GJeu[j].y) or
                    (GPiece[i].y + 30 = GJeu[j].y + 10) or
                    (GPiece[i].y + 30 = GJeu[j].y + 20))) and
                    (ErreurCorrige = False)
                    then
                      if GJeuColor[j] <> 0
                        then
                          begin
                            GPiecePosition.x := GPiecePosition.x + 30;
                            ErreurCorrige := True;
                          end;
              GKey := 0;
            end;
          VK_UP :
            begin
              if GOrientationPiece >= 4
                then
                  GOrientationPiece := 1
                else
                  inc(GOrientationPiece);
              GKey := 0;
            end;
          32 : //barre d'espace (même effet que VK_UP)
            begin
              if GOrientationPiece >= 4
                then
                  GOrientationPiece := 1
                else
                  inc(GOrientationPiece);
              GKey := 0;
            end;
          VK_DOWN :
            begin
              TimerJeu.Interval := 1;
              inc(GScore);
              LbPoints.Caption := IntToStr(GScore);
            end;
        end;

        //vérification que la pièce peut être posée avec les paramètres saisis
        repeat
          GestionPiece := VerifPart(GPieceUse,GOrientationPiece,GPiecePosition);
          case GestionPiece of
            1 : GPiecePosition.x := GPiecePosition.x - 30; //trop à droite
            2 : GPiecePosition.x := GPiecePosition.x + 30; //trop à gauche
            3 : //stoppée
              begin
                GPiecePosition.y := GPiecePosition.y - IncChute;
                GStopMouv := True;
              end;
            4 : GStopMouv := True; //stoppée par une autre pièce
            5 : GPiecePosition.x := GPiecePosition.x - 30; //trop à droite
            6 : GPiecePosition.x := GPiecePosition.x + 30; //trop à gauche
          end;
        until (GestionPiece = 0) or (GestionPiece = 4);

        //réaffichage de la pièce, dans la nouvelle position
        case GPieceUse of
          1 : ImageJeu.Canvas.Pen.Color := clMaroon;
          2 : ImageJeu.Canvas.Pen.Color := clNavy;
          3 : ImageJeu.Canvas.Pen.Color := clPurple;
          4 : ImageJeu.Canvas.Pen.Color := clTeal;
          5 : ImageJeu.Canvas.Pen.Color := clGray;
          6 : ImageJeu.Canvas.Pen.Color := clBlue;
          7 : ImageJeu.Canvas.Pen.Color := clRed;
        end;
        ImageJeu.Canvas.Brush.Color := ImageJeu.Canvas.Pen.Color;
        for i := 1 to 4 do
          ImageJeu.Canvas.Rectangle(GPiece[i].x,GPiece[i].y,
            GPiece[i].x + 30,GPiece[i].y + 30);

        //incrémentation de la position Y de la pièce si celle-ci continue
        if GStopMouv = False
          then
            GPiecePosition.y := GPiecePosition.y + IncChute;
      end
    else
      begin
        //vérification que la partie n'est pas perdue
        for i := 1 to 4 do
          if GPiece[i].y < -30
            then
              GEnd := True;

        //réinitialisation de la position d'une pièce
        GPiecePosition.x := 120;
        GPiecePosition.y := 0;

        //préparation des prochaines pièces
        GPieceUse := GPieceIndice;
        GPieceIndice := random(7) + 1;

        //affichage de l'indice
        if Indice.Checked
          then
            DrawIndice(GPieceIndice);

        //Mise à jour des tableaux
        for i := 1 to 4 do
          begin
            GPiece[i].x := 0;
            GPiece[i].y := - 30;
          end;
        for i := 1 to 108 do
          begin
            GJeu[i].x := 0;
            GJeu[i].y := 0;
            GJeuColor[i] := 0;
          end;
        GCaseOccupees := 1;
        for i := 1 to 12 do
          for j := 1 to 9 do
            if ImageJeu.Canvas.Pixels[(j - 1) * 30,(i - 1) * 30] <> clWhite
              then
                begin
                  GJeu[GCaseOccupees].x := (j - 1) * 30;
                  GJeu[GCaseOccupees].y := (i - 1) * 30;
                  GJeuColor[GCaseOccupees] :=
                    ImageJeu.Canvas.Pixels[(j - 1) * 30,(i - 1) * 30];
                  inc(GCaseOccupees);
                end;

        //Relancement de la gestion de la chute
        GOrientationPiece := 1;
        GStopMouv := False;

        //recherche d'éventuelles lignes
        for i := 1 to 12 do
          begin
            CarresParLigne := 0;
            for j := 1 to 9 do
              if ImageJeu.Canvas.Pixels[(j - 1) * 30,(i - 1) * 30] <> clWhite
                then
                  begin
                    Inc(CarresParLigne);
                    if CarresParLigne = 9
                      then
                        begin
                          GLigne[GNbLignes] := (i - 1) * 30;
                          Inc(GNbLignes);
                        end;
                  end;
          end;

        //lancement de la gestion des lignes si il y en a
        if GNbLignes > 1
          then
            begin
              GAnimation := 2; //lancement de l'animation (gestion des lignes)
              TimerAnimations.Enabled := True;
              TimerJeu.Enabled := False;
            end;
      end;

  //arrêt de la partie si le sommet a été atteint
  if GEnd
    then
      begin
        ImageJeu.Canvas.Pen.Color := clBlack;
        ImageJeu.Canvas.Brush.Color := clBlack;
        ImageJeu.Canvas.Rectangle(0,0,270,360);
        ImageIndice.Picture.LoadFromFile('Images\Tetris_Indice00.bmp');
        Pos.x := 15;
        Pos.y := 20;
        WriteOnScreen(ImageJeu,Pos,clWhite,2, 'Enter to continue ...');
        TimerJeu.Enabled := False;
      end;
end;

//Timer pour l'ensemble des animations
procedure TMainForm.TimerAnimationsTimer(Sender: TObject);
var //déclaration des variables
  PositionTexte : TPoint; //pour la position du texte dans le composant image
  i, j : integer; //pour l'incrémentation des boucles for
begin
  case GAnimation of
    1 :
      begin
        TimerAnimations.Interval := 100;
        PositionTexte.x := 130;
        PositionTexte.y := 130;
        if ImageJeu.Canvas.Pixels[130,150] = CouleurDef
          then
            WriteOnScreen(ImageJeu,PositionTexte,clWhite,2,'_')
          else
            WriteOnScreen(ImageJeu,PositionTexte,CouleurDef,2,'_');
        if GKey in[48..57]
          then
            begin
              ImageJeu.Canvas.Pen.Color := clWhite;
              ImageJeu.Canvas.Brush.Color := clWhite;
              ImageJeu.Canvas.Rectangle(PositionTexte.x,PositionTexte.y,
                PositionTexte.x + 11, PositionTexte.y + 20);
              WriteOnScreen(ImageJeu,PositionTexte,CouleurDef,1,
                IntToStr(GKey - 48));
              GNiveau := GKey - 48;
              PositionTexte.x := 15;
              PositionTexte.y := 320;
              WriteOnScreen(ImageJeu,PositionTexte,CouleurDef,2,'Enter to continue ...')
            end;
        if GKey = 13 //13 -> <enter>
          then
            begin //fin de l'animation
              ImageJeu.Canvas.Brush.Color := clWhite;
              ImageJeu.Canvas.Brush.Style := bsSolid;
              ImageJeu.Canvas.Pen.Color := clWhite;
              ImageJeu.Canvas.Pen.Style := psClear;
              ImageJeu.Canvas.Rectangle(0,0,270,360);
              GAnimation := 0;
              TimerAnimations.Enabled := False;
              TimerJeu.Enabled := True;
              LbNiveau.Caption := 'Level : ' + IntToStr(GNiveau);

              //affichage de l'indice
              DrawIndice(GPieceIndice);
            end;
      end;
    2 :
      begin
        //initialisation
        TimerAnimations.Interval := 250;

        //clignotement des lignes accomplies
        if GClignote < 6
          then
            if GDiversBool1 = False
              then //initialisation des tableaux pour les lignes
                begin
                  SetLength(GTemp,(GNbLignes - 1) * 9);
                  SetLength(GTempColor,(GNbLignes - 1) * 9);
                  for i := 1 to 4 do
                    if i < GNbLignes
                      then
                        case i of
                          1 :
                            for j := 0 to 8 do
                              begin
                                GTemp[j].x := j * 30;
                                GTemp[j].y := GLigne[i];
                              end;
                          2 :
                            for j := 9 to 17 do
                              begin
                                GTemp[j].x := (j - 9) * 30;
                                GTemp[j].y := GLigne[i];
                              end;
                          3 :
                            for j := 18 to 26 do
                              begin
                                GTemp[j].x := (j -18) * 30;
                                GTemp[j].y := GLigne[i];
                              end;
                          4 :
                            for j := 27 to 35 do
                              begin
                                GTemp[j].x := (j -27) * 30;
                                GTemp[j].y := GLigne[i];
                              end;
                        end;
                  for i := 0 to High(GTemp) do
                    GTempColor[i] := ImageJeu.Canvas.Pixels[GTemp[i].x,
                      GTemp[i].y];
                  GDiversBool1 := True; //pour pouvoir lancer le clignotement
                end
              else //lancement du clignotement (basé à deux fois)
                begin
                  if GClignote mod 2 = 1
                    then
                      begin
                        ImageJeu.Canvas.Brush.Color := clWhite;
                        ImageJeu.Canvas.Pen.Color := clWhite;
                        for i := 0 to High(GTemp) do
                          ImageJeu.Canvas.Rectangle(GTemp[i].x,GTemp[i].y,
                            GTemp[i].x + 30,GTemp[i].y + 30);
                        Inc(GClignote);
                      end
                    else
                      begin
                        for i := 0 to High(GTemp) do
                          begin
                            ImageJeu.Canvas.Brush.Color := GTempColor[i];
                            ImageJeu.Canvas.Pen.Color := GTempColor[i];
                            ImageJeu.Canvas.Rectangle(GTemp[i].x,GTemp[i].y,
                              GTemp[i].x + 30,GTemp[i].y + 30);
                          end;
                        Inc(GClignote);
                      end;
                end
          else //chute du reste de la construction et incrémentation du score
            begin
              //Mise à jour des tableaux
              for i := 0 to GNbLignes - 1 do
                for j := 1 to 108 do
                  if GJeu[j].y = GLigne[i]
                    then
                      begin
                        GJeu[j].y := 0;
                        GJeu[j].x := 0;
                        GJeuColor[j] := 0;
                      end
                    else
                      if (GJeu[j].y < GLigne[i]) and (GJeu[j].y <> 0)
                        then
                          GJeu[j].y := GJeu[j].y + 30;

              //effacement du composant ImageJeu
              ImageJeu.Canvas.Pen.Color := clWhite;
              ImageJeu.Canvas.Brush.Color := clWhite;
              ImageJeu.Canvas.Rectangle(0,0,270,360);

              //réaffichage du reste
              for i := 1 to 108 do
                if GJeu[i].y <> 0
                  then
                    begin
                      ImageJeu.Canvas.Pen.Color := GJeuColor[i];
                      ImageJeu.Canvas.Brush.Color := GJeuColor[i];
                      ImageJeu.Canvas.Rectangle(GJeu[i].x,GJeu[i].y,
                        GJeu[i].x + 30,GJeu[i].y + 30);
                    end;

              //Mise à jour du score
              GLignes := GLignes + GNbLignes - 1;
              GScore := GScore + 50 * (GNbLignes - 1);
              if GNbLignes = 5
                then
                   GScore := GScore + 1000 * (GNiveau + 1);
              LbLignes.Caption := 'Lines : ' + IntToStr(GLignes);
              LbPoints.Caption := IntToStr(GScore);

              //relancement du jeu
              for i := 1 to 4 do
                GLigne[i] := 0;
              GNbLignes := 1;
              GAnimation := 0;
              GDiversBool1 := False;
              GDiversBool2 := False;
              GClignote := 1;
              TimerJeu.Enabled := True;
              TimerAnimations.Enabled := False;
            end;
      end;
  end;
end;

//Lancement d'une nouvelle parite
procedure TMainForm.Nouvelle_PartieClick(Sender: TObject);
begin
  NewGame;
end;

//Gestion de la demande d'afficher/masquer l'indice
procedure TMainForm.IndiceClick(Sender: TObject);
var //déclaration des variables
  Pos : TPoint; //pour utiliser la procédure WriteOnScreen
begin
  //initialisation des variables
  Pos.x := 5;
  Pos.y := 25;

  //gestion du composant ImageIndice selon l'état choisi par l'utilisateur
  if Indice.Checked
    then
      begin
        ImageIndice.Picture.LoadFromFile('Images\Tetris_Indice00.bmp');
        Indice.Checked := False;
        WriteOnScreen(ImageIndice,Pos,CouleurDef,3,'Crtl+I');
      end
    else
      begin
        ImageIndice.Canvas.Rectangle(0,0,80,80);
        Indice.Checked := True;
        DrawIndice(GPieceIndice);
      end;
end;

//Met à jour l'état du clavier pour les autres procédures
procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //initialisation d'une variable accessible par chaque formule
  GKey := Key;
end;

//Gère l'interraction de la touche flèche-bas
procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //annule l'effet de la touche flèche-bas (VK_DOWN)
  if Key = VK_DOWN
    then
      GKey := 0;
end;

//Petite animation de fin de partie
procedure TMainForm.ImageJeuMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  pos : Tpoint; //pour utiliser la procédure WriteOnScreen
begin
  if GEnd //ne s'utilise seulement si la partie est finie
    then
      begin
        ImageJeu.Canvas.Pen.Color := clBlack;
        ImageJeu.Canvas.Brush.Color := clBlack;
        ImageJeu.Canvas.Rectangle(0,0,270,360);
        Pos.x := 15;
        Pos.y := 20;
        WriteOnScreen(ImageJeu,Pos,clWhite,2,
          'Enter to continue ...');
        Pos.x := X - 110;
        Pos.y := Y - 20;
        WriteOnScreen(ImageJeu,Pos,clWhite,3,'Game Over');
        Pos.x := 10;
        Pos.y := 300;
        WriteOnScreen(ImageJeu,Pos,clWhite,1,IntToStr(GLignes) + ' lines');
        Pos.x := 10;
        Pos.y := 330;
        WriteOnScreen(ImageJeu,Pos,clWhite,1,IntToStr(GScore) + ' points');
      end;
end;




{*******************************************************************************
Procédure :   NewGame
Description : Initialise tous les éléments pour une nouvelle partie

Paramètres d'entrée :
      Aucun

Auteur :      Link Aran
Version :     1.0, version de base, 12.07.06
*******************************************************************************}
procedure TMainForm.NewGame;
var //déclaration des varaibles
  i : integer; //pour l'itération des boucles for
  PositionTexte : TPoint; //pour la position du texte dans le composant image
begin
  //mise à zéro du Timer principal (TimerJeu)
  TimerJeu.Enabled := False;

  //Initialisation des variables globales
  SetLength(GTemp,0);
  SetLength(GTempColor,0);
  for i := 1 to 4 do
    GLigne[i] := 0;
  for i := 1 to 4 do
    begin
      GPiece[i].x := 0;
      GPiece[i].y := 0;
    end;
  for i := 1 to 108 do
    begin
      GJeu[i].x := 0;
      GJeu[i].y := 0;
      GJeuColor[i] := 0;
    end;
  GPieceUse := random(7) + 1;
  GPieceIndice := random(7) + 1;
  GLignes := 0;
  GNiveau := 0;
  GScore := 0;
  GPiecePosition.x := 120;
  GPiecePosition.y := 0;
  GCaseOccupees := 0;
  GOrientationPiece := 1;
  GNbLignes := 1;
  GAnimation := 0;
  GDiversBool1 := False;
  GDiversBool2 := False;
  GClignote := 1;
  GEnd := False;
  GStopMouv := False;
  GBackGround := '';

  //Initialisation de l'affichage
  ImageJeu.Picture.LoadFromFile(BGJeu);

  ImageIndice.Picture.LoadFromFile(BGIndice);

  LbNiveau.Caption := 'Level : --';
  LbLignes.Caption := 'Lines : 0';
  LbPoints.Caption := '0';

  //préparation à la saisie des valeurs pour une nouvelle partie
  PositionTexte.x := 80;
  PositionTexte.y := 10;
  WriteOnScreen(ImageJeu,PositionTexte,CouleurDef,3,'Tetris PC');
  PositionTexte.x := 10;
  PositionTexte.y := 50;
  WriteOnScreen(ImageJeu,PositionTexte,CouleurDef,2,'Game parameters :');
  PositionTexte.x := 20;
  PositionTexte.y := 130;
  WriteOnScreen(ImageJeu,PositionTexte,CouleurDef,2,'Level :');

  //lancement du timer animation pour un début de partie
  GAnimation := 1; //choix de l'animation (début choix du niveau);
  TimerAnimations.Enabled := True;
end;

{*******************************************************************************
Procedure :   DrawIndice
Description : Dessine dans la case indice la prochaine pièce
Paramètres d'entrées :
      Indice :      définit la pièce à afficher, obéit aux mêmes règles que la
                    variable Piece de la fonction VerifPart

Auteur :     Link Aran
Version :    1.0, version de base, 18.07.06
*******************************************************************************}
procedure TMainForm.DrawIndice(Indice:Word);
var //déclaration des variables
  i : integer; //pour l'incrémentation des boucles for

  //déclaration des tableaux
  TableauPiece : array[1..4] of TPoint; //contient les points de l'indice
begin
  //initialisation du tableau selon la requête
  case Indice of
    1 :
      begin
        TableauPiece[1].x := 32;
        TableauPiece[2].x := 32;
        TableauPiece[3].x := 32;
        TableauPiece[4].x := 32;
        TableauPiece[1].y := 10;
        TableauPiece[2].y := 25;
        TableauPiece[3].y := 40;
        TableauPiece[4].y := 55;
      end;
    2 :
      begin
        TableauPiece[1].x := 25;
        TableauPiece[2].x := 40;
        TableauPiece[3].x := 25;
        TableauPiece[4].x := 40;
        TableauPiece[1].y := 25;
        TableauPiece[2].y := 25;
        TableauPiece[3].y := 40;
        TableauPiece[4].y := 40;
      end;
    3 :
      begin
        TableauPiece[1].x := 17;
        TableauPiece[2].x := 32;
        TableauPiece[3].x := 47;
        TableauPiece[4].x := 32;
        TableauPiece[1].y := 25;
        TableauPiece[2].y := 25;
        TableauPiece[3].y := 25;
        TableauPiece[4].y := 40;
      end;
    4 :
      begin
        TableauPiece[1].x := 17;
        TableauPiece[2].x := 32;
        TableauPiece[3].x := 32;
        TableauPiece[4].x := 47;
        TableauPiece[1].y := 25;
        TableauPiece[2].y := 25;
        TableauPiece[3].y := 40;
        TableauPiece[4].y := 40;
      end;
    5 :
      begin
        TableauPiece[1].x := 32;
        TableauPiece[2].x := 47;
        TableauPiece[3].x := 17;
        TableauPiece[4].x := 32;
        TableauPiece[1].y := 25;
        TableauPiece[2].y := 25;
        TableauPiece[3].y := 40;
        TableauPiece[4].y := 40;
      end;
    6 :
      begin
        TableauPiece[1].x := 25;
        TableauPiece[2].x := 25;
        TableauPiece[3].x := 25;
        TableauPiece[4].x := 40;
        TableauPiece[1].y := 17;
        TableauPiece[2].y := 32;
        TableauPiece[3].y := 47;
        TableauPiece[4].y := 47;
      end;
    7 :
      begin
        TableauPiece[1].x := 40;
        TableauPiece[2].x := 40;
        TableauPiece[3].x := 25;
        TableauPiece[4].x := 40;
        TableauPiece[1].y := 17;
        TableauPiece[2].y := 32;
        TableauPiece[3].y := 47;
        TableauPiece[4].y := 47;
      end;
  end;

  //réinitialise le composant image
  {ImageIndice.Canvas.Pen.Color := clWhite;
  ImageIndice.Canvas.Brush.Color := clWhite;
  ImageIndice.Canvas.Rectangle(0,0,80,80);}
  ImageIndice.Picture.LoadFromFile('Images\Tetris_Indice00.bmp');

  //dessin de l'indice
  case Indice of
    1 : ImageIndice.Canvas.Pen.Color := clMaroon;
    2 : ImageIndice.Canvas.Pen.Color := clNavy;
    3 : ImageIndice.Canvas.Pen.Color := clPurple;
    4 : ImageIndice.Canvas.Pen.Color := clTeal;
    5 : ImageIndice.Canvas.Pen.Color := clGray;
    6 : ImageIndice.Canvas.Pen.Color := clBlue;
    7 : ImageIndice.Canvas.Pen.Color := clRed;
  end;
  ImageIndice.Canvas.Pen.Style := psClear;
  ImageIndice.Canvas.Brush.Color := ImageIndice.Canvas.Pen.Color;
  for i := 1 to 4 do
    ImageIndice.Canvas.Rectangle(TableauPiece[i].x,TableauPiece[i].y,
      TableauPiece[i].x + 15,TableauPiece[i].y + 15);
end;

{*******************************************************************************
Procédure :   WriteOnScreen
Description : Permet d'afficher la quasi totaloté des la table ascii simple
              dans un composant image.

Paramètres d'entrée :
      Composant :   définit dans quel composant image il faut dessiner
      Position :    définit la position du premier charactère
      Couleur :     définit la couleur du texte
      Epaisseur :   définit l'épaisseur du texte
      Texte :       définit le texte qui va être écrit

Auteur :      Link Aran
Version :     1.0, version de base, 24.06.06
*******************************************************************************}
procedure TMainForm.WriteOnScreen(Composant:TImage;Position:TPoint;
  Couleur:TColor;Epaisseur:byte;Texte:string);
var //déclaration des variables
  i : integer; //pour l'incrémentation des boucles for
begin
  //initialisation des paramètres du crayon
  Composant.Canvas.Pen.Style := psSolid;
  Composant.Canvas.Pen.Color := Couleur;
  Composant.Canvas.Pen.Width := Epaisseur;
  Composant.Canvas.Brush.Style := bsClear;

  //dessin des charactères
  for i := 1 to length(Texte) do
    begin
      case ord(Texte[i]) of
        32 : //charactére : ' '
          //incrémentation de la position du charactère, pour le prochain
          Position.X := Position.X + 12;
        33 : //charactère : '!'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 15);
            Composant.Canvas.Pixels[Position.X + 5, Position.Y + 20] := Couleur;

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        34 : //charactère : '"'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 3, Position.Y);
            Composant.Canvas.LineTo(Position.X + 3, Position.Y + 5);
            Composant.Canvas.MoveTo(Position.X + 7, Position.Y);
            Composant.Canvas.LineTo(Position.X + 7, Position.Y + 5);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        35 : //charactère : '#'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 5);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 8);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 8);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 12);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 12);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        37 : //charactère : '%'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.Ellipse(Position.X, Position.Y,
              Position.X + 5, Position.Y + 5);
            Composant.Canvas.Ellipse(Position.X + 5, Position.Y + 15,
              Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        39 : //charactère : '''
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 5);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        40 : //charactère : '('
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        41 : //charactère : ')'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        42 : //charactère : '*'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 10);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 5);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        43 : //charactère : '+'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 15);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        44 : //charactère : ','
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 25);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        45 : //charactère : '-'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        46 : //charactère : '.'
          begin
            //dessin du charactère
            Composant.Canvas.Pixels[Position.X + 5, Position.Y + 20] := Couleur;

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        47 : //charactère : '/'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        48 : //charactère : '0'
          begin
            //dessin du charactère
            Composant.Canvas.Rectangle(Position.X, Position.Y,
              Position.X + 11, Position.Y + 21);
            Composant.Canvas.MoveTo(Position.X , Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        49 : //charactère : '1'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X + 5 , Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 5);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        50 : //charactère : '2'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 11, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        51 : //charactère : '3'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        52 : //charactère : '4'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        53 : //charactère : '5'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X - 1, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        54 : //charactère : '6'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        55 : //charactère : '7'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        56 : //charactère : '8'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.Rectangle(Position.X, Position.Y,
              Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        57 : //charactère : '9'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        58 : //charactère : ':'
          begin
            //dessin du charactère
            Composant.Canvas.Pixels[Position.X + 5, Position.Y + 10] := Couleur;
            Composant.Canvas.Pixels[Position.X + 5, Position.Y + 20] := Couleur;

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        59 : //charactère : ';'
          begin
            //dessin du charactère
            Composant.Canvas.Pixels[Position.X + 5, Position.Y + 10] := Couleur;
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 25);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        60 : //charactère : '<'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 15);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        61 : //charactère : '='
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 8);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 8);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 12);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 12);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        62 : //charactère : '>'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 15);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        63 : //charactère : '?'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 15);
            Composant.Canvas.Pixels[Position.X + 5, Position.Y + 20] := Couleur;

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        64 : //charactère : '@'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 5);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        65 : //charactère : 'A'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        66 : //charactère : 'B'
          begin
            //dessin du charactère
            Composant.Canvas.Rectangle(Position.X, Position.Y,
              Position.X + 9, Position.Y + 9);
            Composant.Canvas.Rectangle(Position.X, Position.Y + 8,
              Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        67 : //charactère : 'C'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        68 : //charactère : 'D'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        69 : //charactère : 'E'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        70 : //charactère : 'F'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        71 : //charactère : 'G'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        72 : //charactère : 'H'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        73 : //charactère : 'I'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        74 : //charactère : 'J'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        75 : //charactère : 'K'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        76 : //charactère : 'L'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        77 : //charactère : 'M'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        78 : //charactère : 'N'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        79 : //charactère : 'O'
          begin
            //dessin du charactère
            Composant.Canvas.Rectangle(Position.X, Position.Y,
              Position.X + 11, Position.Y + 21);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        80 : //charactère : 'P'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        81 : //charactère : 'Q'
          begin
            //dessin du charactère
            Composant.Canvas.Rectangle(Position.X, Position.Y,
              Position.X + 11, Position.Y + 21);
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 15);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        82 : //charactère : 'R'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        83 : //charactère : 'S'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X - 1, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        84 : //charactère : 'T'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.MoveTo(Position.X + 6, Position.Y);
            Composant.Canvas.LineTo(Position.X + 6, Position.Y + 21);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        85 : //charactère : 'U'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        86 : //charactère : 'V'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y - 1);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        87 : //charactère : 'W'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 3, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X + 8, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y - 1);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        88 : //charactère : 'X'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);;

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        89 : //charactère : 'Y'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y - 1);
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 21);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        90 : //charactère : 'Z'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        91 : //charactère : '['
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        92 : //charactère : '\'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        93 : //charactère : ']'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        94 : //charactère : '^'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y);
            Composant.Canvas.LineTo(Position.X + 11, Position.Y + 6);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        95 : //charactère : '_'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        96 : //charactère : '''
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 5);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        97 : //charactère : 'a'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 15);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        98 : //charactère : 'b'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        99 : //charactère : 'c'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        100 : //charactère : 'd'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        101 : //charactère : 'e'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X, Position.Y + 15);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        102 : //charactère : 'f'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 5);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        103 : //charactère : 'g'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 25);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 25);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        104 : //charactère : 'h'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        105 : //charactère : 'i'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 10);
            Composant.Canvas.Pixels[Position.X + 5, Position.Y + 7] := Couleur;

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        106 : //charactère : 'j'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y + 25);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 10);
            Composant.Canvas.Pixels[Position.X + 5, Position.Y + 7] := Couleur;

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        107 : //charactère : 'k'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 16);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 11);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 16);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 21);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        108 : //charactère : 'l'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 21);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        109 : //charactère : 'm'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 21);
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 21);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        110 : //charactère : 'n'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 21);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        111 : //charactère : 'o'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        112 : //charactère : 'p'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 25);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        113 : //charactère : 'q'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 25);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        114 : //charactère : 'r'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        115 : //charactère : 's'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X - 1, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        116 : //charactère : 't'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X + 5, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 5);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        117 : //charactère : 'u'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 9);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        118 : //charactère : 'v'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 9);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        119 : //charactère : 'w'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 3, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 5, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 7, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 9);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        120 : //charactère : 'x'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        121 : //charactère : 'y'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 26);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
        122 : //charactère : 'z'
          begin
            //dessin du charactère
            Composant.Canvas.MoveTo(Position.X, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 10);
            Composant.Canvas.LineTo(Position.X, Position.Y + 20);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 20);
            Composant.Canvas.MoveTo(Position.X, Position.Y + 15);
            Composant.Canvas.LineTo(Position.X + 10, Position.Y + 15);

            //incrémentation de la position du charactère, pour le prochain
            Position.X := Position.X + 12;
          end;
      else
        begin
          //dessin du charactère universel
          Composant.Canvas.Rectangle(Position.X,Position.Y,
            Position.X + 10, Position.Y + 20);

          //incrémentation de la position du charactère, pour le prochain
          Position.X := Position.X + 12;
        end;
      end;
    end;
end;

{*******************************************************************************
Fonction :   VerifPart
Description : Vérifie si une pièce peut être affichée dans la position voulue

Paramètres d'entrée :
      Piece :       définit la pièce qui va être testée
                    1 -> ligne
                    2 -> carré
                    3 -> T
                    4 -> Z
                    5 -> Z inverse
                    6 -> L
                    7 -> L inverse
      Orientation : définit l'orientation de la pièce
      Position :    définit la position de le carré le plus bas de la pièce
Résultat :
      Le résultat indique si la pièce peut être affichée (0), si elle est trop à
      droite (1), trop à gauche (2), si elle est stoppée (3) ou si elle percute
      une autre pièce (4)

Auteur :      Link Aran
Version :     1.0, version de base, 12.07.06
*******************************************************************************}
function TMainForm.VerifPart(Piece:Word;Orientation:Word;Position:TPoint):Word;
var //déclaration des variables
  i, j, k, //pour l'itération des boucles for
  Temp : integer; //variable d'entiers pour diverses utilisations
begin
  //initialisation des variables
  Result := 0;
  Temp := 0;

  //Mise à jour du tableau de positions pour la pièce voulue
  case Piece of
    1 :
      if Orientation mod 2 <> 0
        then
          begin
            for i := 1 to 4 do
              GPiece[i].x := Position.x;
            GPiece[1].y := Position.y - 90;
            GPiece[2].y := Position.y - 60;
            GPiece[3].y := Position.y - 30;
            GPiece[4].y := Position.y;
          end
        else
          begin
            for i := 1 to 4 do
              GPiece[i].y := Position.y;
            GPiece[1].x := Position.x - 30;
            GPiece[2].x := Position.x;
            GPiece[3].x := Position.x + 30;
            GPiece[4].x := Position.x + 60;
          end;
    2 :
      begin
        GPiece[1].x := Position.x;
        GPIece[2].x := Position.x + 30;
        GPiece[3].x := Position.x;
        GPIece[4].x := Position.x + 30;
        GPiece[1].y := Position.y - 30;
        GPIece[2].y := Position.y - 30;
        GPiece[3].y := Position.y;
        GPIece[4].y := Position.y;
      end;
    3 :
      case Orientation of
        1 :
          begin
            GPiece[1].x := Position.x - 30;
            GPiece[2].x := Position.x;
            GPiece[3].x := Position.x + 30;
            GPiece[4].x := Position.x;
            GPiece[1].y := Position.y - 30;
            GPiece[2].y := Position.y - 30;
            GPiece[3].y := Position.y - 30;
            GPiece[4].y := Position.y;
          end;
        2 :
          begin
            GPiece[1].x := Position.x;
            GPiece[2].x := Position.x - 30;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x;
            GPiece[1].y := Position.y - 60;
            GPiece[2].y := Position.y - 30;
            GPiece[3].y := Position.y - 30;
            GPiece[4].y := Position.y;
          end;
        3 :
          begin
            GPiece[1].x := Position.x;
            GPiece[2].x := Position.x - 30;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x + 30;
            GPiece[1].y := Position.y - 30;
            GPiece[2].y := Position.y;
            GPiece[3].y := Position.y;
            GPiece[4].y := Position.y;
          end;
        4 :
          begin
            GPiece[1].x := Position.x;
            GPiece[2].x := Position.x;
            GPiece[3].x := Position.x + 30;
            GPiece[4].x := Position.x;
            GPiece[1].y := Position.y - 60;
            GPiece[2].y := Position.y - 30;
            GPiece[3].y := Position.y - 30;
            GPiece[4].y := Position.y;
          end;
      end;
    4 :
      if Orientation mod 2 <> 0
        then
          begin
            GPiece[1].x := Position.x - 30;
            GPiece[2].x := Position.x;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x + 30;
            GPiece[1].y := Position.y - 30;
            GPiece[2].y := Position.y - 30;
            GPiece[3].y := Position.y;
            GPiece[4].y := Position.y;
          end
        else
          begin
            GPiece[1].x := Position.x + 30;
            GPiece[2].x := Position.x + 30;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x;
            GPiece[1].y := Position.y - 60;
            GPiece[2].y := Position.y - 30;
            GPiece[3].y := Position.y - 30;
            GPiece[4].y := Position.y;
          end;
    5 :
      if Orientation mod 2 <> 0
        then
          begin
            GPiece[1].x := Position.x;
            GPiece[2].x := Position.x + 30;
            GPiece[3].x := Position.x - 30;
            GPiece[4].x := Position.x;
            GPiece[1].y := Position.y - 30;
            GPiece[2].y := Position.y - 30;
            GPiece[3].y := Position.y;
            GPiece[4].y := Position.y;
          end
        else
          begin
            GPiece[1].x := Position.x - 30;
            GPiece[2].x := Position.x - 30;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x;
            GPiece[1].y := Position.y - 60;
            GPiece[2].y := Position.y - 30;
            GPiece[3].y := Position.y - 30;
            GPiece[4].y := Position.y;
          end;
    6 :
      case Orientation of
        1 :
          begin
            GPiece[1].x := Position.x;
            GPiece[2].x := Position.x;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x + 30;
            GPiece[1].y := Position.y - 60;
            GPiece[2].y := Position.y - 30;
            GPiece[3].y := Position.y;
            GPiece[4].y := Position.y;
          end;
        2 :
          begin
            GPiece[1].x := Position.x;
            GPiece[2].x := Position.x + 30;
            GPiece[3].x := Position.x + 60;
            GPiece[4].x := Position.x;
            GPiece[1].y := Position.y - 30;
            GPiece[2].y := Position.y - 30;
            GPiece[3].y := Position.y - 30;
            GPiece[4].y := Position.y;
          end;
        3 :
          begin
            GPiece[1].x := Position.x - 30;
            GPiece[2].x := Position.x;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x;
            GPiece[1].y := Position.y - 60;
            GPiece[2].y := Position.y - 60;
            GPiece[3].y := Position.y - 30;
            GPiece[4].y := Position.y;
          end;
        4 :
          begin
            GPiece[1].x := Position.x + 30;
            GPiece[2].x := Position.x - 30;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x + 30;
            GPiece[1].y := Position.y - 30;
            GPiece[2].y := Position.y;
            GPiece[3].y := Position.y;
            GPiece[4].y := Position.y;
          end;
      end;
    7 :
      case Orientation of
        1 :
          begin
            GPiece[1].x := Position.x;
            GPiece[2].x := Position.x;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x - 30;
            GPiece[1].y := Position.y - 60;
            GPiece[2].y := Position.y - 30;
            GPiece[3].y := Position.y;
            GPiece[4].y := Position.y;
          end;
        2 :
          begin
            GPiece[1].x := Position.x - 30;
            GPiece[2].x := Position.x - 30;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x + 30;
            GPiece[1].y := Position.y - 30;
            GPiece[2].y := Position.y;
            GPiece[3].y := Position.y;
            GPiece[4].y := Position.y;
          end;
        3 :
          begin
            GPiece[1].x := Position.x + 30;
            GPiece[2].x := Position.x;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x;
            GPiece[1].y := Position.y - 60;
            GPiece[2].y := Position.y - 60;
            GPiece[3].y := Position.y - 30;
            GPiece[4].y := Position.y;
          end;
        4 :
          begin
            GPiece[1].x := Position.x - 60;
            GPiece[2].x := Position.x - 30;
            GPiece[3].x := Position.x;
            GPiece[4].x := Position.x;
            GPiece[1].y := Position.y - 30;
            GPiece[2].y := Position.y - 30;
            GPiece[3].y := Position.y - 30;
            GPiece[4].y := Position.y;
          end;
      end;
  end;

  //vérification que la pièce peut être affichée
  for i := 1 to 4 do
    if GPiece[i].x >= 270
      then
        Result := 1; //pièce trop à droite
  for i := 1 to 4 do
    if GPiece[i].x < 0
      then
        Result := 2; //pièce trop à gauche
  for i := 1 to 4 do
    if GPiece[i].y > 330
      then
        Result := 3; //pièce stoppée

  //vérification d'éventuelles percussions avec d'autres pièces
  for i := 1 to 4 do
    for j := 1 to 108 do
      if j < GCaseOccupees
        then
          if ((GPiece[i].x = GJeu[j].x) and (GPiece[i].y + 30 = GJeu[j].y))
            and (GJeuColor[j] <> 0)
            then
              Temp := 4; //piece stoppée par une autre pièce
  Result := Result + Temp;
end;

end.
