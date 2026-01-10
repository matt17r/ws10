import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "source", "button" ]
  static values = {
    successText: { type: String, default: "Copied!" },
    timeout: { type: Number, default: 2000 }
  }

  copy() {
    const text = this.sourceTarget.textContent.trim()
    navigator.clipboard.writeText(text).then(() => {
      const originalText = this.buttonTarget.textContent
      this.buttonTarget.textContent = this.successTextValue

      setTimeout(() => {
        this.buttonTarget.textContent = originalText
      }, this.timeoutValue)
    })
  }
}
