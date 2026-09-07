import { Controller } from '@hotwired/stimulus';
import Swal from 'sweetalert2';

// Connects to data-controller="attend"
export default class extends Controller {
  static targets = ['userCount'];
  static values = {
    url: String,
  };

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').content;
  }

  async clicky(event) {
    event.preventDefault();
    const response = await fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': this.csrfToken,
        'Content-Type': 'application/json',
        accept: 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      Swal.fire({
        position: 'bottom-end',
        icon: 'error',
        title: 'NOT ALLOWED',
        text: data.error || (data.errors && data.errors.join(', ')) || 'Could not join this event',
        showConfirmButton: false,
        timer: 2500,
      });
      return;
    }

    const userCount = data.user_count;
    this.userCountTarget.innerText = userCount

    Swal.fire({
      position: 'bottom-end',
      icon: 'success',
      title: 'CONFIRMED',
      text: `There are now ${userCount} people in this event`,
      showConfirmButton: false,
      timer: 2000,
    });
  }
}
