# Instruções para assistência ao projeto — Programação III (Processing)

## Contexto do projeto

Este é um projeto académico da ESMAD (P.Porto), da unidade curricular **Programação III**, desenvolvido em **Processing (Java mode)**. O grupo é composto por três elementos: Miguel Machado, Henrique Silva e Petúnia Dias. (O enunciado oficial prevê grupos de até 3 alunos — a configuração reduzida deve ser confirmada com o docente.)

O objetivo é criar um **sketch generativo e reativo ao som**, capaz de gerar um vídeo de 1m30s a 3 minutos em tempo real, sem pós-produção. A estética centra-se na **desintegração geométrica e no caos controlado**, com sinestesia entre som e imagem.

---

## Stack técnica

- **Linguagem:** Processing 4 (Java mode)
- **Bibliotecas obrigatórias:**
  - `processing.sound.*` — SoundFile, **AudioIn (microfone)**, Amplitude, FFT, BeatDetector, WaveForm
  - `processing.video.*` — se necessário para conteúdo vídeo
- **Resolução:** 1920x1080 (FullHD), 25 fps
- **Música:** "Phylyps Track" música de Basic Channel encontrada no Spotify. Ela foi transferida e convertida para .mp3 — ficheiro `PhylypsTrak.mp3` em `data/`

---

## Estrutura obrigatória do sketch

Segundo o enunciado oficial (Secção IV): **cada aluno desenvolve 3 separadores**, cada um com a sua própria layer (`PGraphics`) independente. Com 3 alunos: **9 layers + 1 principal + 1 áudio = 11 tabs**.

Cada layer deve conter:

- Uma `PGraphics` independente (sem partilhar acumulação/sobreposição entre layers)
- Elementos gráficos 2D e/ou 3D próprios
- Reatividade ao som (amplitude, FFT, BeatDetector) — fonte pode ser música **ou** microfone
- Controlo via teclado e/ou rato (ativar/desativar, animar)

### Estrutura de tabs:

```
AsciiArt.pde   → setup, draw, palette global, gestão de inputs, composição de layers
Audio.pde           → SoundFile + AudioIn, Amplitude/FFT/BeatDetector, comutação música⇄mic
PetuniaLayer1_Sketch1.pde  → 1ª layer da Petúnia (PGraphics + classes próprias)
PetuniaLayer2_Sketch2.pde  → 2ª layer da Petúnia
PetuniaLayer3_Sketch3.pde  → 3ª layer da Petún
HenriqueLayer1_Sketch4.pde → 1ª layer do Henrique
HenriqueLayer2_Sketch5.pde → 2ª layer do Henrique
HenriqueLayer3_Sketch6.pde → 3ª layer do Henrique
MiguelLayer1_Sketch7.pde   → 1ª layer do Miguel
MiguelLayer2_Sketch8.pde   → 2ª layer do Miguel
MiguelLayer3_Sketch9.pde   → 3ª layer do Miguel

```

> Nota: o nome do ficheiro principal tem de coincidir com o nome da pasta do sketch (`AsciiArt`).

### Estrutura de pastas:

```
AsciiArt/
├── AsciiArt.pde + restantes tabs .pde
├── data/      → PhylypsTrak.mp3, fontes, imagens (Processing procura aqui automaticamente)
└── frames/    → output de saveFrame() (ignorado pelo .gitignore)
```

---

## Requisitos obrigatórios (não negociáveis)

- `size(1920, 1080)` ou `fullScreen()` + `frameRate(25)`
- Carregar e reproduzir uma `SoundFile` (`PhylypsTrak.mp3` em `data/`)
- **Entrada por microfone** com `AudioIn` (exigido pelo enunciado: "inputs de som (soundtrack **e** microfone)")
- palette de 3 a 8 colores definida explicitamente (`color[]`)
- Uso de `random()` em colores, posições, dimensões e velocidades
- Gráficos estáticos, animados e condicionados
- Input do utilizador via teclado e rato
- Reatividade ao som: amplitude (`Amplitude`), FFT (`FFT`) e batidas (`BeatDetector`) — sobre `SoundFile` **e** `AudioIn`
- Geração e captura do vídeo em tempo real (`saveFrame`)
- 3 layers (`PGraphics`) por aluno, geridas independentemente

---

