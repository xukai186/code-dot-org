/* global p5 */

export function getDanceAPI(p5Inst) {
  const osc = new p5.Oscillator();
  const fft = new p5.FFT(0.7, 128);
  const peakDetect = new p5.PeakDetect(3000, 5000, 0.1, 3);

  // p5Inst.registerPreloadMethod('sounds', () => {
  //   debugger;
  //   song = p5Inst.loadSound('/api/v1/sound-library/category_background/jazzy_beats.mp3');
  // });

  // p5Inst.registerMethod('post', () => {
  //   spectrum = fft.analyze();
  //   peakDetect.update(fft);
  // });

  return {
    oscillator: {
      start: () => osc.start(),
      stop: () => osc.stop(),
      freq: value => osc.freq(value),
      amp: value => osc.amp(value),
    },

    fft: {
      analyze: () => {
        const spectrum = fft.analyze();
        peakDetect.update(fft);
        return spectrum || [];
      },
      isPeak: () => peakDetect.isDetected,
    },

    song: {
      play: () => window.defaultSong.play(),
      stop: () => window.defaultSong.stop(),
    },
  };
}
