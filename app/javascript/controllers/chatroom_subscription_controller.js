import { Controller } from '@hotwired/stimulus';
import { createConsumer } from '@rails/actioncable';

// Connects to data-controller="chatroom-subscription"
// One controller for both circle and event chats; `channel` names the Action Cable channel.
export default class extends Controller {
  static values = { channel: String, id: Number, currentUserId: Number };
  static targets = ['messages'];

  connect() {
    this.subscription = createConsumer().subscriptions.create(
      { channel: this.channelValue, id: this.idValue },
      { received: (data) => this.#insertMessageAndScrollDown(data) }
    );
    this.#scrollToBottom();
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe();
  }

  resetForm(event) {
    event.target.reset();
  }

  #insertMessageAndScrollDown(data) {
    const mine = this.currentUserIdValue === data.sender_id;
    this.messagesTarget.insertAdjacentHTML(
      'beforeend',
      `<div class="message-row d-flex ${mine ? 'justify-content-end' : 'justify-content-start'}">
         <div class="${mine ? 'sender-style' : 'receiver-style'}">${data.message}</div>
       </div>`
    );
    this.#scrollToBottom();
  }

  #scrollToBottom() {
    this.messagesTarget.scrollTo(0, this.messagesTarget.scrollHeight);
  }
}
