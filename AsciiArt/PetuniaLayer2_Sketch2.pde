/*
  Propósito:
    Geração de uma onda diagonal textural que reage à amplitude sonora e ao
    movimento do rato; preenche uma grelha ASCII com níveis de detalhe.

  Variáveis principais:
    - tamFonte2, fonte2: métricas de fonte e grelha.
    - tempo2: tempo interno que avança com a amplitude para modular o efeito.
    - characters2: sequência de caracteres ASCII ordenados por densidade.

  Funções expostas:
    - drawPetunia2(PGraphics pg, float amplitude, boolean batida)
    - calcularCaractere(int col, int linha, float amplitude, float velocidadeRato)

  Uso da paleta:
    - Desenhar caracteres com `palette[7]` ou `palette[2]` conforme contraste.

  Controlo / Keys:
    - sem handler global; responder aos eventos enviados por `AsciiArt.pde`.
*/

// --- CONFIGURAÇÃO GERAL ---

int tamFonte2 = 16;
PFont fonte2;
float tempo2 = 0;

char[] characters2 = {' ', '.', ',', '*', 'x', '#', '0'};


void drawPetunia2(PGraphics pg, float amplitude, boolean batida) {

  if (fonte2 == null)
    fonte2 = createFont("Courier New", tamFonte2, true);

  // O tempo avança mais depressa com mais amplitude
  tempo2 += 0.06 + amplitude * 0.3;

  int numColunas2 = pg.width  / tamFonte2;
  int numLinhas2  = pg.height / tamFonte2;

  // Velocidade do rato distorce a onda
  float velocidadeRato = dist(mouseX, mouseY, pmouseX, pmouseY);

  pg.beginDraw();
  pg.background(palette[3]);
  pg.textFont(fonte2);
  pg.textSize(tamFonte2);
  pg.textAlign(CENTER, CENTER);

  for (int linha = 0; linha < numLinhas2; linha++) {
    for (int col = 0; col < numColunas2; col++) {

      float px = col   * tamFonte2 + tamFonte2 * 0.5;
      float py = linha * tamFonte2 + tamFonte2 * 0.5;

      char c = calcularCaractere(col, linha, amplitude, velocidadeRato);
      if (c == 0) continue; // abaixo do limiar — célula vazia

      pg.fill(palette[7]);
      pg.text(c, px, py);
    }
  }

  pg.endDraw();
}


// --- CÁLCULO DO CARACTERE ---

// Devolve o caractere a mostrar nesta célula, ou 0 se ficar abaixo do limiar
char calcularCaractere(int col, int linha, float amplitude, float velocidadeRato) {

  // Onda diagonal com distorção de amplitude e rato
  float onda = sin(
    (col - linha) * 0.05
    - tempo2
    + sin(linha * 0.08) * (0.8 + amplitude * 5.0)
    + velocidadeRato * sin(linha * 0.1) * 0.05
  );

  // Normaliza a onda de [-1,1] para [0,1]
  float t = (onda + 1) / 2.0;

  // Limiar: com mais amplitude, aceita valores mais baixos (mais caracteres visíveis)
  float limiar = map(amplitude, 0, 1, 0.3, 0.1);

  if (t < limiar) return 0; // Abaixo do limiar — não desenha

  // Mapeia o valor normalizado para um índice na sequência de caracteres
  float tNormalizado = map(t, limiar, 1.0, 0, 1);
  int indice = constrain(int(tNormalizado * (characters2.length - 1)), 0, characters2.length - 1);

  return characters2[indice];
}