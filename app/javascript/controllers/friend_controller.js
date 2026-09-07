import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="friend" — sends a circle invitation to one user.
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
    const data = { invitation: { invitee_id: this.userIdValue } };

    fetch(`/circles/${this.circleIdValue}/invitations`, {
      method: 'POST',
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
        this.buttonTarget.replaceWith('Invited ✓');
      })
      .catch((error) => {
        this.buttonTarget.replaceWith('Could not invite');
        console.error('Error:', error);
      });
  }
}
