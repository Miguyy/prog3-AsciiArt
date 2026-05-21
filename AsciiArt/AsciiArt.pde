import processing.sound.*;

// Audio global state
SoundFile music;
AudioIn mic;
Amplitude amp;
FFT fft;
BeatDetector beat;
boolean useMic = false; // change between music and mic with 'm' key

// Layers — 3 per student, drawn in separate PGraphics for better performance and control
PGraphics pL1, pL2, pL3;   // Petúnia
PGraphics hL1, hL2, hL3;  // Henrique
PGraphics mL1, mL2, mL3;   // Miguel

// Layer visibility control (toggle with keys 1-6)
boolean[] layerOn = { true, true, true, true, true, true, true, true, true };

color[] palette; // color palette for the artwork

void setup() {
  size(1920, 1080);
  frameRate(25);

  palette = new color[]{
    color(1, 1, 1),       // #010101 - Quase Preto
    color(34, 0, 16),      // #220010 - Roxo Escuro
    color(190, 42, 56),    // #be2a38 - Vermelho
    color(71, 200, 99),    // #47c863 - Verde
    color(45, 139, 220),   // #2d8bdc - Azul
    color(91, 160, 217)    // #5ba0d9 - Azul Claro
  };

  setupAudio(); // define in Audio.pde

  // Initialize layers
  pL1 = createGraphics(width, height);
  pL2 = createGraphics(width, height);
  pL3 = createGraphics(width, height);
  hL1 = createGraphics(width, height);
  hL2 = createGraphics(width, height);
  hL3 = createGraphics(width, height);
  mL1 = createGraphics(width, height);
  mL2 = createGraphics(width, height);
  mL3 = createGraphics(width, height);
}

void draw() {
  background(palette[0]);

  float amplitude = amp.analyze();
  fft.analyze();
  boolean isBeat = beat.isBeat();

  if (layerOn[0]) drawPetunia1(pL1, amplitude, isBeat);
  if (layerOn[1]) drawPetunia2(pL2, amplitude, isBeat);
  if (layerOn[2]) drawPetunia3(pL3, amplitude, isBeat);
  if (layerOn[3]) drawHenrique1(hL1, amplitude, isBeat);
  if (layerOn[4]) drawHenrique2(hL2, amplitude, isBeat);
  if (layerOn[5]) drawHenrique3(hL3, amplitude, isBeat);
  if (layerOn[6]) drawMiguel1(mL1, amplitude, isBeat);
  if (layerOn[7]) drawMiguel2(mL2, amplitude, isBeat);
  if (layerOn[8]) drawMiguel3(mL3, amplitude, isBeat);

  if (layerOn[0]) image(pL1, 0, 0);
  if (layerOn[1]) image(pL2, 0, 0);
  if (layerOn[2]) image(pL3, 0, 0);
  if (layerOn[3]) image(hL1, 0, 0);
  if (layerOn[4]) image(hL2, 0, 0);
  if (layerOn[5]) image(hL3, 0, 0);
  if (layerOn[6]) image(mL1, 0, 0);
  if (layerOn[7]) image(mL2, 0, 0);
  if (layerOn[8]) image(mL3, 0, 0);

  // saveFrame("frames/frame-####.png"); // Need to remove the comment to save frames for the video
}

void keyPressed() {
  // 1..9 → change visibility of layers (1-3 for Petúnia, 4-6 for Henrique, 7-9 for Miguel)
  if (key >= '1' && key <= '9') layerOn[key - '1'] = !layerOn[key - '1'];
  // m → change between music and mic input
  if (key == 'm' || key == 'M') changeAudioFont();
}
