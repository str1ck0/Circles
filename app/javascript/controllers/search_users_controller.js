import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="search-users" — live search inside the invite modal.
export default class extends Controller {
  static targets = ['form', 'input', 'users_list'];

  update() {
    const url = `${this.formTarget.action}?query=${encodeURIComponent(this.inputTarget.value)}`;
    fetch(url, { headers: { Accept: 'text/plain' } })
      .then((response) => response.text())
      .then((html) => {
        this.users_listTarget.outerHTML = html;
      });
  }
}
