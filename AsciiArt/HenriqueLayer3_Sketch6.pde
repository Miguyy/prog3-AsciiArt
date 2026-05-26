/*
    Propósito:
        Converter uma sequência de frames em silhuetas ASCII reativas ao áudio.
        A animação avança com batidas/picos e pausa no silêncio, enquanto o rato
        provoca variações locais nos glifos e no brilho.
*/

// ---- Motor ASCII + estado do ciclo de frames ----
final String ASCII_RAMP = " .:-=+*#%@"; // escuro -> claro
final char HENRIQUE3_SOLID_CHAR = '@';
final int HENRIQUE3_FRAME_COUNT = 23;
final int HENRIQUE3_TARGET_W = 1200;
final int HENRIQUE3_TARGET_H = 1200;
final int HENRIQUE3_CORNER_FRAME_COUNT = 33;
final float HENRIQUE3_SILHOUETTE_SCALE = 0.85;
final float HENRIQUE3_CORNER_SCALE = 0.32;

char[] henrique3StarChars = {'.', ',', '*'};
int[][] henrique3StarMap;
float[][] henrique3StarGlow;
int henrique3StarCols = -1;
int henrique3StarRows = -1;

PImage[] henrique3Frames;
PImage[] henrique3CornerFrames;
int henrique3FrameIndex = 0;
int henrique3CornerIndex = 0;
boolean henrique3Ready = false;
int henrique3CornerVisibleCount = 0;

PFont henrique3Font;
int henrique3CharSize = 16; // ajustar para mudar a densidade ASCII
int henrique3CharW = 6; // espaçamento horizontal mais apertado para preenchimento sólido
int henrique3CharH = 10; // espaçamento vertical mais apertado para preenchimento sólido
int henrique3HoverRadius = 60; // raio de hover do rato em píxeis

int henrique3LastSwitchMs = 0;
int henrique3MinSwitchIntervalMs = 80; // debounce para batidas rápidas
float henrique3SilenceThreshold = 0.015; // abaixo disto, congela o frame
float henrique3SpikeThreshold = 0.06; // acima disto, permite troca
float henrique3SilhouetteThreshold = 120; // limiar mais amplo para silhueta completa

// Inicializar frames e fonte uma vez (carregamento preguiçoso no draw)
void initHenrique3() {
    henrique3Frames = new PImage[HENRIQUE3_FRAME_COUNT];

    for (int i = 0; i < HENRIQUE3_FRAME_COUNT; i++) {
        int frameNumber = i; // frames are 0..22
        String frameLabel = nf(frameNumber, 2); // 00..22
        // Carregar da pasta frames do sketch (frame00.gif..frame22.gif)
        PImage img = loadImage(sketchPath("data/frame" + frameLabel + ".gif"));
        if (img != null) {
            img.resize(HENRIQUE3_TARGET_W, HENRIQUE3_TARGET_H); // normalize size
        }
        henrique3Frames[i] = img;
    }

    henrique3CornerFrames = new PImage[HENRIQUE3_CORNER_FRAME_COUNT];
    for (int i = 0; i < HENRIQUE3_CORNER_FRAME_COUNT; i++) {
        String frameLabel = nf(i, 2);
        PImage img = loadImage(sketchPath("data/frame" + frameLabel + "_2.gif"));
        henrique3CornerFrames[i] = img;
    }

    // Fonte monoespaçada para grelha ASCII estável
    henrique3Font = createFont("Courier", henrique3CharSize, true);

    henrique3Ready = true;
}

void ensureHenrique3Stars(int cols, int rows) {
    if (henrique3StarMap != null && cols == henrique3StarCols && rows == henrique3StarRows) {
        return;
    }
    henrique3StarCols = cols;
    henrique3StarRows = rows;
    henrique3StarMap = new int[cols][rows];
    henrique3StarGlow = new float[cols][rows];

    float starProbability = 0.0065;
    for (int x = 0; x < cols; x++) {
        for (int y = 0; y < rows; y++) {
            if (random(1) < starProbability) {
                henrique3StarMap[x][y] = int(random(1, 4));
                henrique3StarGlow[x][y] = random(0.35, 1.0);
            } else {
                henrique3StarMap[x][y] = 0;
                henrique3StarGlow[x][y] = 0;
            }
        }
    }
}

