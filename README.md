# AsciiArt — Sketch Generativo e Reativo ao Som

## Resumo

Projeto académico desenvolvido em Processing (Java mode) para a unidade curricular Programação III (ESMAD - P.Porto). O sketch combina várias camadas de arte ASCII e gráficas, reativas ao som (ficheiro de áudio e microfone), com o objetivo de gerar imagens/frames para um vídeo final.

## Características principais

- 9 layers independentes (3 por cada autor: Petúnia, Henrique, Miguel), cada uma a desenhar para um `PGraphics` próprio.
- Entrada de áudio: `SoundFile` (ficha `PhylypsTrak.mp3`) e `AudioIn` (microfone). Analisadores: `Amplitude`, `FFT` e `BeatDetector`.
- Paleta global (`color[] palette`) definida em `AsciiArt.pde` - todas as layers devem reutilizá-la para coerência.
- Export de frames via `saveFrame("frames/frame-####.png")` para composição de vídeo.

## Estrutura do repositório

- `AsciiArt/` — pasta do sketch (nome deve coincidir com ficheiro principal `AsciiArt.pde`)
  - `AsciiArt.pde` — ficheiro principal: setup, composição, paleta, inputs.
  - `Audio.pde` — inicialização de `SoundFile`, `AudioIn`, `Amplitude`, `FFT` e `BeatDetector`.
  - `PetuniaLayer1_Sketch1.pde`, `PetuniaLayer2_Sketch2.pde`, `PetuniaLayer3_Sketch3.pde`
  - `HenriqueLayer1_Sketch4.pde`, `HenriqueLayer2_Sketch5.pde`, `HenriqueLayer3_Sketch6.pde`
  - `MiguelLayer1_Sketch7.pde`, `MiguelLayer2_Sketch8.pde`, `MiguelLayer3_Sketch9.pde`
  - `data/` — recursos: audio (`PhylypsTrak.mp3`), fontes, imagens.
  - `frames/` — saída de `saveFrame()` (guardar imagens sequenciais para vídeo).

## Requisitos

- Processing 4 (Java mode)
- Biblioteca `processing.sound` (incluída com Processing) - para `SoundFile`, `AudioIn`, `Amplitude`, `FFT` e `BeatDetector`.
- Resolução alvo: 1920×1080 (FullHD)

## Como executar

1. Coloque `PhylypsTrak.mp3` em `AsciiArt/data/`.
2. Abra a pasta `AsciiArt` no Processing (abrir `AsciiArt.pde`).
3. Execute o sketch (`Run`).

## Controlo em runtime

- `1`..`9`: alternar qual layer está visível (cada tecla torna activa uma layer — o sketch está desenhado para que apenas uma layer esteja visível por predefinição)
- `m`: alternar entre ficheiro de música e microfone como fonte de áudio
- `space`: pausar / retomar reprodução do ficheiro (quando `useMic == false`)
- `h`: alternar HUD de diagnóstico (espectro)

## Notas de desenvolvimento

- Cada layer deve desenhar para o seu `PGraphics` e não desenhar diretamente para o ecrã.
- Use `palette[index]` para as cores, mantendo assim consistência entre layers.
- Para gravar frames (para compor o vídeo final), descomente ou mantenha `saveFrame("frames/frame-####.png")` dentro do `draw()` em `AsciiArt.pde`.

## Documentação do código

Existe um documento com comentários organizados em PT-PT por ficheiro: `docs/CODE_COMMENTS_PT-PT.md`. Consulte-o para localizar funções, variáveis importantes, paleta de cores e handlers de input por layer.

## Contribuir

- Fork + Pull Request. Ao submeter código, siga estas orientações:
  - Mantenha a paleta centralizada em `AsciiArt.pde`.
  - Evite modificar o setup global sem consenso.
  - Documente novas funções com comentários em PT-PT seguindo o estilo do projeto.

## Licença

O repositório está destinado a uso académico; defina uma licença explícita se for necessário (por exemplo MIT) antes de fazer release público.

## Problemas e debugging

- Se o `SoundFile` não carregar, confirme que o ficheiro existe em `data/` e que o nome está correto.
- Se o microfone não for detectado, verifique as permissões do sistema e que o `AudioIn` está configurado corretamente.

## Contribuidores

| Name           | GitHub profile                 |
| -------------- | ------------------------------ |
| Miguel Machado | https://github.com/Miguyy      |
| Petúnia Dias   | https://github.com/petuniadias |
| Henrique Silva | https://github.com/HenReis     |