## Padrões de código a seguir

### Estrutura base do `AsciiArt.pde`

```java
import processing.sound.*;

// Audio global state
SoundFile musica;
AudioIn mic;
Amplitude amp;
FFT fft;
BeatDetector beat;
boolean usarMic = false; // change between music and mic with 'm' key

// Layers — 3 per student, drawn in separate PGraphics for better performance and control
PGraphics pL1, pL2, pL3;   // Petúnia
PGraphics hL1, hL2, hL3;  // Henrique
PGraphics mL1, mL2, mL3;   // Miguel

// Layer visibility control (toggle with keys 1-6)
boolean[] layerOn = { true, true, true, true, true, true };

color[] palette; // color palette for the artwork

void setup() {
  size(1920, 1080);
  frameRate(25);

  palette = new color[]{
    color(x, x, x),

  };

  setupAudio(); // define in Audio.pde

  // Initialize layers
  pL1 = createGraphics(width, height);
  pL2 = createGraphics(width, height);
  pL3 = createGraphics(width, height);
  hL1 = createGraphics(width, height);
  hL2 = createGraphics(width, height);
  hL3 = createGraphics(width, height);
  mL1 = createGraphics(width, height);
  mL2 = createGraphics(width, height);
  mL3 = createGraphics(width, height);
}

void draw() {
  background(palette[0]);

  float amplitude = amp.analyze();
  fft.analyze();
  boolean beat = beat.isOnset();

  if (layerOn[0]) drawPetunia1(pL1, amplitude, beat);
  if (layerOn[1]) drawPetunia2(pL2, amplitude, beat);
  if (layerOn[2]) drawPetunia3(pL3, amplitude, beat);
  if (layerOn[3]) drawHenrique1(hL1, amplitude, beat);
  if (layerOn[4]) drawHenrique2(hL2, amplitude, beat);
  if (layerOn[5]) drawHenrique3(hL3, amplitude, beat);
  if (layerOn[6]) drawMiguel1(mL1, amplitude, beat);
  if (layerOn[7]) drawMiguel2(mL2, amplitude, beat);
  if (layerOn[8]) drawMiguel3(mL3, amplitude, beat);

  if (layerOn[0]) image(pL1, 0, 0);
  if (layerOn[1]) image(pL2, 0, 0);
  if (layerOn[2]) image(pL3, 0, 0);
  if (layerOn[3]) image(hL1, 0, 0);
  if (layerOn[4]) image(hL2, 0, 0);
  if (layerOn[5]) image(hL3, 0, 0);
  if (layerOn[6]) image(mL1, 0, 0);
  if (layerOn[7]) image(mL2, 0, 0);
  if (layerOn[8]) image(mL3, 0, 0);

  // saveFrame("frames/frame-####.png"); // Need to remove the comment to save frames for the video
}

void keyPressed() {
  // 1..6 → change visibility of layers (1-3 for Petúnia, 4-6 for Henrique, 7-9 for Miguel)
  if (key >= '1' && key <= '9') layerOn[key - '1'] = !layerOn[key - '1'];
  // m → alternar entre música e microfone (lógica em Audio.pde)
  if (key == 'm' || key == 'M') alternarFonteAudio();
}

```

### Padrão de `Audio.pde`

```java
void setupAudio() {
  music = new SoundFile(this, ""); // specify your audio file path here
  mic = new AudioIn(this, 0);
  amp = new Amplitude(this);
  fft = new FFT(this, 512);
  beat = new BeatDetector(this);

  music.loop();
  turnAnalysersA(music);
}

void turnAnalysersA(SoundFile src) {
  amp.input(src);
  fft.input(src);
  beat.input(src);
}

void turnAnalysersB(AudioIn src) {
  amp.input(src);
  fft.input(src);
  beat.input(src);
}

void changeAudioFont() {
  useMic = !useMic;
  if (useMic) {
    music.pause();
    mic.start();
    turnAnalysersA(mic);
  } else {
    mic.stop();
    music.play();
    turnAnalysersA(music);
  }
}
```

### Padrão de uma classe de objeto

