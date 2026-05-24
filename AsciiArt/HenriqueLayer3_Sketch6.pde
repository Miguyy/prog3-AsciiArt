// In HenriqueLayer3_Sketch6.pde

// ---- ASCII engine + frame loop state ----
final String ASCII_RAMP = " .:-=+*#%@"; // dark -> bright
final char HENRIQUE3_SOLID_CHAR = '@';
final int HENRIQUE3_FRAME_COUNT = 23;
final int HENRIQUE3_TARGET_W = 1200;
final int HENRIQUE3_TARGET_H = 1200;

PImage[] henrique3Frames;
int henrique3FrameIndex = 0;
boolean henrique3Ready = false;

PFont henrique3Font;
int henrique3CharSize = 16; // adjust to change ASCII density
int henrique3CharW = 6; // tighter horizontal spacing for solid fill
int henrique3CharH = 10; // tighter vertical spacing for solid fill
int henrique3HoverRadius = 60; // mouse hover radius in pixels

int henrique3LastSwitchMs = 0;
int henrique3MinSwitchIntervalMs = 80; // debounce for rapid beats
float henrique3SilenceThreshold = 0.015; // below this, freeze the frame
float henrique3SpikeThreshold = 0.06; // above this, allow switching
float henrique3SilhouetteThreshold = 120; // wider threshold for full silhouette

// Initialize frames and font once (lazy-loaded from draw)
void initHenrique3() {
    henrique3Frames = new PImage[HENRIQUE3_FRAME_COUNT];

    for (int i = 0; i < HENRIQUE3_FRAME_COUNT; i++) {
        int frameNumber = i; // frames are 0..22
        String frameLabel = nf(frameNumber, 2); // 00..22
        // Load from sketch root frames folder (frame00.gif..frame22.gif)
        PImage img = loadImage(sketchPath("data/frame" + frameLabel + ".gif"));
        if (img != null) {
            img.resize(HENRIQUE3_TARGET_W, HENRIQUE3_TARGET_H); // normalize size
        }
        henrique3Frames[i] = img;
    }

    // Monospaced font for stable ASCII grid
    henrique3Font = createFont("Courier", henrique3CharSize, true);

    henrique3Ready = true;
}

// Convert a PImage to ASCII and render into a PGraphics buffer
void renderAscii(PGraphics pg, PImage img) {
    if (img == null) {
        return;
    }

    img.loadPixels();

    pg.beginDraw();
    pg.background(0); // pure black, no background text
    pg.textFont(henrique3Font);
    pg.textAlign(LEFT, TOP);
    pg.colorMode(HSB, 360, 100, 100, 255);
    pg.fill(lockedHue, lockedSat, lockedBri, 230);
    pg.noStroke();

    // Silhouette grid size based on resized image
    int silCols = max(1, img.width / henrique3CharW);
    int silRows = max(1, img.height / henrique3CharH);

    // Center horizontally and align bottom to the window edge
    int startX = (pg.width - silCols * henrique3CharW) / 2;
    int startY = pg.height - silRows * henrique3CharH;

    float stepX = img.width / float(silCols);
    float stepY = img.height / float(silRows);

    // Only draw ASCII where the black silhouette is detected
    for (int y = 0; y < silRows; y++) {
        int py = int(y * stepY);
        for (int x = 0; x < silCols; x++) {
            int px = int(x * stepX);
            int idx = py * img.width + px;
            int c = img.pixels[idx];
            float b = brightness(c); // 0..100 in Processing

            if (b >= henrique3SilhouetteThreshold) {
                int gx = startX + x * henrique3CharW;
                int gy = startY + y * henrique3CharH;
                float mouseDist = dist(mouseX, mouseY, gx, gy);
                float clampedB = constrain(b, 0, 255);
                int rampIndex = int(map(clampedB, 0, 255, 0, ASCII_RAMP.length() - 1));
                rampIndex = constrain(rampIndex, 0, ASCII_RAMP.length() - 1);
                char glyph = ASCII_RAMP.charAt(rampIndex);
                if (mouseDist <= henrique3HoverRadius) {
                    float boost = map(mouseDist, 0, henrique3HoverRadius, 100, 30);
                    pg.fill(lockedHue, lockedSat, min(100, lockedBri + boost), 255);
                    glyph = ASCII_RAMP.charAt(int(random(ASCII_RAMP.length())));
                } else {
                    pg.fill(lockedHue, lockedSat, lockedBri, 230);
                }
                pg.text(glyph, gx, gy);
            }
        }
    }
    pg.colorMode(RGB, 255, 255, 255, 255);
    pg.endDraw();
}

// Audio-driven frame update
void updateHenrique3Frame(float amp, boolean beat) {
    // If music is silent, keep the current frame (pause)
    if (amp < henrique3SilenceThreshold) {
        return;
    }

    // Only advance on beat or strong spike, with debounce
    int now = millis();
    if ((beat || amp >= henrique3SpikeThreshold) && (now - henrique3LastSwitchMs) >= henrique3MinSwitchIntervalMs) {
        henrique3FrameIndex = (henrique3FrameIndex + 1) % HENRIQUE3_FRAME_COUNT;
        henrique3LastSwitchMs = now;
    }
}

void drawHenrique3(PGraphics pg, float amp, boolean beat){
    if (!henrique3Ready) {
        initHenrique3();
    }

    updatePalette();

    updateHenrique3Frame(amp, beat);

    PImage current = henrique3Frames[henrique3FrameIndex];
    renderAscii(pg, current);
}