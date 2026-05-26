/*
  Propósito:
    Projeção 3D de um cubo em grelha ASCII; desenha vértices e arestas como
    caracteres numa grelha, com rotação controlada pelo rato e reatividade ao áudio.

  Variáveis principais:
    - tamFonte3, numColunas3, numLinhas3, fonte3: parâmetros de grelha e fonte.
    - anguloX, anguloY, distanciaCamara: estado da câmara/projeção.
    - arestas: ligação entre vértices para desenhar linhas.

  Funções expostas:
    - drawPetunia3(PGraphics pg, float amplitude, boolean batida)
    - projetarVertices(PGraphics pg, float s)
    - desenharGrelha(PGraphics pg)
    - desenharArestas(PGraphics pg)

  Uso da paleta:
    - `palette[3]` para fundo; `palette[8]` e `palette[2]` para vértices/arestas.

  Controlo / Keys:
    - interação por rato (posicionamento da rotação através de `mouseX/mouseY`).
*/

// --- CONFIGURAÇÃO GERAL ---

int tamFonte3 = 16;
int numColunas3, numLinhas3;
PFont fonte3;

char[] characters3 = {'.', ',', '*', 'x', '#', '1', '0', '░', '='};

// --- ESTADO DA CÂMARA E PROJEÇÃO ---

float anguloX = 0;
float anguloY = 0;
float distanciaCamara = 300;
float[][] verticesEcra = new float[8][2]; // Posições 2D dos 8 vértices do cubo


// --- ARESTAS DO CUBO ---
// Cada par é o índice de dois vértices ligados por uma aresta

int[][] arestas = {
  {0,1},{0,2},{0,3},
  {7,4},{7,5},{7,6},
  {1,4},{1,6},
  {2,4},{2,5},
  {3,5},{3,6}
};

void drawPetunia3(PGraphics pg, float amplitude, boolean batida) {

  if (fonte3 == null) {
    fonte3      = createFont("Courier", tamFonte3);
    numColunas3 = pg.width  / tamFonte3;
    numLinhas3  = pg.height / tamFonte3;
  }

  pg.beginDraw();
  pg.background(palette[3]);
  pg.textFont(fonte3);
  pg.textSize(tamFonte3);
  pg.textAlign(CENTER, CENTER);

  float tamanho = 100 + (amplitude * 50) + (batida ? 5 : 0);

  projetarVertices(pg, tamanho);
  desenharGrelha(pg);
  desenharArestas(pg);

  pg.endDraw();
}


// --- PROJEÇÃO 2D ---

// Roda os 8 vértices do cubo e projeta-os no ecrã
void projetarVertices(PGraphics pg, float s) {

  anguloX = map(mouseY, 0, pg.height, -PI, PI);
  anguloY = map(mouseX, 0, pg.width,  -PI, PI);

  // Os 8 cantos do cubo (em cada eixo)
  float[][] vertices = {
    { s,  s,  s}, { s, -s,  s}, { s,  s, -s}, {-s,  s,  s},
    { s, -s, -s}, {-s,  s, -s}, {-s, -s,  s}, {-s, -s, -s}
  };

  for (int i = 0; i < 8; i++) {
    float x = vertices[i][0];
    float y = vertices[i][1];
    float z = vertices[i][2];

    // Rotação em Y (esquerda/direita com o rato)
    float x1 =  x * cos(anguloY) - z * sin(anguloY);
    float z1 =  x * sin(anguloY) + z * cos(anguloY);

    // Rotação em X (cima/baixo com o rato)
    float y2 = y * cos(anguloX) + z1 * sin(anguloX);
    float z2 = -y * sin(anguloX) + z1 * cos(anguloX);
    
    // Projeção perspetiva
    float escala = distanciaCamara / (distanciaCamara + z2);
    verticesEcra[i][0] = (pg.width  / 2) + (x1 * escala);
    verticesEcra[i][1] = (pg.height / 2) + (y2 * escala);
  }
}


// --- DESENHO DA GRELHA ---

// Preenche cada célula da grelha: vértice ou fundo
void desenharGrelha(PGraphics pg) {
  for (int linha = 0; linha < numLinhas3; linha++) {
    for (int col = 0; col < numColunas3; col++) {

      float px = col   * tamFonte3 + (tamFonte3 / 2.0);
      float py = linha * tamFonte3 + (tamFonte3 / 2.0);

      if (perto_de_vertice(px, py)) {
        pg.fill(palette[8]);
        pg.text(characters3[6], px, py); // '0'
      } else {
        pg.fill(palette[2]);
        pg.text(characters3[4], px, py); // '#'
      }
    }
  }
}

// Devolve true se o ponto (px, py) está perto de algum vértice projetado
boolean perto_de_vertice(float px, float py) {
  for (int i = 0; i < 8; i++) {
    if (dist(px, py, verticesEcra[i][0], verticesEcra[i][1]) < 15)
      return true;
  }
  return false;
}


// --- DESENHO DAS ARESTAS ---

// Percorre cada aresta e pinta as células da grelha ao longo da linha
void desenharArestas(PGraphics pg) {
  for (int[] aresta : arestas) {
    float x1 = verticesEcra[aresta[0]][0], y1 = verticesEcra[aresta[0]][1];
    float x2 = verticesEcra[aresta[1]][0], y2 = verticesEcra[aresta[1]][1];

    float dx = x2 - x1;
    float dy = y2 - y1;
    int passos = int(sqrt(dx*dx + dy*dy) / tamFonte3);

    for (int i = 0; i <= passos; i++) {
      float t  = (passos == 0) ? 0 : (float) i / passos;
      float gx = floor((x1 + dx*t) / tamFonte3) * tamFonte3 + tamFonte3 * 0.5;
      float gy = floor((y1 + dy*t) / tamFonte3) * tamFonte3 + tamFonte3 * 0.5;

      pg.fill(palette[8]);
      pg.text('#', gx, gy);
    }
  }
}