```java
class Particles {
  PVector pos, vel;
  float size;
  color color;

  Particles(float x, float y) {
    pos = new PVector(x, y);
    vel = PVector.random2D();
    vel.mult(random(1, 4));
    size = random(5, 20);
    color = palette[int(random(palette.length))];
  }

  void update(float amplitude) {
    vel.mult(1 + amplitude);
    pos.add(vel);
  }

  void draw(PGraphics pg) {
    pg.noStroke();
    pg.fill(color, 180);
    pg.ellipse(pos.x, pos.y, size, size);
  }
}
```

---

## Referências estéticas do projeto

| Obra / Referência                             | Autor                      | Influência / Tema                                                                 |
| --------------------------------------------- | -------------------------- | --------------------------------------------------------------------------------- |
| ertdfgcvb                                     | Andreas Gysin              | Sistemas visuais generativos, formas reativas e comportamento áudio-responsivo    |
| Motion Design & Typography (Processing)       | Andréion de Castro         | Tipografia experimental, motion design e uso de Processing em sistemas gráficos   |
| Science Journals / Data Visualization Studies | Andréion de Castro         | Visualização de dados, estética científica e representação de informação          |
| OpenProcessing Sketch #2851072                | Dave Pagurek               | Arte generativa em tempo real, exploração de algoritmos visuais e interação       |
| Audio Reactive ASCII (Reddit)                 | Comunidade Creative Coding | Conversão de áudio em ASCII art, visualização sonora experimental                 |
| Audio Reactive ASCII/Unicode (Reddit)         | Comunidade Creative Coding | Expansão tipográfica de áudio em caracteres Unicode e sistemas híbridos texto/som |
| 3D Data Visualization (Pinterest)             | Referência visual          | Exploração de dados em 3D, composição espacial e visual analytics                 |
| Retro Effects App (Pinterest)                 | Referência visual          | Estética retro digital, filtros e efeitos de pós-processamento em UI/motion       |

---

## Requisitos opcionais (a implementar se possível)

- `noise()` para movimento orgânico
- Transformações 2D/3D: `pushMatrix`, `translate`, `rotateX/Y/Z`, `scale`
- Iluminação 3D: `lights`, `ambientLight`, `directionalLight`, `pointLight`
- Filtros em layers: `pg.filter(BLUR, 2)`
- `PShape` para formas vetoriais
- `PFont` para tipografia generativa
- `tint` e `blendMode` para composição de layers
- `WaveForm` para visualização da onda sonora
- `PImage`/`Video` como fonte de colores ou texturas

---

## O que NÃO fazer

- Não usar `delay()` nem loops bloqueantes no `draw()`
- Não criar objetos dentro do `draw()` sem necessidade (usar ArrayLists pré-alocados)
- Não aceder a `pixels[]` em cada frame sem necessidade (é lento)
- Não esquecer `beginDraw()` / `endDraw()` nos PGraphics
- Não usar bibliotecas externas além das mencionadas sem validar compatibilidade

---

## Entrega e prazos

| O quê                           | Quando                  | Como      |
| ------------------------------- | ----------------------- | --------- |
| Proposta de trabalho            | 6 de maio (já entregue) | Email     |
| Trabalho + Apresentação + Vídeo | 26 de maio              | OneDrive  |
| Apresentação/Defesa             | 27 de maio, 09h-13h     | Sala B206 |

### Formato do vídeo

- MP4, 1920x1080 (pixel ratio 1.0), 25fps, x264, áudio estéreo 48kHz AAC
- Incluir separador da ESMAD, título, ano letivo e nomes dos autores

---

## Pesos de avaliação

| Componente                        | Peso |
| --------------------------------- | ---- |
| Trabalho prático (código + vídeo) | 40%  |
| Relatório                         | 30%  |
| Participação ativa                | 15%  |
| Apresentação / Defesa             | 15%  |

---

## Como pedir ajuda à IA de forma eficiente

Para obter o melhor resultado possível ao pedir assistência, sê específico:

**Mau exemplo:** "Faz-me a primeira layer da Petúnia"

**Bom exemplo:** "Cria uma classe `Particle` para a primeira layer da Petúnia (`PetuniaLayer1_Sketch1.pde`) que desenha partículas reativas à amplitude do som. A classe deve ter um construtor, um método `update()` que recebe a amplitude e um método `draw(PGraphics pg)` para desenhar a partícula. O comportamento deve acumular no ecrã, sem limpar por frame."

Sempre que pedires código:

