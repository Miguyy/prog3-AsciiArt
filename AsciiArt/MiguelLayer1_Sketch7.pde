/*
    Propósito:
    - Desenhra uma grelha de caracteres ASCII em `PGraphics`, com linhas alternadas
        para criar movimento visual.
    - A animação é conduzida pelo analisador FFT e pela amplitude global, e
        responde a batidas (flag `beat`) para variações de cor/ritmo.
    - Suporta apagamento (wipe) por linha: pedidos manuais com 'e', modo
        auto-sequencial com 'E' e reset com 'r'. O estado apagado é cacheado por
        célula para persistência entre frames.
    - Ajusta dinamicamente o tamanho da fonte e o layout (colunas/linhas) quando
        a dimensão do `PGraphics` muda, para manter a legibilidade.
    - Integrado com o sketch principal (`AsciiArt.pde`): a função
        `drawMiguel1(PGraphics, float, boolean)` é chamada por `draw()` e o
        `miguelLayer1KeyPressed()` é invocado a partir de `keyPressed()`.
*/

// Mapa de caracteres utilizados na grelha ASCII
String ML7_chars = "'.', ',', '*', 'x', '#', '1', '0', '░', '='";
PFont ML7_font = null;        // fonte monoespaçada para desenhar os carateres
int ML7_fontSize = 28;        // tamanho da fonte (ajustado dinamicamente)
int ML7_cachedW = -1;         // largura em cache para re-criar a fonte quando muda
int ML7_cachedH = -1;         // altura em cache para re-criar a fonte quando muda

// Buffer reutilizável para análise FFT
float[] ML7_spectrum = new float[512];

// Estado de apagamento (erase/wipe)
boolean ML7_erasing = false;
int ML7_targetRow = -1;       // linha actual a apagar
int ML7_eraseProgress = 0;    // progresso de apagar em colunas
int ML7_eraseDir = 1;         // 1 = esquerda→direita, -1 = direita→esquerda
int ML7_pendingErase = 0;     // número de pedidos de 'e' pendentes
int ML7_nextEraseRow = 0;     // próxima linha a apagar quando em modo sequencial

// Controlo de auto-apagamento
boolean ML7_autoEraseMode = false;
int ML7_delayBetweenRows = 6; // frames a esperar entre linhas em modo auto
int ML7_delayCounter = 0;

// Cache do estado apagado (rows x cols) — reatribuído quando o layout muda
int ML7_cachedCols = -1;
int ML7_cachedRows = -1;
boolean[][] ML7_erased = null;

