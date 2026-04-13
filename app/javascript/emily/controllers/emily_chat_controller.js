import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["window", "messages", "input", "typing"]
  static values = { url: String }

  connect() {
    this.conversationId = null
    this.consumer = createConsumer()
    this.subscription = null
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
  }

  toggle() {
    this.windowTarget.classList.toggle("emily-chat-widget__window--open")

    if (this.windowTarget.classList.contains("emily-chat-widget__window--open") && !this.conversationId) {
      this.startConversation()
    }
  }

  async startConversation() {
    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ page: window.location.pathname })
    })

    const data = await response.json()
    this.conversationId = data.conversation_id
    this.subscribeToChannel()
    this.loadMessages()
  }

  subscribeToChannel() {
    this.subscription = this.consumer.subscriptions.create(
      { channel: "Emily::ConversationChannel", conversation_id: this.conversationId },
      {
        received: (data) => {
          this.appendMessage(data.role, data.content)
          this.typingTarget.style.display = "none"
        }
      }
    )
  }

  async loadMessages() {
    const response = await fetch(`${this.urlValue}/${this.conversationId}`)
    const data = await response.json()

    this.messagesTarget.innerHTML = ""
    data.messages.forEach(msg => {
      this.appendMessage(msg.role, msg.content)
    })
  }

  async send() {
    const content = this.inputTarget.value.trim()
    if (!content || !this.conversationId) return

    this.inputTarget.value = ""
    this.appendMessage("user", content)
    this.typingTarget.style.display = "block"
    this.scrollToBottom()

    await fetch(`${this.urlValue}/${this.conversationId}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ content })
    })
  }

  appendMessage(role, content) {
    const div = document.createElement("div")
    div.className = `emily-chat-widget__message emily-chat-widget__message--${role}`
    div.innerHTML = `<div class="emily-chat-widget__bubble">${this.escapeHtml(content)}</div>`
    this.messagesTarget.appendChild(div)
    this.scrollToBottom()
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
