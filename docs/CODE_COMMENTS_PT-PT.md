# Comentários organizados (PT-PT) — Código do projeto AsciiArt

Este documento centraliza comentários e descrições por ficheiro para facilitar leitura e manutenção. Inclui: propósito do ficheiro, variáveis principais, funções expostas, uso da paleta de cores e teclas/inputs relevantes.

---

1. AsciiArt.pde

- Propósito: ficheiro principal; inicializa áudio, paleta (`palette`), cria `PGraphics` para cada layer e compõe-as em `draw()`.
- Variáveis principais:
  - `SoundFile music`, `AudioIn mic`, `Amplitude amp`, `FFT fft`, `BeatDetector beat` — analisadores e fontes de áudio.
  - `PGraphics pL1..mL3` — set de 9 `PGraphics`, um por layer.
  - `boolean[] layerOn` — controlo de visibilidade de cada layer.
  - `color[] palette` — paleta global (definida aqui). Índices usados por convenção (0 = fundo base, 3 = cor de fundo das layers, 5..8 = cores de destaque/hover/beat).
- Funções importantes:
  - `setup()` — inicialização geral, criação dos `PGraphics` e `setupAudio()`.
  - `draw()` — obtém `amplitude` e `fft`, chama `drawX()` de cada layer activo e compõe as imagens com `image()`.
  - `renderHUD()` — desenho do HUD de espectro (diagnóstico).
  - `keyPressed()` — mapeamento de teclas para alternar audio, layers e delegar handlers específicos de layer.

2. Audio.pde

- Propósito: inicializa o ficheiro de música e o microfone; cria `Amplitude`, `FFT` e `BeatDetector` e fornece helper para alternar entre fontes.
- Variáveis principais: `music`, `mic`, `amp`, `fft`, `beat`, `useMic`.
- Funções:
  - `setupAudio()` — carregar `PhylypsTrak.mp3`, criar analisadores e ligar ao ficheiro por defeito.
  - `turnAnalysersA(SoundFile)` / `turnAnalysersB(AudioIn)` — ligar analizadores a uma fonte específica.
  - `changeAudioFont()` — alterna `useMic`, pausa/arranca playback e liga analisadores ao mic/ficheiro.

3. PetuniaLayer1_Sketch1.pde

- Propósito: terminal/efeito textural; aceita input do utilizador que se dissolve e tem linhas de sistema simuladas.
- Variáveis principais: `tamFonte`, `numColunas`, `numLinhas`, `fonte`, `inputUtilizador` (lista de `LetraInput`), `linhasSistema`.
- Funções:
  - `drawPetunia1(PGraphics, float amplitude, boolean batida)` — render principal da layer.
  - `keyPressed_p1()` — handler de teclado para entrada do utilizador (backspace, enter, letras).
  - `resetLayer1()` — reiniciar estado da layer.

4. PetuniaLayer2_Sketch2.pde

- Propósito: onda diagonal com distorção por rato e amplitude; preenche grelha ASCII com `calcularCaractere()`.
- Funções:
  - `drawPetunia2(PGraphics, float amplitude, boolean batida)`
  - `calcularCaractere(int col, int linha, float amplitude, float velocidadeRato)` — devolve carácter baseado na onda e no limiar.

5. PetuniaLayer3_Sketch3.pde

- Propósito: projeção 3D de um cubo em grelha ASCII; arestas e vértices desenhados como caracteres.
- Variáveis/funcs chave: `projetarVertices()`, `desenharGrelha()`, `desenharArestas()`, `perto_de_vertice()`.

6. HenriqueLayer1_Sketch4.pde

- Propósito: grelha ASCII rígida que revela palavras (IPP, ESMAD, etc.) com máscaras e mutações reativas ao rato e áudio.
- Variáveis: `words`, `alphabet`, `mutatePool`, `cellSize`, `henrique1Font`, `maskA/maskB`, `mutateUntil`, `mutateChar`, tempos de transição (`holdMs`, `fadeMs`).
- Funções:
  - `initHenrique1()` — inicialização do estado da layer.
  - `drawHenrique1(PGraphics, float amp, boolean beat)` — render principal; usa `renderWordMask()` e sampling de alpha da máscara.
  - `renderWordMask(PGraphics, String word, float textSize)`, `sampleMaskAlpha()`, `sampleBlendAlpha()` — utilitários de máscara.

7. HenriqueLayer2_Sketch5.pde

- Propósito: render de um toro em 3D mapeado para grelha ASCII com shading por iluminação; usa `zBuffer` e `shadeBuffer`.
- Variáveis: `densityRamp` (rampa de ASCII para shading), `cellSizeH2`, `gridCols/rows`, `rotA/rotB`, `zBuffer`, `shadeBuffer`.
- Funções: `ensureGrid()`, `clearGrid()`, `drawHenrique2(PGraphics, float amp, boolean beat)`.

8. HenriqueLayer3_Sketch6.pde

- Propósito: render ASCII avançado com frames pré-carregados, estrelas e corners; troca de frames condicionada ao áudio.
- Notas: carregar frames em `initHenrique3()`, usar `updateHenrique3Frame()` para controlar avanços por batida.

9. MiguelLayer1_Sketch7.pde

- Propósito: grelha ASCII com linhas alternadas, wipe/erase por linha, cache de estado apagado por célula e controlo via teclas `e`, `E`, `r`.
- Variáveis principais: `ML7_chars`, `ML7_font`, `ML7_erased` (boolean matrix), flags de erase e modo auto.
- Funções: `drawMiguel1(PGraphics, float amp, boolean beat)`, `miguelLayer1KeyPressed()`.

10. MiguelLayer2_Sketch8.pde

- Propósito: blobs orgânicos que se movem para cima; blob principal segue o rato e expande com áudio; usa SDF (signed distance) para formar shapes suaves e mapeá-las para ASCII.
- Funções utilitárias: `sdCircle()`, `opSmoothUnion()` e `miguelLayer2KeyPressed()`.

11. MiguelLayer3_Sketch9.pde

- Propósito: representação ASCII do Sistema Solar; cada planeta desenhado como esfera ASCII rotativa; navegação por setas codificadas (`RIGHT`/`LEFT`).
- Variáveis: `columns`, `lines`, `characters`, `currentPlanet`, `planetRotation`, `starMap`.
- Funções: `drawMiguel3(PGraphics, float amp, boolean beat)`, `miguelLayer3KeyPressed()`.

Notas gerais sobre a paleta de cores

- A paleta global `palette` é um `color[]` definido em `AsciiArt.pde` e deve ser tratada como fonte de verdade. Exemplos de índice de uso:
  - `palette[0]` — cor de fundo global
  - `palette[3]` — fundo interno das layers
  - `palette[5]` / `palette[6]` / `palette[7]` — cores de destaque, batida e hover

Boas práticas

- Evitar efeitos que desenhem diretamente no ecrã fora dos `PGraphics` das layers.
- Documentar novas variáveis e funções em PT-PT com o mesmo estilo usado neste repositório.

Se quiser que eu aplique estes comentários diretamente em cada `.pde` (edição inline), diga-me para eu proceder e indicar quais ficheiros editar primeiro.
