/*
    Propósito:
        Desenhar um toro ASCII numa grelha rígida com shading por iluminação,
        reagindo ao áudio para rotação e pulsação. Usa a análise de áudio existente
        para conduzir o movimento e integra-se com a paleta dinâmica.
*/

// Rampa de densidade ASCII para iluminação
String densityRamp = ".,-~:;=!*#$@";

// Configuração da grelha rígida
int cellSize = 16;
int gridCols = 0;
int gridRows = 0;

// Parâmetros do toro (anel fino)
float torusR = 0.7;   // major radius (smaller)
float torusr = 0.2;   // minor radius (thin)

// Estado de rotação
float rotA = 0.0;
float rotB = 0.0;
float rotVelA = 0.02;
float rotVelB = 0.015;

// Buffers de profundidade para a grelha ASCII
float[] zBuffer;
int[] shadeBuffer;

void ensureGrid(PGraphics pg) {
    int newCols = pg.width / cellSize;
    int newRows = pg.height / cellSize;
    if (newCols != gridCols || newRows != gridRows) {
        gridCols = newCols;
        gridRows = newRows;
        zBuffer = new float[gridCols * gridRows];
        shadeBuffer = new int[gridCols * gridRows];
    }
}

void clearGrid() {
    for (int i = 0; i < zBuffer.length; i++) {
        zBuffer[i] = -1e9;
        shadeBuffer[i] = 0;
    }
}

void drawHenrique2(PGraphics pg, float amp, boolean beat) {
    updatePalette();
    ensureGrid(pg);
    clearGrid();

    // Rotação e pulsação conduzidas pelo áudio
    float audioVolume = constrain(amp, 0.0, 1.0);
    float beatKick = beat ? 0.04 : 0.0;
    rotVelA = lerp(rotVelA, 0.02 + audioVolume * 0.08 + beatKick, 0.15);
    rotVelB = lerp(rotVelB, 0.015 + audioVolume * 0.06 + beatKick, 0.15);
    rotA += rotVelA;
    rotB += rotVelB;

    float pulse = 1.0 + audioVolume * 0.22 + (beat ? 0.08 : 0.0);
    float R = torusR * pulse;
    float r = torusr * pulse; // anel fino mantem-se fino

    // Pré-cálculo de senos/cossenos da rotação
    float cosA = cos(rotA);
    float sinA = sin(rotA);
    float cosB = cos(rotB);
    float sinB = sin(rotB);

    // Projetar pontos do toro na grelha ASCII rígida
    for (float theta = 0.0; theta < TWO_PI; theta += 0.12) {
        float cosT = cos(theta);
        float sinT = sin(theta);
        for (float phi = 0.0; phi < TWO_PI; phi += 0.04) {
            float cosP = cos(phi);
            float sinP = sin(phi);

            // Ponto da superfície do toro no espaço do objeto
            float circle = R + r * cosT;
            float x = circle * cosP;
            float y = circle * sinP;
            float z = r * sinT;

            // Rodar em 3D
            float x1 = x;
            float y1 = y * cosA - z * sinA;
            float z1 = y * sinA + z * cosA;

            float x2 = x1 * cosB + z1 * sinB;
            float y2 = y1;
            float z2 = -x1 * sinB + z1 * cosB;

            // Projeção em perspetiva para coordenadas da grelha
            float depth = 2.8 + z2;
            float invDepth = 1.0 / depth;
            float projX = x2 * invDepth;
            float projY = y2 * invDepth;

            int col = int((projX * 0.95 + 0.5) * gridCols);
            int row = int((projY * 0.95 + 0.5) * gridRows);
            if (col < 0 || col >= gridCols || row < 0 || row >= gridRows) {
                continue;
            }

            // Normal da superfície para shading ASCII
            float nx = cosP * cosT;
            float ny = sinP * cosT;
            float nz = sinT;

            // Rodar a normal (igual ao ponto, sem translação)
            float ny1 = ny * cosA - nz * sinA;
            float nz1 = ny * sinA + nz * cosA;
            float nx2 = nx * cosB + nz1 * sinB;
            float ny2 = ny1;
            float nz2 = -nx * sinB + nz1 * cosB;

            // Direção de luz simples
            float light = nx2 * 0.2 + ny2 * 0.6 + nz2 * 0.7;
            int shade = int(map(light, -1.0, 1.0, 0, densityRamp.length() - 1));
            shade = constrain(shade, 0, densityRamp.length() - 1);

            int idx = row * gridCols + col;
            if (invDepth > zBuffer[idx]) {
                zBuffer[idx] = invDepth;
                shadeBuffer[idx] = shade;
            }
        }
    }

    pg.beginDraw();
    pg.clear();
    pg.colorMode(RGB, 255, 255, 255, 255);
    pg.textAlign(CENTER, CENTER);
    pg.textSize(cellSize * 0.9);

    color baseCol = paletteBlend(palettePhase);
    color beatCol = paletteBlend(palettePhase + 0.8);

    // Render da matriz ASCII rígida (células mapeadas para centros exatos)
    for (int row = 0; row < gridRows; row++) {
        for (int col = 0; col < gridCols; col++) {
            int idx = row * gridCols + col;
            if (zBuffer[idx] <= -1e8) continue;

            char glyph = densityRamp.charAt(shadeBuffer[idx]);
            int x = col * cellSize + cellSize / 2;
            int y = row * cellSize + cellSize / 2;
            pg.fill(beat ? beatCol : baseCol, 230);
            pg.text(glyph, x, y);
        }
    }
    pg.endDraw();
}
