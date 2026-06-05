# AsciiArt

## Overview

Academic project developed in Processing (Java mode) for the Programming III course (ESMAD - P.Porto). The sketch combines multiple layers of ASCII and graphical art, reactive to audio input (audio file and microphone), with the goal of generating images/frames for a final video.

## Main Features

- 9 independent layers (3 per author: Petúnia, Henrique, Miguel), each drawing to its own `PGraphics`.
- Audio input: `SoundFile` (`PhylypsTrak.mp3`) and `AudioIn` (microphone). Analyzers: `Amplitude`, `FFT`, and `BeatDetector`.
- Global color palette (`color[] palette`) defined in `AsciiArt.pde` — all layers should reuse it for consistency.
- Frame export via `saveFrame("frames/frame-####.png")` for video composition.

## Repository Structure

- `AsciiArt/` — sketch folder (the folder name must match the main file `AsciiArt.pde`)
  - `AsciiArt.pde` — main file: setup, composition, palette, inputs.
  - `Audio.pde` — initialization of `SoundFile`, `AudioIn`, `Amplitude`, `FFT`, and `BeatDetector`.
  - `PetuniaLayer1_Sketch1.pde`, `PetuniaLayer2_Sketch2.pde`, `PetuniaLayer3_Sketch3.pde`
  - `HenriqueLayer1_Sketch4.pde`, `HenriqueLayer2_Sketch5.pde`, `HenriqueLayer3_Sketch6.pde`
  - `MiguelLayer1_Sketch7.pde`, `MiguelLayer2_Sketch8.pde`, `MiguelLayer3_Sketch9.pde`
  - `data/` — resources: audio (`PhylypsTrak.mp3`), fonts, images.
  - `frames/` — output from `saveFrame()` (stores sequential images for video creation).

## Requirements

- Processing 4 (Java mode)
- `processing.sound` library (included with Processing) — required for `SoundFile`, `AudioIn`, `Amplitude`, `FFT`, and `BeatDetector`.
- Target resolution: 1920×1080 (Full HD)

## How to Run

1. Place `PhylypsTrak.mp3` inside `AsciiArt/data/`.
2. Open the `AsciiArt` folder in Processing (open `AsciiArt.pde`).
3. Run the sketch (`Run`).

## Runtime Controls

- `1`..`9`: switch which layer is visible (each key activates a layer — the sketch is designed so that only one layer is visible by default)
- `m`: switch between the music file and microphone as the audio source
- `space`: pause / resume audio file playback (when `useMic == false`)
- `h`: toggle the diagnostic HUD (spectrum display)

## Development Notes

- Each layer should draw to its own `PGraphics` and not directly to the screen.
- Use `palette[index]` for colors to maintain consistency across layers.
- To save frames (for composing the final video), uncomment or keep `saveFrame("frames/frame-####.png")` inside `draw()` in `AsciiArt.pde`.

## Code Documentation

A document containing organized PT-PT comments by file is available at `docs/CODE_COMMENTS_PT-PT.md`. Refer to it to locate functions, important variables, the color palette, and input handlers for each layer.

## Contributing

Fork + Pull Request. When submitting code, please follow these guidelines:

- Keep the color palette centralized in `AsciiArt.pde`.
- Avoid modifying the global setup without team consensus.
- Document new functions with PT-PT comments following the project's style.

## License

This repository is intended for academic use. Define an explicit license if public release is planned (for example, MIT).

## Troubleshooting

- If `SoundFile` fails to load, verify that the file exists in `data/` and that the filename is correct.
- If the microphone is not detected, check your system permissions and ensure that `AudioIn` is configured correctly.

## Contributors

| Name | GitHub Profile |
|--------|--------|
| Miguel Machado | https://github.com/Miguyy |
| Petúnia Dias | https://github.com/petuniadias |
| Henrique Silva | https://github.com/HenReis |