- Indica em que tab vai o código (ex: `PetuniaLayer1_Sketch1.pde`)
- Diz se é classe nova, função, ou modificação de existente
- Menciona variáveis globais que o código precisa de aceder (`palette`, `amp`, `fft`, `beat`)
- Refere se o comportamento deve acumular no ecrã ou limpar por frame

# Ideias do projeto

## Público-alvo, objetivos e motivações

### Público-alvo:

Faixa etária: 16+

- Formação : Programação , Design, Multimédia e Artes Digitais
- Profissão: Programador, Motion Designer, Designer Gráfico, Artista Digital
- Interesses pessoais : Arte generativa, creative coding, estética digital, tipografia experimental, interação audiovisual

### Objetivos e motivações:

Objetivos e Motivações: O tema selecionado centra -se na utilização de elementos ASCII como matéria visual e conceptual, reinterpretando uma linguagem computacional primitiva num contexto artístico contemporâneo.
Os objetivos conceptuais são:

- Explorar a relação entre humano e máquina através do texto,entendendo o ASCII como ponte entre linguagem humana e linguagem computacional;
- Demonstrar como símbolos simples podem gerar composições visuais complexas e dinâmicas;
- Reinterpretar o ASCII como linguagem artística contemporânea , para além da sua função técnica;
- Refletir sobre fenómenos digitais : erros, ruídos, glitches e fragmentação visual

Os objetivos formais/plásticos são:

- Utilização de tipografia dinâmica através da transformação constante entre letras, números e símbolos;
- Criação de glitches visuais e distorções gráficas;
- Desenvolvimento de movimento reativo ao som e à interação do utilizador;
- Aplicação de uma paleta cromática variada, contrariando a estética monocromática tradicional associada ao ASCII;
- Exploração de composições densas, mutáveis e generativas no espaço visual.

Por fim, os objetivos técnicos são:

- Utilização de elementos ASCII como unidades gráficas principais ;
- Interação por teclado e rato;
- Reatividade sonora através de microfone, amplitude, frequência e deteção de batidas ;
- Implementação de s istemas de partículas;
- Utilização de noise() para movimentos ;
- Utilização de random() para variação visual e comportamental ;
- Organização gráfica em layers através de PGraphics.

# Conceito Geral do projeto

A ideia do projeto é o canvas ser uma espécie de terminal, onde nos restringimos a como os caracteres se comportam nesse espaço. Letras ao contrário, a flutuar, ou animações como irem de um ponto A para um ponto B fogem dessa ideia, a não ser que seja uma manipulação da perceção das letras a terem esse movimento dentro dos limites definidos. É sobretudo trabalhar em volta dessas limitações.

## 1ª layer da Petúnia Sketch1:

A tela está completamente preenchida por caracteres e os de destaque estão mais acentuados com cores mais vibrantes. Está a ser escrito algo com uma animação de escrita, como se estivesses a fazer reboot ao PC.

Interação: Ao digitar no teclado, as letras mudam sequencialmente. O que é escrito aparece no ecrã, seguido de uma sucessão rápida de caracteres aleatórios (glitch, como no site do andreas no hover) antes de a tela estabilizar e voltar ao estado normal.

Reação ao som: Caracteres ficam mais cheios e as cores mais vibrantes de acordo com a frequencia

Referências Visuais: https://ertdfgcvb.xyz/

## 2ª layer da Petúnia Sketch2:

Ondas de letras que se movem na diagonal

Interação: Distorção quando se mexe rapidamente com o rato

Reação ao som: vão aparecendo de acordo com a frequência da música

## 3ª layer da Petúnia Sketch3:

Um cubo onde com os caracteres cria-se profundidade e forma de um cubo, onde as faces são preenchidas por caracteres. O cubo tem um movimento de rotação lenta, e os caracteres nas faces reagem à música, ficando mais vibrantes e densos com o aumento da amplitude.

Interações: é possivel girá-lo com o hover do mouse. O cubo segue o mouse basicamente.

Reação ao som: aumenta e a diminui de acordo com a frequência

## 1ª layer do Henrique Sketch4:

É exatamente a mesma animaçao das letras do background do site do Andreas com mais ou menos a mesma interaçao: se mexerem o mouse rapidamente muda de cor.

Reação ao som: As letras expandem ou diminuem de acordo com a frequência