// Converter um PImage para ASCII e renderizar num buffer PGraphics
void renderAscii(PGraphics pg, PImage img, float amp, boolean beat) {
    if (img == null) {
        return;
    }

    img.loadPixels();

    pg.beginDraw();
    pg.background(0); // preto puro, sem texto de fundo
    pg.textFont(henrique3Font);
    pg.textAlign(LEFT, TOP);
    pg.colorMode(RGB, 255, 255, 255, 255);
    color baseCol = paletteBlend(palettePhase);
    color hoverCol = paletteBlend(palettePhase + 1.6);
    pg.fill(baseCol, 230);
    pg.noStroke();

    // Tamanho da grelha da silhueta baseado na imagem redimensionada
    int silCols = max(1, int((img.width * HENRIQUE3_SILHOUETTE_SCALE) / henrique3CharW));
    int silRows = max(1, int((img.height * HENRIQUE3_SILHOUETTE_SCALE) / henrique3CharH));

    int starCols = max(1, pg.width / henrique3CharW);
    int starRows = max(1, pg.height / henrique3CharH);
    ensureHenrique3Stars(starCols, starRows);

    // Centrar horizontalmente e alinhar em baixo com a borda da janela
    int startX = (pg.width - silCols * henrique3CharW) / 2;
    int startY = pg.height - silRows * henrique3CharH;
    int endX = startX + silCols * henrique3CharW;
    int endY = startY + silRows * henrique3CharH;

    float stepX = img.width / float(silCols);
    float stepY = img.height / float(silRows);

    float hf = 0;
    if (fft != null) {
        float[] specLocal = new float[512];
        fft.analyze(specLocal);
        for (int fi = 300; fi < 512; fi++) hf += specLocal[fi];
        hf /= max(1, 512 - 300);
    }

    color starBase = (palette != null && palette.length > 8) ? palette[8] : color(175, 175, 175);

    // Desenhar ASCII apenas onde a silhueta é detetada
    for (int y = 0; y < silRows; y++) {
        int py = int(y * stepY);
        for (int x = 0; x < silCols; x++) {
            int px = int(x * stepX);
            int idx = py * img.width + px;
            int c = img.pixels[idx];
            float b = brightness(c); // 0..100 in Processing

            int gx = startX + x * henrique3CharW;
            int gy = startY + y * henrique3CharH;
            if (b >= henrique3SilhouetteThreshold) {
                float mouseDist = dist(mouseX, mouseY, gx, gy);
                float clampedB = constrain(b, 0, 255);
                int rampIndex = int(map(clampedB, 0, 255, 0, ASCII_RAMP.length() - 1));
                rampIndex = constrain(rampIndex, 0, ASCII_RAMP.length() - 1);
                char glyph = ASCII_RAMP.charAt(rampIndex);
                if (mouseDist <= henrique3HoverRadius) {
                    float alpha = map(mouseDist, 0, henrique3HoverRadius, 255, 180);
                    pg.fill(hoverCol, alpha);
                    glyph = ASCII_RAMP.charAt(int(random(ASCII_RAMP.length())));
                } else {
                    pg.fill(baseCol, 230);
                }
                pg.text(glyph, gx, gy);
            } else {
                int sx = constrain(gx / henrique3CharW, 0, starCols - 1);
                int sy = constrain(gy / henrique3CharH, 0, starRows - 1);
                int sIdx = henrique3StarMap[sx][sy];
                if (sIdx > 0) {
                    int charIndex = constrain(sIdx - 1, 0, henrique3StarChars.length - 1);
                    char starChar = henrique3StarChars[charIndex];
                    float twinkle = henrique3StarGlow[sx][sy] + amp * 0.9 + (beat ? 0.6 : 0) + hf * 1.2;
                    float alpha = constrain(twinkle, 0.15, 1.0);
                    color starColor = pg.color(red(starBase) * alpha, green(starBase) * alpha, blue(starBase) * alpha);
                    pg.fill(starColor);
                    pg.text(starChar, gx, gy);
                }
            }
        }
    }

    // Estrelas apenas nas laterais da silhueta
    for (int y = 0; y < starRows; y++) {
        int posY = y * henrique3CharH;
        if (posY < startY || posY >= endY) continue;
        for (int x = 0; x < starCols; x++) {
            int posX = x * henrique3CharW;
            boolean insideSilhouette = (posX >= startX && posX < endX && posY >= startY && posY < endY);
            if (insideSilhouette) continue;

            int sIdx = henrique3StarMap[x][y];
            if (sIdx > 0) {
                int charIndex = constrain(sIdx - 1, 0, henrique3StarChars.length - 1);
                char starChar = henrique3StarChars[charIndex];
                float twinkle = henrique3StarGlow[x][y] + amp * 0.9 + (beat ? 0.6 : 0) + hf * 1.2;
                float alpha = constrain(twinkle, 0.15, 1.0);
                color starColor = pg.color(red(starBase) * alpha, green(starBase) * alpha, blue(starBase) * alpha);
                pg.fill(starColor);
                pg.text(starChar, posX, posY);
            }
        }
    }

    if (henrique3CornerVisibleCount > 0) {
        drawHenrique3Corners(pg, baseCol, hoverCol, henrique3CornerVisibleCount);
    }
    pg.endDraw();
}

