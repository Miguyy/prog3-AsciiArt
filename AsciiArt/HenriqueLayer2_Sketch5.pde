// Henrique layer 2: segmented particle ring with pseudo-3D tilt
// Uses the global Processing Sound FFT defined in Audio.pde

// Audio analysis
int bassBins = 12; // number of low-frequency bins to average

// Ring configuration
RingTunnel tunnel;
float ringPulse = 0.0;
float ringPulseTarget = 0.0;
float ringPulseSmooth = 0.12;

void drawHenrique2(PGraphics pg, float amp, boolean beat) {
    if (tunnel == null) {
        tunnel = new RingTunnel(width * 0.5, height * 0.5);
    }

    updatePalette();

    float bassEnergy = 0.0;
    for (int i = 0; i < bassBins && i < fft.spectrum.length; i++) {
        bassEnergy += fft.spectrum[i];
    }
    bassEnergy /= max(1, min(bassBins, fft.spectrum.length));

    float ampBoost = map(amp, 0, 0.4, 0.0, 0.4);
    ringPulseTarget = constrain(map(bassEnergy, 0, 0.2, 0.0, 1.0) + ampBoost, 0.0, 1.0);
    ringPulse = lerp(ringPulse, ringPulseTarget, ringPulseSmooth);

    pg.beginDraw();
    pg.clear();
    pg.colorMode(HSB, 360, 100, 100, 255);

    tunnel.update(ringPulse, bassEnergy, beat, ampBoost);
    tunnel.draw(pg);

    pg.colorMode(RGB, 255, 255, 255, 255);
    pg.endDraw();
}

class RingTunnel {
    float cx;
    float cy;
    int ringCount = 8;
    float minRadius = 8.0;
    float maxRadius = 0.0;
    float baseThickness = 44.0;
    float tilt = 0.55; // ellipse squash (0.45-0.7 gives a nice tilt)
    float depthFade = 0.65;
    float depthResponse = 0.08;

    SolidRing[] rings;

    RingTunnel(float x, float y) {
        cx = x;
        cy = y;
        maxRadius = min(width, height) * 0.85;
        rings = new SolidRing[ringCount];
        for (int i = 0; i < ringCount; i++) {
            float progress = i / float(ringCount);
            rings[i] = new SolidRing(progress);
        }
    }

    void update(float pulse, float bassEnergy, boolean beat, float ampBoost) {
        float pumpScale = lerp(0.85, 1.25, pulse);
        float targetDepth = constrain(map(bassEnergy, 0, 0.2, 0.15, 0.95) + ampBoost * 0.4, 0.0, 1.0);
        float beatKick = beat ? 0.06 : 0.0;
        targetDepth = constrain(targetDepth + beatKick, 0.0, 1.0);

        for (int i = 0; i < rings.length; i++) {
            rings[i].update(targetDepth, depthResponse, pulse, minRadius, maxRadius, baseThickness, tilt, depthFade, beat, pumpScale);
        }
    }

    void draw(PGraphics pg) {
        for (int i = 0; i < rings.length; i++) {
            rings[i].draw(pg, cx, cy);
        }
    }
}

class SolidRing {
    float progress;
    float baseOffset;
    int speckCount = 420;
    Speck[] specks;

    float currentRadius;
    float currentThickness;
    float currentTilt;
    float currentFade;
    float ringFade;
    float currentDepth;

    SolidRing(float initialProgress) {
        progress = initialProgress;
        baseOffset = initialProgress;
        specks = new Speck[speckCount];
        for (int i = 0; i < specks.length; i++) {
            specks[i] = new Speck();
        }
    }

