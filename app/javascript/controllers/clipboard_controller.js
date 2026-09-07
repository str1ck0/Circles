import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="clipboard"
export default class extends Controller {
  static targets = ['source', 'button'];

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value).then(() => {
      this.buttonTarget.innerText = 'Copied!';
      setTimeout(() => { this.buttonTarget.innerText = 'Copy link'; }, 2000);
    });
  }
}