## 2ª layer do Henrique Sketch5:

Anel 2D, quando chega a um determinado diâmetro lança uma onda de caracteres

Reação ao som: fica menor ou maior de acordo com a frequência da música

## 3ª layer do Henrique Sketch6:

Biblioteca que transforma imagens em ASCII, vamos colocar meia dúzida de frames criando uma animaçao (à escolha do freguês), que vai ficar em loop por alguns segundos

## 1ª layer do Miguel Sketch7 (MiguelLayer1_Sketch7.pde)

Resumo: tipografia tipo "typewriter" preenchendo toda a área do sketch com várias linhas em paralelo; o comportamento é reativo ao áudio (música ou microfone) e tem uma limpeza em faixa (wipe) suave.

- **Frame rate:** manter `frameRate(25)` — a layer foi otimizada para suavidade sem alterar fps.
- **Cobertura:** o texto é desenhado em múltiplas linhas paralelas e ocupa toda a área do `PGraphics` (ajustado a `textSize` e espaçamento de linhas).
- **Paleta:** usa as cores mais claras da `palette` definida em `AsciiArt.pde` (índices altos, por exemplo `palette[5..8]`) para o texto; o fundo usa uma das cores mais escuras (por exemplo `palette[3]`).
- **Áudio / Controles:**
  - A tecla `space` pausa/retoma a reprodução da `SoundFile` (comportamento global em `AsciiArt.pde`).
  - A tecla `m` alterna entre música e microfone: quando `m` ativa o microfone, a layer passa a reagir ao som do `AudioIn`; premir `m` novamente volta para a música.
  - Quando a música está parada e `m` é premido, o microfone é activado e a análise (Amplitude/FFT/BeatDetector) passa a usar o microfone, fazendo a animação reagir à voz.
- **Suavidade:** a animação do "wipe" e os timings de escrita foram suavizados (interpolação e delays adaptativos por linha) para reduzir saltos perceptíveis a 25 fps.

Notas de implementação: usar buffers reutilizáveis para a FFT/spectrum (evitar alocação por frame), tipar linhas em paralelo (cada linha tem o seu próprio temporizador) e escolher cores diretamente a partir de `palette` para garantir consistência cromática.

Reação ao som: Muda de frame com a frequencia da música

Referências Visuais:

- https://pt.pinterest.com/pin/845973111269205715/
- https://pt.pinterest.com/pin/131589620348038204/
- https://pt.pinterest.com/pin/131589620348038204/
- https://pt.pinterest.com/pin/579134833378680567/

## 1ª layer do Miguel Sketch7:

Animaçao de typing, seguida de uma transiçao tipo comboio que limpa o que esta a ser escrito

Interação: N/A

Reação ao som: As letras correm mais rapido com a frequencia

Referências Visuais: https://play.ertdfgcvb.xyz/#/src/basics/rendering_to_canvas

## 2ª layer do Miguel Sketch8:

Espécie de gradiente com círculos que se fundem, a tela está completamente cheia de caracteres. Os círculos são mais ou menos como nas imagens. Basicamente é uma mistura dos exemplos.

Interação: fusão dos círculos com o mouse ou manipulação da posição

Reação ao som: Cículos aumentam ou dimuem de acordo com a frequência da música

Referências Visuais:

- https://pt.pinterest.com/pin/1064819905637388180/
- https://play.ertdfgcvb.xyz/#/src/sdf/two_circles
- https://play.ertdfgcvb.xyz/#/src/demos/hotlink

## 3ª layer do Miguel Sketch9:

Reação ao som: Criar uma representação visual do Sistema Solar usando arte ASCII, onde cada planeta é desenhado como uma esfera rotativa composta por caracteres, com texturas reativas ao áudio.
O utilizador pode navegar entre os planetas usando as setas esquerda/direita, e cada planeta tem características visuais distintas baseadas em suas propriedades astronómicas e reatividade ao som.

---

## Controls (Miguel Layer 1)

- **Space:** Toggle music play / pause. Pressing space will stop the soundtrack when playing, and resume it when pressed again.
- **M:** Toggle microphone input. Pressing `M` switches to the microphone (when music is stopped or when you want live voice input) and the sketch will react to the microphone amplitude/FFT. Press `M` again to stop the microphone and return control to the music.