    void update(float targetDepth, float response, float pulse, float minRadius, float maxRadius, float baseThickness, float tilt, float fade, boolean beat, float pumpScale) {
        float desired = targetDepth + baseOffset - 0.5;
        if (desired > 1.0) {
            desired -= 1.0;
        }
        if (desired < 0.0) {
            desired += 1.0;
        }
        progress = lerp(progress, desired, response);

        float depthCurve = pow(progress, 1.6);
        float radius = lerp(minRadius, maxRadius, depthCurve) * pumpScale;
        float thickness = (baseThickness + lerp(0.0, 32.0, depthCurve)) * lerp(0.9, 1.1, pulse);

        float fadeIn = smoothStep(0.02, 0.18, progress);
        float fadeOut = 1.0 - smoothStep(0.65, 0.85, progress);
        ringFade = fadeIn * fadeOut;

        currentRadius = radius;
        currentThickness = thickness;
        currentTilt = tilt;
        currentFade = fade;
        currentDepth = depthCurve;

        for (int i = 0; i < specks.length; i++) {
            specks[i].update(beat);
        }
    }

    void draw(PGraphics pg, float cx, float cy) {
        float outlineAlpha = lerp(70, 210, currentDepth) * ringFade;
        float fillAlpha = lerp(80, 220, currentDepth) * ringFade;
        float extrusion = lerp(1.0, 14.0, currentDepth);

        float outerRadius = currentRadius + currentThickness;

        pg.noFill();
        pg.stroke(lockedHue, 90, 100, outlineAlpha);
        pg.strokeWeight(2.0);
        pg.ellipse(cx, cy, outerRadius * 2.0, outerRadius * 2.0 * currentTilt);
        pg.ellipse(cx, cy, currentRadius * 2.0, currentRadius * 2.0 * currentTilt);

        pg.stroke(lockedHue, 90, 100, outlineAlpha * 0.7);
        pg.ellipse(cx, cy - extrusion, outerRadius * 2.0, outerRadius * 2.0 * currentTilt);
        pg.ellipse(cx, cy - extrusion, currentRadius * 2.0, currentRadius * 2.0 * currentTilt);

        for (int i = 0; i < specks.length; i++) {
            specks[i].draw(pg, cx, cy, currentRadius, currentThickness, currentTilt, fillAlpha, currentFade, -extrusion);
        }
    }

    void arcStrip(PGraphics pg, float cx, float cy, float rInner, float rOuter, float startA, float endA, float tilt, float yOffset) {
        int steps = 32;
        for (int i = 0; i <= steps; i++) {
            float t = i / float(steps);
            float a = lerp(startA, endA, t);
            pg.vertex(cx + cos(a) * rOuter, cy + sin(a) * rOuter * tilt + yOffset);
        }
        for (int i = steps; i >= 0; i--) {
            float t = i / float(steps);
            float a = lerp(startA, endA, t);
            pg.vertex(cx + cos(a) * rInner, cy + sin(a) * rInner * tilt + yOffset);
        }
    }

}

class Speck {
    float radial01;
    float angle01;
    float life;
    float angularSpeed;
    float radialSpeed;

    Speck() {
        reset();
    }

    void reset() {
        radial01 = random(0.0, 1.0);
        angle01 = random(0.0, 1.0);
        life = random(0.4, 1.0);
        angularSpeed = random(-0.008, 0.012);
        radialSpeed = random(-0.004, 0.006);
    }

    void update(boolean beat) {
        float boost = beat ? 1.6 : 1.0;
        angle01 += angularSpeed * boost;
        radial01 += radialSpeed * boost;
        life -= 0.006 * boost;

        if (angle01 > 1.0) {
            angle01 -= 1.0;
        }
        if (angle01 < 0.0) {
            angle01 += 1.0;
        }

        if (radial01 > 1.0) {
            radial01 -= 1.0;
        }
        if (radial01 < 0.0) {
            radial01 += 1.0;
        }

        if (life <= 0.0) {
            reset();
        }
    }

    void draw(PGraphics pg, float cx, float cy, float r, float thickness, float tilt, float alpha, float fade, float yOffset) {
        float a = angle01 * TWO_PI;
        float rr = r + radial01 * thickness;
        float z = radial01;
        float aFade = lerp(alpha, alpha * fade, z);
        float depthOffset = lerp(yOffset, 0.0, radial01);

        pg.noStroke();
        pg.fill(lockedHue, lockedSat, lockedBri, aFade);
        pg.ellipse(cx + cos(a) * rr, cy + sin(a) * rr * tilt + depthOffset, 1.6, 1.6);
    }
}

float smoothStep(float edge0, float edge1, float x) {
    float t = constrain((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}
