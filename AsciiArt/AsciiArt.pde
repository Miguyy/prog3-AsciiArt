/*
  Propósito:
    Entrada principal do sketch Processing.
    - Inicializa áudio, paleta de cores e layers (PGraphics) usados pelas várias
      camadas (Petúnia, Henrique, Miguel).
    - Contém o ciclo principal `draw()` que atualiza e desenha cada layer
      dependendo do estado de visibilidade e dos dados de áudio.
*/

import processing.sound.*; // biblioteca de som do Processing

// Estado global do áudio
SoundFile music;   // ficheiro de música para reprodução
AudioIn mic;       // entrada do microfone
Amplitude amp;     // analisador de amplitude para detectar volume geral
FFT fft;           // analisador de frequências (FFT)
BeatDetector beat; // detector simples de batidas/onsets
boolean useMic = false; // alterna entre ficheiro de música e microfone com 'm'
boolean showHUD = false; // mostrar/ocultar HUD com informação de frequência com 'h'

// Layers — 3 por estudante, cada um desenhado em um PGraphics para controlo
PGraphics pL1, pL2, pL3;   // camadas da Petúnia
PGraphics hL1, hL2, hL3;  // camadas do Henrique
PGraphics mL1, mL2, mL3;   // camadas do Miguel

// Controlo de visibilidade das layers (toggle com teclas '1'..'9')
// índice 0 = Petúnia layer 1 está ligado por omissão
boolean[] layerOn = { true, false, false, false, false, false, false, false, false };

// Paleta de cores usada pelo projeto
color[] palette;

void setup() {
  size(1920, 1080, P2D);
  fullScreen(P2D);
  frameRate(25);
  surface.setResizable(false);
  smooth(8);
  

  palette = new color[]{
    /* Colors: 
    010101
    022664
    210110
    040813
    1B3518
    27C6ED
    D71E24
    4EA658
    AFAFAF*/
    color(1, 1, 1), // Color 1: #010101
    color(2, 38, 100), // Color 2: #022664
    color(33, 1, 16), // Color 3: #210110
    color(4, 8, 19), // Color 4: #040813
    color(27, 53, 24), // Color 5: #1B3518
    color(39, 198, 237), // Color 6: #27C6ED
    color(215, 30, 36), // Color 7: #D71E24
    color(78, 166, 88), // Color 8: #4EA658
    color(175, 175, 175) // Color 9: #AFAFAF
  };

  // Inicializa o sistema de áudio (ver Audio.pde)
  setupAudio();

  // Inicializar PGraphics para cada layer (mesma dimensão do ecrã)
  pL1 = createGraphics(width, height, P2D);
  pL1.smooth(8);
  pL2 = createGraphics(width, height, P2D);
  pL2.smooth(8);
  pL3 = createGraphics(width, height, P2D);
  pL3.smooth(8);
  hL1 = createGraphics(width, height, P2D);
  hL1.smooth(8);
  hL2 = createGraphics(width, height, P2D);
  hL2.smooth(8);
  hL3 = createGraphics(width, height, P2D);
  hL3.smooth(8);
  mL1 = createGraphics(width, height, P2D);
  mL1.smooth(8);
  mL2 = createGraphics(width, height, P2D);
  mL2.smooth(8);
  mL3 = createGraphics(width, height, P2D);
  mL3.smooth(8);
}

