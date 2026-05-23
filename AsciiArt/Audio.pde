/*
  Propósito:
    Inicialização e controlo dos analisadores de áudio.
    - Cria o `SoundFile` para reprodução, a entrada `AudioIn` para microfone,
      e os objetos `Amplitude`, `FFT` e `BeatDetector` usados pelo sketch.
    - Fornece utilitários para ligar os analisadores a uma fonte (ficheiro ou mic)
      e alternar entre eles.
*/

// Configura o sistema de áudio: ficheiro, microfone e analisadores
void setupAudio() {
  music = new SoundFile(this, "PhylypsTrak.mp3");
  mic = new AudioIn(this, 0);
  amp = new Amplitude(this);
  fft = new FFT(this, 512);
  beat = new BeatDetector(this);

  // Começar a tocar em loop por omissão e ligar os analisadores ao ficheiro
  music.loop();
  turnAnalysersA(music);
}

// Liga os analisadores (`amp`, `fft`, `beat`) a uma fonte `SoundFile`
void turnAnalysersA(SoundFile src) {
  amp.input(src);
  fft.input(src);
  beat.input(src);
}

// Liga os mesmos analisadores à entrada do microfone (`AudioIn`)
void turnAnalysersB(AudioIn src) {
  amp.input(src);
  fft.input(src);
  beat.input(src);
}

// Alterna entre usar o ficheiro de música e o microfone
void changeAudioFont() {
  useMic = !useMic;
  if (useMic) {
    // Ativar microfone: pausar música, arrancar o mic e ligar analisadores ao mic
    music.pause();
    mic.start();
    turnAnalysersB(mic);
  } else {
    // Voltar para ficheiro: parar mic, retomar música e ligar analisadores ao ficheiro
    mic.stop();
    music.play();
    turnAnalysersA(music);
  }
}