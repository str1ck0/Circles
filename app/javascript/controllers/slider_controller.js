import { Controller } from '@hotwired/stimulus';
import { Splide } from '@splidejs/splide';
import { AutoScroll } from '@splidejs/splide-extension-auto-scroll';

// Connects to data-controller="slider"
export default class extends Controller {
  connect() {
    const slideCount = this.element.querySelectorAll('.splide__slide').length;
    const perPage = Math.min(3, Math.max(1, slideCount));
    // Loop mode clones slides to fill the track, which looks broken with only a few.
    const loop = slideCount > perPage;

    this.splide = new Splide(this.element, {
      type: loop ? 'loop' : 'slide',
      drag: 'free',
      focus: loop ? 'center' : 0,
      perPage,
      gap: '14px',
      arrows: slideCount > perPage,
      pagination: false,
      autoScroll: { speed: 0.6, pauseOnHover: true },
    });

    this.splide.mount(loop ? { AutoScroll } : {});
  }

  disconnect() {
    if (this.splide) this.splide.destroy();
  }
}
