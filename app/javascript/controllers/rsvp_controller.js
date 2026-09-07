import { Controller } from '@hotwired/stimulus';
import Swal from 'sweetalert2';

// Connects to data-controller="rsvp"
export default class extends Controller {
  static targets = ['button', 'count'];
  static values = { url: String };

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').content;
  }

  async choose(event) {
    event.preventDefault();
    const status = event.currentTarget.dataset.status;

    const response = await fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': this.csrfToken,
        'Content-Type': 'application/json',
        accept: 'application/json',
      },
      body: JSON.stringify({ user_event: { status } }),
    });
    const data = await response.json();

    if (!response.ok) {
      Swal.fire({
        position: 'bottom-end',
        icon: 'error',
        title: 'NOT ALLOWED',
        text: data.error || 'Could not update your RSVP',
        showConfirmButton: false,
        timer: 2500,
      });
      return;
    }

    this.buttonTargets.forEach((button) => {
      button.classList.toggle('is-active', button.dataset.status === data.status);
    });
    this.countTargets.forEach((count) => {
      count.innerText = data.counts[count.dataset.status] ?? 0;
    });

    Swal.fire({
      position: 'bottom-end',
      icon: 'success',
      title: data.label,
      showConfirmButton: false,
      timer: 1500,
    });
  }
}
