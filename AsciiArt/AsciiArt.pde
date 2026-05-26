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
  fft.analyze();   // keep if used elsewhere
  boolean beatDetected = amplitude > 0.12; // adjust threshold to taste

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

  // saveFrame("frames/frame-####.png"); // Need to remove the comment to save frames for the video
}

void keyPressed() {
  // 1..6 → change visibility of layers (1-3 for Petúnia, 4-6 for Henrique, 7-9 for Miguel)
  if (key >= '1' && key <= '9') {
    int index = key - '1';
    layerOn[index] = !layerOn[index];
    
    if (key == '1' && layerOn[0]) {
      resetLayer1(); 
    }
  }
  // m → change between music and mic input
  if (key == 'm' || key == 'M') changeAudioFont();
  keyPressed_p1();
}
