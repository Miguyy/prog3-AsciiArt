/*
  Propósito:
    Camada orgânica de arte ASCII baseada em 'blobs' que se movem para cima;
    o blob principal segue o rato e expande com o áudio e batidas; blobs de
    background flutuam para cima com variações de raio. A grelha usa SDF para
    formas suaves e ruído para deslocamentos fluidos.

  Variáveis principais:
    - m2DensityChars: caracteres ordenados por densidade.
    - m2Blobs, m2BasePos, m2BaseRadius, m2Radius: dados dos blobs e raios.
    - m2CellSize, m2Smoothness: parâmetros da grelha e suavidade da união SDF.
    - m2WaveYTime, m2BeatPulse: tempo da onda e pulso de batida.
    - m2Font: fonte monoespaçada usada para desenhar os caracteres.

  Funções expostas:
    - initMiguel2() — inicializa blobs e fontes.
    - drawMiguel2(PGraphics pg, float amplitude, boolean beatDetected) — render principal.
    - sdCircle(), opSmoothUnion() — utilitárias SDF.
    - miguelLayer2KeyPressed() — handler para 'r' (randomizar blobs).

  Uso da paleta:
    - Fundo: `palette[3]`; cores de glyph usam `palette[5]`, `palette[8]` e `palette[2]` consoante intensidade.

  Controlo / Keys:
    - 'r' → randomizar posições e raios dos blobs de fundo.
*/

// 1. Configuração: caracteres ASCII e parâmetros de grelha
char[] m2DensityChars = new char[]{'.', ',', '*', 'x', '#', '1', '0', '░', '='};
PVector[] m2Blobs;         // centros dos 'blobs' (índice 0 = blob controlado pelo rato)
float[] m2BaseRadius;      // raios base para cada blob
float[] m2Radius;          // raios dinâmicos (animados)
PVector[] m2BasePos;       // posições base para os blobs de fundo
int m2BlobCount = 4;       // número total de blobs (0 = rato, 1.. = fundo)

// Dimensão da célula ASCII: maior → melhor performance, menor → mais detalhe
float m2CellSize = 16;
float m2Smoothness = 200.0; // suavidade da união SDF para fusão orgânica

// Variáveis de tempo/áudio para conduzir o movimento ascendente
float m2WaveYTime = 0.0;
// Pulso curto gerado por deteção de batida para efeitos visuais
float m2BeatPulse = 0.0;

PFont m2Font;

// Inicializar dados dos blobs (um segue o rato, os outros flutuam)
void initMiguel2() {
  m2Blobs = new PVector[m2BlobCount];
  m2BasePos = new PVector[m2BlobCount];
  m2BaseRadius = new float[m2BlobCount];
  m2Radius = new float[m2BlobCount];
  for(int i = 0; i < m2BlobCount; i++) {
    m2Blobs[i] = new PVector(random(width), random(height));
    m2BasePos[i] = m2Blobs[i].copy();
    // Raios base grandes para boa leitura visual
    m2BaseRadius[i] = random(120, 160);
    m2Radius[i] = m2BaseRadius[i];
  }
  m2Font = createFont("Courier", m2CellSize);
}