void drawHenrique3Corners(PGraphics pg, color cornerCol, color hoverCol, int visibleCount) {
    if (henrique3CornerFrames == null || henrique3CornerFrames.length == 0) return;

    int reverseIndex = (henrique3CornerFrames.length - 1) - henrique3CornerIndex;
    PImage corner = henrique3CornerFrames[reverseIndex];
    if (corner == null) return;

    int size = int(min(pg.width, pg.height) * HENRIQUE3_CORNER_SCALE);
    int cols = max(1, size / henrique3CharW);
    int rows = max(1, size / henrique3CharH);
    int drawW = cols * henrique3CharW;
    int drawH = rows * henrique3CharH;
    int cornerInset = int(henrique3CharW * 2.0);
    int rightX = pg.width - drawW - cornerInset;
    int bottomYOffset = int(drawH * 0.32);
    int bottomY = pg.height - drawH - bottomYOffset;
    int topY = -int(drawH * 0.5);

    if (visibleCount >= 1) {
        renderCornerAscii(pg, corner, cornerInset, topY, drawW, drawH, cornerCol, hoverCol);
    }
    if (visibleCount >= 2) {
        renderCornerAscii(pg, corner, rightX, topY, drawW, drawH, cornerCol, hoverCol);
    }
    if (visibleCount >= 3) {
        renderCornerAscii(pg, corner, cornerInset, bottomY, drawW, drawH, cornerCol, hoverCol);
    }
    if (visibleCount >= 4) {
        renderCornerAscii(pg, corner, rightX, bottomY, drawW, drawH, cornerCol, hoverCol);
    }
}

void renderCornerAscii(PGraphics pg, PImage img, int startX, int startY, int targetW, int targetH, color col, color hoverCol) {
    if (img == null) return;
    img.loadPixels();

    int cols = max(1, targetW / henrique3CharW);
    int rows = max(1, targetH / henrique3CharH);
    float stepX = img.width / float(cols);
    float stepY = img.height / float(rows);

    for (int y = 0; y < rows; y++) {
        int py = int(y * stepY);
        for (int x = 0; x < cols; x++) {
            int px = int(x * stepX);
            int idx = py * img.width + px;
            int c = img.pixels[idx];
            float b = brightness(c);
            int rampIndex = int(map(b, 0, 255, ASCII_RAMP.length() - 1, 0));
            rampIndex = constrain(rampIndex, 0, ASCII_RAMP.length() - 1);
            char glyph = ASCII_RAMP.charAt(rampIndex);
            int gx = startX + x * henrique3CharW;
            int gy = startY + y * henrique3CharH;
            float alpha = map(b, 0, 255, 255, 80);
            pg.fill(col, alpha);
            pg.text(glyph, gx, gy);
        }
    }
}

// Atualização de frame conduzida pelo áudio
void updateHenrique3Frame(float amp, boolean beat) {
    // Se o som estiver silencioso, manter o frame atual (pausa)
    if (amp < henrique3SilenceThreshold) {
        return;
    }

    // Avançar apenas com batida ou pico forte, com debounce
    int now = millis();
    if ((beat || amp >= henrique3SpikeThreshold) && (now - henrique3LastSwitchMs) >= henrique3MinSwitchIntervalMs) {
        henrique3FrameIndex = (henrique3FrameIndex + 1) % HENRIQUE3_FRAME_COUNT;
        henrique3CornerIndex = (henrique3CornerIndex + 1) % HENRIQUE3_CORNER_FRAME_COUNT;
        henrique3LastSwitchMs = now;
    }
}

void henriqueLayer3KeyPressed() {
    if (key == 'g' || key == 'G') {
        henrique3CornerVisibleCount = (henrique3CornerVisibleCount + 1) % 5;
    }
}

void drawHenrique3(PGraphics pg, float amp, boolean beat){
    if (!henrique3Ready) {
        initHenrique3();
    }

    updatePalette();

    updateHenrique3Frame(amp, beat);

    PImage current = henrique3Frames[henrique3FrameIndex];
    renderAscii(pg, current, amp, beat);
}