import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["window", "messages", "input", "typing", "badge", "hashcash"]
  static values = { url: String, botName: String, flow: Object }

  static storageKey = "emily.conversation_id"

  connect() {
    this.conversationId = this.readStoredConversationId()
    this.consumer = createConsumer()
    this.subscription = null
    this.unreadCount = 0
    this.isOpen = false
    this.flowPath = []
    this.messageIdCounter = 0
    this.sending = false
    this.hashcashReady = !this.hasHashcashTarget

    if (this.hasHashcashTarget) {
      this.mintHashcash()
    }

    if (this.conversationId) {
      this.subscribeToChannel()
    }
  }

  async mintHashcash() {
    const raw = this.hashcashTarget.getAttribute("data-hashcash")
    if (!raw) {
      this.hashcashReady = true
      return
    }

    await this.awaitHashcashGlobal()
    if (typeof window.Hashcash !== "function") {
      console.warn("[Emily] Hashcash global missing; anti-bot proof will be empty")
      this.hashcashReady = true
      return
    }

    const options = JSON.parse(raw)
    window.Hashcash.mint(options.resource, options, (stamp) => {
      this.hashcashTarget.value = stamp.toString()
      this.hashcashReady = true
    })
  }

  awaitHashcashGlobal() {
    return new Promise((resolve) => {
      const start = performance.now()
      const poll = () => {
        if (typeof window.Hashcash === "function") return resolve()
        if (performance.now() - start > 10000) return resolve()
        setTimeout(poll, 100)
      }
      poll()
    })
  }

  async waitForHashcash() {
    if (this.hashcashReady) return
    await new Promise((resolve) => {
      const start = performance.now()
      const poll = () => {
        if (this.hashcashReady || performance.now() - start > 30000) return resolve()
        setTimeout(poll, 100)
      }
      poll()
    })
  }

  get hashcashValue() {
    return this.hasHashcashTarget ? this.hashcashTarget.value : null
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
      } else if (this.messagesTarget.childElementCount === 0) {
        this.loadMessages()
      }
    }
  }

  async startConversation() {
    await this.waitForHashcash()

    const payload = { page: window.location.pathname }
    const hashcash = this.hashcashValue
    if (hashcash) payload.hashcash = hashcash

    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify(payload)
    })

    const data = await response.json()
    this.conversationId = data.conversation_id
    this.storeConversationId(this.conversationId)
    this.subscribeToChannel()
    this.loadMessages()
  }

  readStoredConversationId() {
    try {
      return window.sessionStorage.getItem(this.constructor.storageKey)
    } catch (_e) {
      return null
    }
  }

  storeConversationId(id) {
    try {
      window.sessionStorage.setItem(this.constructor.storageKey, id)
    } catch (_e) {
      // sessionStorage unavailable (private mode, quota); fall back to in-memory only
    }
  }

  subscribeToChannel() {
    this.subscription = this.consumer.subscriptions.create(
      { channel: "Emily::ConversationChannel", conversation_id: this.conversationId },
      {
        received: (data) => {
          // Skip user messages — already shown locally by send()
          if (data.role === "user") return

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

    if (response.status === 404) {
      this.clearStoredConversation()
      await this.startConversation()
      return
    }

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

  clearStoredConversation() {
    this.conversationId = null
    this.subscription?.unsubscribe()
    this.subscription = null
    try {
      window.sessionStorage.removeItem(this.constructor.storageKey)
    } catch (_e) {
      // no-op
    }
  }

  async send() {
    if (this.sending) return
    const content = this.inputTarget.value.trim()
    if (!content || !this.conversationId) return

    this.sending = true
    this.inputTarget.value = ""
    this.appendMessage("user", content)
    this.showTyping()

    try {
      await fetch(`${this.urlValue}/${this.conversationId}/messages`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ content, page: window.location.pathname })
      })
    } finally {
      this.sending = false
    }
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
      body: JSON.stringify({ content, page: window.location.pathname })
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

    const formatted = role === "assistant" ? this.renderMarkdown(content) : this.escapeHtml(content)
    let bubbleHtml = formatted

    // Add rating buttons inside the bubble for assistant messages
    if (role === "assistant" && messageId) {
      bubbleHtml += `
        <div class="emily-chat-widget__rating">
          <button data-score="2" onclick="this.closest('[data-controller]').__stimulusController.rate('${id}', 2)">&#128077;</button>
          <button data-score="1" onclick="this.closest('[data-controller]').__stimulusController.rate('${id}', 1)">&#128078;</button>
        </div>`
    }

    let html = `<div class="emily-chat-widget__bubble">${bubbleHtml}</div>`

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

  renderMarkdown(text) {
    let html = this.escapeHtml(text)
    // Bold: **text**
    html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    // Italic: *text*
    html = html.replace(/\*([^*]+)\*/g, '<em>$1</em>')
    // Inline code: `text`
    html = html.replace(/`([^`]+)`/g, '<code>$1</code>')
    // Unordered list items: - text
    html = html.replace(/^- (.+)$/gm, '<li>$1</li>')
    html = html.replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>')
    // Line breaks
    html = html.replace(/\n/g, '<br>')
    // Clean up <br> inside <ul>
    html = html.replace(/<ul><br>/g, '<ul>').replace(/<br><\/ul>/g, '</ul>')
    return html
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
