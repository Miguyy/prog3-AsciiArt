// In HenriqueLayer1_Sketch4.pde
String[] words = {
  "IPP", "ESMAD", "P.PORTO", "TDW", "TSIW", "DM", "TMD", "DI", "PM"
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

int lastMouseX = -1;
int lastMouseY = -1;
int lastMoveMs = 0;
float lockedHue = 200.0;
float lockedSat = 70.0;
float lockedBri = 90.0;
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
    lockedHue = (lockedHue + speed * 4.0) % 360.0;
    lockedSat = 60.0 + (speed * 3.0) % 40.0;
    lockedBri = 75.0 + (speed * 2.0) % 25.0;
    lastMoveMs = now;
  }
  lastMouseX = mouseX;
  lastMouseY = mouseY;
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

  float time = millis() * 0.001;
  float warpStrength = 18.0 + audioVolume * 35.0;
  int step = max(10, int(16 + audioVolume * 40.0));
  float glyphSize = max(8, step * 0.9);

  pg.textAlign(CENTER, CENTER);
  pg.textSize(glyphSize);
  pg.colorMode(HSB, 360, 100, 100, 255);

  for (int y = 0; y < pg.height; y += step) {
    for (int x = 0; x < pg.width; x += step) {
      float n = noise(x * 0.004, y * 0.004, time * 0.35);
      float waveX = sin(y * 0.015 + time * 2.2) * warpStrength;
      float waveY = cos(x * 0.017 + time * 1.8) * warpStrength;
      float ripple = (n - 0.5) * warpStrength * 2.0;
      int sx = int(x + waveX + ripple);
      int sy = int(y + waveY - ripple);

      float alpha = sampleBlendAlpha(sx, sy, fadeT);
      if (alpha <= 10) continue;

      float edgeAlpha = max(
        sampleBlendAlpha(sx + step, sy, fadeT),
        sampleBlendAlpha(sx - step, sy, fadeT)
      );
      edgeAlpha = max(edgeAlpha, sampleBlendAlpha(sx, sy + step, fadeT));
      edgeAlpha = max(edgeAlpha, sampleBlendAlpha(sx, sy - step, fadeT));

      boolean isEdge = edgeAlpha < 80.0;
      int gridX = x / step;
      int gridY = y / step;
      int key = gridY * 10000 + gridX;
      float mouseDist = dist(mouseX, mouseY, x, y);
      boolean nearMouse = mouseDist < step * 2.5;

      if (!isEdge && nearMouse) {
        mutateUntil.set(str(key), now + mutateDecayMs);
        if (!mutateChar.hasKey(str(key))) {
          mutateChar.set(str(key), int(randomMutateChar()));
        }
      }

      if (isEdge) {
        pg.fill(lockedHue, 90, 100, 255);
        pg.text(randomAlphabetChar(), x, y);
      } else {
        int until = mutateUntil.hasKey(str(key)) ? mutateUntil.get(str(key)) : 0;
        if (until > now) {
          int stored = mutateChar.get(str(key));
          pg.fill(lockedHue, 90, 100, 255);
          pg.text(char(stored), x, y);
        } else {
          pg.fill(lockedHue, lockedSat, lockedBri, 220);
          pg.text(",", x, y);
          if (mutateChar.hasKey(str(key))) {
            mutateChar.remove(str(key));
            mutateUntil.remove(str(key));
          }
        }
      }
    }
  }

  pg.colorMode(RGB, 255, 255, 255, 255);
  pg.endDraw();
}

		