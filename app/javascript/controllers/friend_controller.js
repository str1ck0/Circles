import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="friend"
export default class extends Controller {
  static values = {
    circleId: Number,
    userId: Number,
  };

  static targets = ['button'];

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').content;
  }

  submit() {
    const data = { user_circle: { user_id: this.userIdValue } };

    fetch(`/circles/${this.circleIdValue}/user_circles`, {
      method: 'POST', // or 'PUT'
      headers: {
        'X-CSRF-Token': this.csrfToken,
        'Content-Type': 'application/json',
        accept: 'application/json',
      },
      body: JSON.stringify(data),
    })
      .then((response) => {
        if (!response.ok) throw new Error(`Request failed (${response.status})`);
        return response.json();
      })
      .then(() => {
        this.buttonTarget.replaceWith(`✅`);
      })
      .catch((error) => {
        this.buttonTarget.replaceWith(`❌`);
        console.error('Error:', error);
      });
  }
}