void drawMiguel1(PGraphics pg, float amp, boolean beat){
    pg.beginDraw();

    // Usar a paleta do projeto para fundo e texto quando disponível
    color bgCol = (palette != null && palette.length > 3) ? palette[3] : color(4, 8, 19);
    color textCol = (palette != null && palette.length > 5) ? palette[5] : color(39, 198, 237);
    pg.background(bgCol);

    // Criação preguiçosa (lazy) da fonte e cache — só quando as dimensões mudam
    if (ML7_font == null || ML7_cachedW != pg.width || ML7_cachedH != pg.height){
        ML7_fontSize = 16; // tamanho inicial para ajustar
        ML7_font = createFont("Courier", ML7_fontSize);
        pg.textFont(ML7_font);
        float leftMargin = 4;
        float rightMargin = 4;
        float targetWidth = pg.width - leftMargin - rightMargin;
        // reduzir o tamanho da fonte até caber o número desejado de colunas
        int desiredCols = 42;
        while (ML7_fontSize > 6) {
            ML7_font = createFont("Courier", ML7_fontSize);
            pg.textFont(ML7_font);
            float cw = pg.textWidth("W");
            if (cw * desiredCols <= targetWidth) break;
            ML7_fontSize -= 1;
        }
        // guardar dimensões em cache
        ML7_cachedW = pg.width;
        ML7_cachedH = pg.height;
    } else {
        pg.textFont(ML7_font);
    }

    // Métricas de layout
    float leftMargin = 4;
    float topMargin = 4;
    float rightMargin = 4;
    float targetWidth = pg.width - leftMargin - rightMargin;
    float charW = pg.textWidth("W");
    float lineH = ML7_fontSize * 1.05;

    int cols = max(1, int(targetWidth / max(1, charW)));
    int rows = max(1, int((pg.height - topMargin) / lineH));

    // Garantir que o buffer de estado apagado corresponde ao layout atual
    if (cols != ML7_cachedCols || rows != ML7_cachedRows || ML7_erased == null){
        ML7_cachedCols = cols;
        ML7_cachedRows = rows;
        ML7_erased = new boolean[rows][cols];
        // inicializar a falso
        for (int ry = 0; ry < rows; ry++){
            for (int rx = 0; rx < cols; rx++) ML7_erased[ry][rx] = false;
        }
    }

    // Alinhar texto ao canto superior-esquerdo para que os carateres formem uma grelha
    pg.textAlign(LEFT, TOP);

    // Velocidade de animação influenciada pelo espectro de frequências
    if (fft != null) {
        fft.analyze(ML7_spectrum);
    }
    int sStart = 2;
    int sEnd = 40;
    float sum = 0;
    for (int i = sStart; i < sEnd && i < ML7_spectrum.length; i++) sum += ML7_spectrum[i];
    float freqEnergy = sum / max(1, sEnd - sStart);
    // reduzir velocidade base: só acelerar significativamente quando há energia
    float speed;
    if (freqEnergy < 0.02) speed = 0.45;
    else speed = map(freqEnergy, 0.02, 0.25, 0.6, 3.0);
    speed = constrain(speed, 0.2, 4.0);
    // modular ligeiramente com amplitude geral
    speed *= (1.0 + amp * 0.8);
    speed = constrain(speed, 0.2, 6.0);
    int foffset = int(frameCount * speed);
    int l = ML7_chars.length();

    for (int y = 0; y < rows; y++){
        for (int x = 0; x < cols; x++){
            int idx;
            // Se a linha está a ser apagada, saltar as colunas já apagadas
            if (ML7_erasing && y == ML7_targetRow){
                if (ML7_eraseDir == -1){
                    if (x >= cols - ML7_eraseProgress) continue;
                } else {
                    if (x < ML7_eraseProgress) continue;
                }
            }
            // saltar células permanentemente apagadas
            if (ML7_erased != null && ML7_erased[y][x]) continue;
            if ((y % 2) != 0) idx = (y + x + foffset) % l;
            else idx = (y + cols - x + foffset) % l;
            char c = ML7_chars.charAt(idx);
            float px = leftMargin + x * charW;
            float py = topMargin + y * lineH;

            // Cor por omissão
            color drawCol = textCol;
            // Quando há energia nas frequências, escolher cor da paleta para cada carater
            if (freqEnergy > 0.06 && palette != null && palette.length > 5){
                int startIdx = min(5, palette.length-1);
                int paletteRange = palette.length - startIdx;
                if (paletteRange > 0){
                    int shift = beat ? 1 : 0;
                    int pick = startIdx + ((abs(idx) + shift) % paletteRange);
                    pick = constrain(pick, 0, palette.length-1);
                    drawCol = palette[pick];
                }
            }

            pg.fill(drawCol);
            pg.text(c, px, py);
        }
    }

    // Iniciar apagamento se houver pedidos pendentes ou se estiver em modo auto
    if (!ML7_erasing){
        if (ML7_pendingErase > 0){
            ML7_pendingErase -= 1;
            ML7_erasing = true;
            ML7_targetRow = ML7_nextEraseRow % max(1, rows);
            ML7_eraseProgress = 0;
            ML7_eraseDir = (ML7_targetRow % 2 == 0) ? -1 : 1; // linha par → direita→esquerda
            ML7_delayCounter = 0;
        } else if (ML7_autoEraseMode && ML7_delayCounter <= 0){
            ML7_erasing = true;
            ML7_targetRow = ML7_nextEraseRow % max(1, rows);
            ML7_eraseProgress = 0;
            ML7_eraseDir = (ML7_targetRow % 2 == 0) ? -1 : 1;
            ML7_delayCounter = 0;
        }
    }

    // Avançar o progresso de apagamento quando activo
    if (ML7_erasing){
        int minStep = 1;
        int maxStep = max(1, int(cols * 0.6));
        int step = int(map(freqEnergy, 0.0, 0.25, minStep, maxStep));
        step = constrain(step, minStep, maxStep);
        ML7_eraseProgress += step;
        if (ML7_eraseProgress >= cols){
            // terminar esta linha — marcar como permanentemente apagada
            if (ML7_targetRow >= 0 && ML7_targetRow < rows && ML7_erased != null){
                for (int rx = 0; rx < cols; rx++) ML7_erased[ML7_targetRow][rx] = true;
            }
            ML7_erasing = false;
            ML7_eraseProgress = 0;
            ML7_nextEraseRow = (ML7_nextEraseRow + 1) % max(1, rows);
            if (ML7_autoEraseMode) ML7_delayCounter = ML7_delayBetweenRows;
        }
    } else {
        if (ML7_delayCounter > 0) ML7_delayCounter -= 1;
    }

    pg.endDraw();
}

// key handler invoked from AsciiArt.pde keyPressed() via try/catch
void miguelLayer1KeyPressed(){
    // lowercase 'e' → trigger a single-row erase; uppercase 'E' → toggle auto-sequential erase
    if (key == 'e'){
        ML7_pendingErase += 1;
    } else if (key == 'E'){
        ML7_autoEraseMode = !ML7_autoEraseMode;
        if (ML7_autoEraseMode){
            ML7_nextEraseRow = 0;
            ML7_pendingErase = 0;
            ML7_delayCounter = 0;
            ML7_erasing = false;
        }
    } else if (key == 'r' || key == 'R'){
        // restart: clear erased-state and stop auto mode
        if (ML7_erased != null){
            for (int ry = 0; ry < ML7_erased.length; ry++){
                for (int rx = 0; rx < ML7_erased[ry].length; rx++) ML7_erased[ry][rx] = false;
            }
        }
        ML7_nextEraseRow = 0;
        ML7_pendingErase = 0;
        ML7_autoEraseMode = false;
        ML7_erasing = false;
    }
}