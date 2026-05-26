/*
  Propósito:
    Criar uma grelha ASCII rígida que revela palavras (IPP, ESMAD, etc.) com
    transições suaves entre máscaras, reagindo ao áudio e ao rato. As letras
    mudam temporariamente perto do cursor e a cor varia com o movimento.
*/
String[] words = {
  "IPP", "ESMAD", "TDW", "TSIW", "DM", "TMD", "DI", "PM"
};

String alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
String mutatePool = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+=-[]{}<>?/\\|";

boolean init = false;
int wordIndex = 0;
int nextWordIndex = 1;
int wordStartMs = 0;
int holdMs = 5000;
int fadeMs = 1500;
PGraphics maskA;
PGraphics maskB;
PFont henrique1Font;
boolean henrique1FontsLogged = false;

int lastMouseX = -1;
int lastMouseY = -1;
int lastMoveMs = 0;
float lockedHue = 200.0;
float lockedSat = 70.0;
float lockedBri = 90.0;
float palettePhase = 0.0;
IntDict mutateUntil;
IntDict mutateChar;
int mutateDecayMs = 350;

void initHenrique1() {
  wordIndex = 0;
  nextWordIndex = 1;
  wordStartMs = millis();
  init = true;
  maskA = createGraphics(width, height);
  maskB = createGraphics(width, height);
  lastMouseX = mouseX;
  lastMouseY = mouseY;
  lastMoveMs = millis();
  mutateUntil = new IntDict();
  mutateChar = new IntDict();
  if (!henrique1FontsLogged) {
    henrique1FontsLogged = true;
  }
  henrique1Font = createFont(selectHenrique1Font(), 48, true);
}

String selectHenrique1Font() {
  return "Courier";
}

char randomAlphabetChar() {
  int idx = int(random(alphabet.length()));
  return alphabet.charAt(idx);
}

char randomMutateChar() {
  int idx = int(random(mutatePool.length()));
  return mutatePool.charAt(idx);
}

void updatePalette() {
  int now = millis();
  float speed = dist(mouseX, mouseY, lastMouseX, lastMouseY);
  if (speed > 1.0) {
    palettePhase = (palettePhase + speed * 0.02) % 3.0;
    lastMoveMs = now;
  }
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

color paletteBlend(float phase) {
  color c1 = (palette != null && palette.length > 5) ? palette[5] : color(39, 198, 237);
  color c2 = (palette != null && palette.length > 6) ? palette[6] : color(215, 30, 36);
  color c3 = (palette != null && palette.length > 7) ? palette[7] : color(78, 166, 88);
  float t = phase % 3.0;
  if (t < 1.0) return lerpColor(c1, c2, t);
  if (t < 2.0) return lerpColor(c2, c3, t - 1.0);
  return lerpColor(c3, c1, t - 2.0);
}

PGraphics renderWordMask(PGraphics mask, String word, float textSize) {
  if (mask == null || mask.width != width || mask.height != height) {
    mask = createGraphics(width, height);
  }
  mask.beginDraw();
  mask.clear();
  mask.textAlign(CENTER, CENTER);
  mask.textSize(textSize);
  mask.fill(255);
  mask.text(word, mask.width * 0.5, mask.height * 0.5);
  mask.endDraw();
  mask.loadPixels();
  return mask;
}

int sampleMaskAlpha(PGraphics mask, int x, int y) {
  if (mask == null) return 0;
  if (x < 0 || y < 0 || x >= mask.width || y >= mask.height) return 0;
  int idx = y * mask.width + x;
  return (mask.pixels[idx] >>> 24) & 0xFF;
}

float sampleBlendAlpha(int x, int y, float fadeT) {
  int a = sampleMaskAlpha(maskA, x, y);
  int b = sampleMaskAlpha(maskB, x, y);
  return lerp(a, b, fadeT);
}

void drawHenrique1(PGraphics pg, float amp, boolean beat) {
  if (!init) initHenrique1();

  pg.beginDraw();
  pg.clear();
  pg.background(palette[3]);

  int now = millis();
  int elapsed = now - wordStartMs;
  float fadeT = 0.0;
  if (elapsed > holdMs) {
    fadeT = constrain((elapsed - holdMs) / float(fadeMs), 0.0, 1.0);
  }
  if (elapsed > holdMs + fadeMs) {
    wordIndex = nextWordIndex;
    nextWordIndex = (wordIndex + 1) % words.length;
    wordStartMs = now;
    fadeT = 0.0;
  }

  updatePalette();

  float audioVolume = constrain(amp, 0.0, 1.0);
  float baseWordSize = min(pg.width, pg.height) * 0.38;
  float wordScale = 1.0 + audioVolume * 1.6;
  float wordSize = baseWordSize * wordScale;

  maskA = renderWordMask(maskA, words[wordIndex], wordSize);
  maskB = renderWordMask(maskB, words[nextWordIndex], wordSize);

  // Grelha fixa para um layout rígido em matriz.
  int cellSize = max(12, int(min(pg.width, pg.height) * 0.03));
  int cols = pg.width / cellSize;
  int rows = pg.height / cellSize;
  float glyphSize = cellSize * 0.85;

  pg.textAlign(CENTER, CENTER);
  pg.textFont(henrique1Font);
  pg.textSize(glyphSize);
  pg.colorMode(RGB, 255, 255, 255, 255);

  color baseCol = paletteBlend(palettePhase);
  color beatCol = paletteBlend(palettePhase + 0.8);
  color hoverCol = paletteBlend(palettePhase + 1.6);

  for (int row = 0; row < rows; row++) {
    for (int col = 0; col < cols; col++) {
      // Coordenadas fixas da matriz: cada célula mapeia para o centro exato.
      int x = col * cellSize + cellSize / 2;
      int y = row * cellSize + cellSize / 2;

      float alpha = sampleBlendAlpha(x, y, fadeT);
      if (alpha <= 10) continue;

      int key = row * 10000 + col;
      float mouseDist = dist(mouseX, mouseY, x, y);
      boolean nearMouse = mouseDist < cellSize * 2.5;

      if (nearMouse) {
        mutateUntil.set(str(key), now + mutateDecayMs);
        if (!mutateChar.hasKey(str(key))) {
          mutateChar.set(str(key), int(randomMutateChar()));
        }
      }

      int until = mutateUntil.hasKey(str(key)) ? mutateUntil.get(str(key)) : 0;
      if (until > now) {
        int stored = mutateChar.get(str(key));
        pg.fill(beat ? beatCol : hoverCol, 255);
        pg.text(char(stored), x, y);
      } else {
        // Glifos padrão da matriz dentro da máscara de texto.
        pg.fill(baseCol, 220);
        pg.text(",", x, y);
        if (mutateChar.hasKey(str(key))) {
          mutateChar.remove(str(key));
          mutateUntil.remove(str(key));
        }
      }
    }
  }

  pg.endDraw();
}

		