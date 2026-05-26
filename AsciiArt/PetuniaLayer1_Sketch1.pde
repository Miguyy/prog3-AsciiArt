/*
  Propósito:
    Terminal/efeito textural que mostra linhas de sistema simuladas e aceita
    input do utilizador. As letras do input dissolvem-se ao longo do tempo.

  Variáveis principais:
    - tamFonte, numColunas, numLinhas: métricas de grelha e fonte.
    - fonte: fonte monoespaçada usada na layer.
    - inputUtilizador: lista de `LetraInput` que armazena caracteres digitados.
    - linhasSistema: mensagens do sistema exibidas progressivamente.

  Funções expostas ao sketch principal:
    - drawPetunia1(PGraphics pg, float amplitude, boolean batida)
    - keyPressed_p1() — handler de teclado específico da layer
    - resetLayer1() — reinicia o estado da layer

  Uso da paleta:
    - Usar `palette[index]` proveniente de `AsciiArt.pde` para manter coerência.

  Controlo / Keys:
    - BACKSPACE, ENTER, caracteres imprimíveis: edição do terminal local.
*/

// --- CONFIGURAÇÃO GERAL ---

int tamFonte = 16;
int numColunas, numLinhas;
PFont fonte;

char[] sequencia1 = {'.', ',', '*', 'x', '#', '1', '0', '░', '='};


// --- MODELO DE DADOS ---

// Representa uma letra digitada pelo utilizador, que vai dissolvendo
class LetraInput {
  char original;     // O caractere que o utilizador escreveu
  int fase = 0;      // Em que ponto da dissolução está (0 = início)
  int delay = 30;   // Frames até começar a dissolver

  LetraInput(char c) {
    original = c;
  }

  // Devolve o caractere a mostrar neste momento
  char caractereAtual() {
    if (delay > 0) return original;
    return sequencia1[fase];
  }

  // Avança a dissolução. Devolve true se já terminou o ciclo.
  boolean avançar() {
    if (delay > 0) { delay--; return false; }
    if (fase < sequencia1.length - 1) { fase++; return false; }
    return true; // Dissolução completa
  }
}

ArrayList<LetraInput> inputUtilizador = new ArrayList<LetraInput>();


// --- TEXTO DO SISTEMA ---

String[] linhasSistema = {
  "LOAD:: SYSTEM_LOG_MATRIX_REACTIVE...",
  "STATUS:: CORE_PALETTE_CONNECTED [AZUL_REACTIVE]",
  "==================================================",
  "| DATA_STREAM_ONLINE | RECT_TO_AUDIO_BEAT: TRUE |",
  "================================================--",
  "                                                  ",
  "SHADERS:: GLSL_AUDIO_REACTORS_LOADED... [OK]",
  "BUFFER:: FREQUENCY_BANDS_MAPPED [64_CHANNELS]",
  "DEVICES:: AUDIO_INPUT_LINE_DETECTED",
  "DECRYPTING MATRIX LAYER_1_PETUNIA...",
  "==================================================",
  "                                                  ",
  ">> TERMINAL READY. AWAITING USER INPUT..."
};

int linhaAtual  = 0;   // Qual linha do sistema está a ser escrita
int colActual   = 0;   // Qual caractere dentro dessa linha
String textoSistema = ""; // Texto acumulado já exibido

void drawPetunia1(PGraphics pg, float amplitude, boolean batida) {

  if (fonte == null) {
    fonte      = createFont("Courier", tamFonte);
    numColunas = pg.width  / tamFonte;
    numLinhas  = pg.height / tamFonte;
  }

  atualizarDissolucao();
  avançarTextoSistema();

  pg.beginDraw();
  pg.background(palette[3]);
  pg.textFont(fonte);
  pg.textSize(tamFonte);
  pg.textAlign(CENTER, CENTER);

  String[] linhasVisiveis = split(textoSistema, '\n');
  int margemColuna = 3;
  int margemLinha  = 2;

  for (int linha = 0; linha < numLinhas; linha++) {
    for (int col = 0; col < numColunas; col++) {

      float px = col   * tamFonte + (tamFonte / 2.0);
      float py = linha * tamFonte + (tamFonte / 2.0);

      boolean desenhado = false;

      desenhado = desenharTextoSistema(pg, linhasVisiveis, linha, col, margemLinha, margemColuna, px, py);

      if (!desenhado && sistemaTerminou())
        desenhado = desenharInputUtilizador(pg, linhasVisiveis, linha, col, margemLinha, margemColuna, px, py);

      if (!desenhado)
        desenharFundoReativo(pg, px, py, amplitude, batida);
    }
  }

  pg.endDraw();
}


