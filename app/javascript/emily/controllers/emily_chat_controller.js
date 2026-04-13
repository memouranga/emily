import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["window", "messages", "input", "typing", "badge"]
  static values = { url: String, botName: String, flow: Object }

  connect() {
    this.conversationId = null
    this.consumer = createConsumer()
    this.subscription = null
    this.unreadCount = 0
    this.isOpen = false
    this.flowPath = []
    this.messageIdCounter = 0
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
  }

  toggle() {
    this.isOpen = !this.isOpen
    this.windowTarget.classList.toggle("emily-chat-widget__window--open")

    if (this.isOpen) {
      this.clearBadge()
      this.inputTarget.focus()

      if (!this.conversationId) {
        this.startConversation()
      }
    }
  }

  async startConversation() {
    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
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
          this.hideTyping()
          this.appendMessage(data.role, data.content, data.message_id)

          if (!this.isOpen) {
            this.incrementBadge()
            this.playSound()
          }
        }
      }
    )
  }

  async loadMessages() {
    const response = await fetch(`${this.urlValue}/${this.conversationId}`)
    const data = await response.json()

    this.messagesTarget.innerHTML = ""
    data.messages.forEach(msg => {
      this.appendMessage(msg.role, msg.content, msg.id)
    })

    // Show conversation flow if configured and it's a fresh conversation
    if (this.hasFlowValue && this.flowValue.options && data.messages.length <= 1) {
      this.showFlowOptions(this.flowValue)
    }
  }

  async send() {
    const content = this.inputTarget.value.trim()
    if (!content || !this.conversationId) return

    this.inputTarget.value = ""
    this.appendMessage("user", content)
    this.showTyping()

    await fetch(`${this.urlValue}/${this.conversationId}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ content })
    })
  }

  // Conversation flow
  showFlowOptions(node) {
    if (!node.options || node.options.length === 0) return

    const container = document.createElement("div")
    container.className = "emily-chat-widget__flow-options"

    node.options.forEach((option, index) => {
      const btn = document.createElement("button")
      btn.className = "emily-chat-widget__flow-option"
      btn.textContent = option.label
      btn.addEventListener("click", () => this.selectFlowOption(option, index))
      container.appendChild(btn)
    })

    this.messagesTarget.appendChild(container)
    this.scrollToBottom()
  }

  async selectFlowOption(option, index) {
    // Remove flow options from UI
    this.messagesTarget.querySelectorAll(".emily-chat-widget__flow-options").forEach(el => el.remove())

    // Show user's selection as a message
    this.appendMessage("user", option.label)
    this.flowPath.push(index)

    if (option.tag === "escalate") {
      // Escalate immediately
      this.appendMessage("assistant", option.next?.greeting || "Let me connect you with someone who can help.")
      this.showTyping()
      await this.sendMessage(option.label)
      return
    }

    if (option.next) {
      // Show next level
      if (option.next.greeting) {
        this.appendMessage("assistant", option.next.greeting)
      }
      this.showFlowOptions(option.next)
    } else {
      // Leaf node — tag the conversation and switch to AI
      this.showTyping()
      await this.sendMessage(`${option.label} [context: ${option.tag || "general"}]`)
    }
  }

  async sendMessage(content) {
    await fetch(`${this.urlValue}/${this.conversationId}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ content })
    })
  }

  // Rating
  async rate(messageId, score) {
    const buttons = document.querySelectorAll(`[data-message-id="${messageId}"] .emily-chat-widget__rating button`)
    buttons.forEach(btn => {
      btn.classList.remove("rated")
      if (parseInt(btn.dataset.score) === score) btn.classList.add("rated")
      btn.disabled = true
    })

    await fetch(`${this.urlValue}/${this.conversationId}/messages/${messageId}/rating`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ score })
    })
  }

  // Message rendering
  appendMessage(role, content, messageId) {
    const div = document.createElement("div")
    const id = messageId || `local-${++this.messageIdCounter}`
    div.className = `emily-chat-widget__message emily-chat-widget__message--${role}`
    div.setAttribute("data-message-id", id)

    let html = `<div class="emily-chat-widget__bubble">${this.escapeHtml(content)}</div>`

    // Add rating buttons for assistant messages
    if (role === "assistant" && messageId) {
      html += `
        <div class="emily-chat-widget__rating">
          <button data-score="2" onclick="this.closest('[data-controller]').__stimulusController.rate('${id}', 2)">&#128077;</button>
          <button data-score="1" onclick="this.closest('[data-controller]').__stimulusController.rate('${id}', 1)">&#128078;</button>
        </div>`
    }

    div.innerHTML = html
    this.messagesTarget.appendChild(div)
    this.scrollToBottom()

    // Store controller reference for rating onclick
    if (role === "assistant") {
      this.element.__stimulusController = this
    }
  }

  // Typing indicator
  showTyping() {
    this.typingTarget.classList.add("emily-chat-widget__typing--visible")
    this.scrollToBottom()
  }

  hideTyping() {
    this.typingTarget.classList.remove("emily-chat-widget__typing--visible")
  }

  // Badge
  incrementBadge() {
    this.unreadCount++
    this.badgeTarget.textContent = this.unreadCount > 9 ? "9+" : this.unreadCount
    this.badgeTarget.classList.add("emily-chat-widget__badge--visible")
  }

  clearBadge() {
    this.unreadCount = 0
    this.badgeTarget.classList.remove("emily-chat-widget__badge--visible")
  }

  // Sound
  playSound() {
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)()
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.connect(gain)
      gain.connect(ctx.destination)
      osc.frequency.value = 800
      gain.gain.value = 0.1
      osc.start()
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.3)
      osc.stop(ctx.currentTime + 0.3)
    } catch (e) {
      // Sound not supported, ignore
    }
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