void drawMiguel2(PGraphics pg, float amplitude, boolean beatDetected) {
  if (m2Blobs == null) initMiguel2();

  // 2. Reacção ao áudio: obter espectro
  float[] spec = new float[512];
  if (fft != null) fft.analyze(spec);

  // Energia em altas frequências controla velocidade/expansão
  float hi = 0;
  if (fft != null) {
    int start = int(spec.length * 0.5);
    for (int i = start; i < spec.length; i++) hi += spec[i];
    hi /= max(1, spec.length - start);
  } else {
    hi = amplitude * 0.5;
  }

  // Pulso breve quando detecta batida
  if (beatDetected) {
    m2BeatPulse = 1.0;
  }
  m2BeatPulse *= 0.92; // decaimento do pulso

  // Mapear 'hi' para velocidade da onda vertical
  float minSpeed = 0.02;
  float maxSpeed = 0.28;
  float currentWaveSpeed = map(hi, 0, 0.2, minSpeed, maxSpeed);
  currentWaveSpeed = constrain(currentWaveSpeed, minSpeed, maxSpeed);
  m2WaveYTime += currentWaveSpeed;

  // Parâmetros de modulação da onda
  float waveFreq = map(hi, 0, 0.2, 0.006, 0.06);
  float waveAmp = map(amplitude, 0, 0.5, 0.0, 0.9);
  float t = millis() / 1000.0;

  // Blob 0 segue o rato com influência áudio
  m2Blobs[0].x = lerp(m2Blobs[0].x, mouseX, 0.32);
  m2Blobs[0].y = lerp(m2Blobs[0].y, mouseY - map(hi, 0, 0.2, -80, 140), 0.5);

  // Expansão do blob do rato em função do áudio e batida
  float mouseTarget = m2BaseRadius[0] * (1.0 + hi * 6.0 + amplitude * 2.0 + m2BeatPulse * 1.2);
  m2Radius[0] = lerp(m2Radius[0], mouseTarget, 0.5);
  m2Radius[0] = constrain(m2Radius[0], 60, 420);

  // Atualizar blobs de fundo: movem-se para cima e variam de raio
  for (int i = 1; i < m2BlobCount; i++){
    float x = m2BasePos[i].x + (noise(t * 0.3 + i * 5) - 0.5) * 120;
    float baseY = m2BasePos[i].y + (noise(t * 0.2 + i * 12) - 0.5) * 100;
    m2Blobs[i].x = (x % width + width) % width;
    m2Blobs[i].y = ( (baseY - currentWaveSpeed * (18.0 + hi * 220.0)) % height + height) % height;
    float wave = sin((m2Blobs[i].y * waveFreq * TWO_PI) + t * (0.5 + hi * 3) + i);
    float targetRadius = m2BaseRadius[i] * (1.0 + wave * waveAmp + (hi * 2.4));
    m2Radius[i] = lerp(m2Radius[i], targetRadius, 0.22);
    m2Radius[i] = constrain(m2Radius[i], 60, 420);
  }

  pg.beginDraw();
  pg.background(palette[3]); // fundo base usando a cor 4 da paleta
  pg.textFont(m2Font);
  pg.textAlign(CENTER, CENTER);

  // 4. Desenhar grelha ASCII com deslocamento por ruído + SDF
  float s = 0.01; // escala de resolução para deslocamentos mais suaves

  for (float y = 0; y < height; y += m2CellSize) {
    for (float x = 0; x < width; x += m2CellSize) {
      float sampleX = x * s;
      float sampleY = (y * s) + m2WaveYTime;
      float flowOffsetX = (noise(sampleX, sampleY, 0.0) - 0.5) * 48.0;
      float flowOffsetY = (noise(sampleX + 100.0, sampleY, 7.7) - 0.5) * 48.0;
      PVector distortedPos = new PVector(x + flowOffsetX, y + flowOffsetY);
      float d = sdCircle(distortedPos, m2Blobs[0], m2Radius[0]);
      for(int i = 1; i < m2Blobs.length; i++) {
        float d2 = sdCircle(distortedPos, m2Blobs[i], m2Radius[i]);
        d = opSmoothUnion(d, d2, m2Smoothness);
      }
      float c = 1.0 - exp(-0.01 * max(0, d));
      if (d < 0) c = 0;
      c = constrain(c + m2BeatPulse * 0.12, 0, 1);
      int index = floor(c * (m2DensityChars.length - 1));
      index = constrain(index, 0, m2DensityChars.length - 1);
      char letter = m2DensityChars[index];
      color col;
      if (c < 0.1) {
        col = palette.length > 5 ? palette[5] : color(39,198,237);
      } else if (c < 0.4) {
        col = lerpColor(palette.length > 5 ? palette[5] : color(39,198,237), palette[8], map(c, 0.1, 0.4, 0, 1));
      } else {
        col = lerpColor(palette[8], palette.length > 2 ? palette[2] : color(33,1,16), map(c, 0.4, 1.0, 0, 1));
      }
      pg.fill(col);
      pg.text(letter, x, y);
    }
  }
  pg.endDraw();
}

// --- Funções utilitárias SDF ---

// Calcula distância assinalável entre um ponto e um círculo (Signed Distance)
float sdCircle(PVector p, PVector center, float r) {
  return dist(p.x, p.y, center.x, center.y) - r;
}

// União suave (smin) para fundir formas de forma orgânica
float opSmoothUnion(float d1, float d2, float k) {
  float h = constrain(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
  return lerp(d2, d1, h) - k * h * (1.0 - h);
}

// 6. Interacção da layer via teclado
void miguelLayer2KeyPressed() {
  // 'r' → randomizar posições e raios dos blobs de fundo
  if (key == 'r' || key == 'R') {
    if (m2Blobs != null) {
      for(int i = 0; i < m2Blobs.length; i++) {
        float bx = random(width);
        float by = random(height);
        m2BasePos[i].set(bx, by);
        m2Blobs[i].set(bx, by);
        m2BaseRadius[i] = random(160, 260);
        m2Radius[i] = m2BaseRadius[i];
      }
    }
  }
}