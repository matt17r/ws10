import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: Number }

  connect() {
    this.timeout = setTimeout(() => this.close(), this.delayValue || 10000)
  }

  close() {
    clearTimeout(this.timeout)
    this.fadeOut()
  }

  fadeOut() {
    this.element.classList.add("opacity-0")
    setTimeout(() => this.element.remove(), 500) // match transition duration from Tailwind class
  }
}