void draw() {
  // Fundo base usando a primeira cor da paleta
  background(palette[0]);

  // Ler analisadores de áudio
  float amplitude = amp.analyze();
  fft.analyze();
  // Detecção simples de batida com threshold ajustável
  boolean beatDetected = amplitude > 0.12;

  if (layerOn[0]) drawPetunia1(pL1, amplitude, beatDetected);
  if (layerOn[1]) drawPetunia2(pL2, amplitude, beatDetected);
  if (layerOn[2]) drawPetunia3(pL3, amplitude, beatDetected);
  if (layerOn[3]) drawHenrique1(hL1, amplitude, beatDetected);
  if (layerOn[4]) drawHenrique2(hL2, amplitude, beatDetected);
  if (layerOn[5]) drawHenrique3(hL3, amplitude, beatDetected);
  if (layerOn[6]) drawMiguel1(mL1, amplitude, beatDetected);
  if (layerOn[7]) drawMiguel2(mL2, amplitude, beatDetected);
  if (layerOn[8]) drawMiguel3(mL3, amplitude, beatDetected);

  if (layerOn[0]) image(pL1, 0, 0);
  if (layerOn[1]) image(pL2, 0, 0);
  if (layerOn[2]) image(pL3, 0, 0);
  if (layerOn[3]) image(hL1, 0, 0);
  if (layerOn[4]) image(hL2, 0, 0);
  if (layerOn[5]) image(hL3, 0, 0);
  if (layerOn[6]) image(mL1, 0, 0);
  if (layerOn[7]) image(mL2, 0, 0);
  if (layerOn[8]) image(mL3, 0, 0);

  // HUD (frequências / diagnóstico) — opcional
  if (showHUD) renderHUD();

  // saveFrame("frames/frame-####.png"); // Need to remove the comment to save frames for the video
}

// renderHUD()
// Desenha um painel simples com barras de espectro (baixas→médias) para depuração.
void renderHUD(){
  if (fft == null) return;
  float[] spec = new float[512];
  fft.analyze(spec);

  int bands = 16;
  float bw = 12;
  float spacing = 6;
  float startX = 20;
  float startY = height - 160;

  pushStyle();
  // Painel de fundo sem contorno
  noStroke();
  fill(0, 120);
  rect(startX - 8, startY - 8, bands * (bw + spacing) + 40, 140, 6);

  // Desenhar barras agregadas por bandas (low→mid)
  for (int i = 0; i < bands; i++){
    int s = int(map(i, 0, bands, 0, 40));
    int e = int(map(i+1, 0, bands, 0, 40));
    float sum = 0;
    for (int j = s; j < e && j < spec.length; j++) sum += spec[j];
    float val = sum / max(1, e - s);
    float h = constrain(val * 300, 0, 120);
    color barCol = (palette != null && palette.length > 5) ? palette[5] : color(39,198,237);
    fill(barCol);
    rect(startX + i * (bw + spacing), startY + 120 - h, bw, h);
    // contorno da barra
    noFill();
    stroke(180);
    rect(startX + i * (bw + spacing), startY + 20, bw, 120);
  }

  // pequenas legendas
  noStroke();
  fill(255);
  textSize(12);
  textAlign(LEFT, TOP);
  text("Frequency", startX, startY - 24);
  popStyle();
};

void keyPressed() {
  // Mudar entre as layers com as teclas '1'..'9'
  if (key >= '1' && key <= '9') {
    int idx = key - '1';
    for (int i = 0; i < layerOn.length; i++) {
      layerOn[i] = (i == idx);
    }
  }
  // m → alternar entre usar o ficheiro de música e o microfone como fonte de áudio
  if (key == 'm' || key == 'M') changeAudioFont();
  // space → pausar/resumir música (funciona apenas quando a fonte é o ficheiro, não o mic)
  if (key == ' ') {
    if (music != null) {
      if (music.isPlaying()) music.pause();
      else music.play();
    }
  }
  // Chamar funções de keyPressed específicas de cada layer, se existirem 
  try {
    miguelLayer1KeyPressed();
  } catch (Exception e) {
    // Ignora se a função não existir 
  }
  try {
    miguelLayer2KeyPressed();
  } catch (Exception e) {
    // Ignora se a função não existir 
  }
  try {
    miguelLayer3KeyPressed();
  } catch (Exception e) {
    // Ignora se a função não existir 
  }
  //  Esconde HUD
  if (key == 'h' || key == 'H') showHUD = !showHUD;
}