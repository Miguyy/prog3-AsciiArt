void setupAudio() {
  music = new SoundFile(this, "PhylypsTrak.mp3");
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
    turnAnalysersB(mic);
  } else {
    mic.stop();
    music.play();
    turnAnalysersA(music);
  }
}