// --- ATUALIZAÇÃO ---

void atualizarDissolucao() {
  for (int i = inputUtilizador.size() - 1; i >= 0; i--) {
    if (inputUtilizador.get(i).avançar())
      inputUtilizador.remove(i);
  }
}

void avançarTextoSistema() {
  for (int k = 0; k < 4; k++) {
    if (linhaAtual >= linhasSistema.length) break;
    if (colActual < linhasSistema[linhaAtual].length()) {
      textoSistema += linhasSistema[linhaAtual].charAt(colActual);
      colActual++;
    } else {
      textoSistema += "\n";
      linhaAtual++;
      colActual = 0;
    }
  }
}

boolean sistemaTerminou() {
  return linhaAtual >= linhasSistema.length;
}


// --- DESENHO ---

boolean desenharTextoSistema(PGraphics pg, String[] linhasVisiveis,
  int linha, int col, int margemLinha, int margemColuna,
  float px, float py) {
  int idxLinha = linha - margemLinha;
  if (idxLinha < 0 || idxLinha >= linhasVisiveis.length) return false;

  int idxCol = col - margemColuna;
  if (idxCol < 0 || idxCol >= linhasVisiveis[idxLinha].length()) return false;

  pg.fill(palette[7]);
  pg.text(linhasVisiveis[idxLinha].charAt(idxCol), px, py);
  return true;
}

boolean desenharInputUtilizador(PGraphics pg, String[] linhasVisiveis,
  int linha, int col, int margemLinha, int margemColuna,
  float px, float py) {
  int linhaInput  = margemLinha + linhasVisiveis.length + 1;
  if (linha != linhaInput) return false;

  int posNaLinha = col - margemColuna;

  if (posNaLinha == 0) { pg.fill(palette[7]); pg.text('>', px, py); return true; }
  if (posNaLinha == 1) { pg.fill(palette[7]); pg.text(' ', px, py); return true; }

  int idxLetra = posNaLinha - 2;

  if (idxLetra >= 0 && idxLetra < inputUtilizador.size()) {
    pg.fill(palette[7]);
    pg.text(inputUtilizador.get(idxLetra).caractereAtual(), px, py);
    return true;
  }

  if (idxLetra == inputUtilizador.size()) {
    pg.fill(palette[7]);
    pg.text((frameCount % 20 < 10) ? "░" : " ", px, py);
    return true;
  }

  return false;
}

void desenharFundoReativo(PGraphics pg, float x, float y, float amplitude, boolean batida) {
  if (batida) {
    color c = lerpColor(palette[1], palette[2], amplitude);
    pg.fill(c);
    pg.text(sequencia1[int(random(sequencia1.length))], x, y);
  } else {
    pg.fill(palette[2]);
    pg.text(sequencia1[4], x, y);
  }
}


// --- INPUT E RESET ---

void keyPressed_p1() {
  if (!sistemaTerminou()) return;
  if      (key == BACKSPACE)              { if (inputUtilizador.size() > 0) inputUtilizador.remove(inputUtilizador.size() - 1); }
  else if (key == ENTER || key == RETURN) { inputUtilizador.clear(); }
  else if (key != CODED && key != ESC)    { inputUtilizador.add(new LetraInput(key)); }
}

void resetLayer1() {
  linhaAtual    = 0;
  colActual     = 0;
  textoSistema  = "";
  inputUtilizador.clear();
}