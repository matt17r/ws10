import { Controller } from "@hotwired/stimulus"

const STRAVA_URL_REPLACEMENT = "ws10\u2022run"

export default class extends Controller {
  static targets = [ "textarea", "submitButton" ]
  static values = { siteUrl: String, stravaUrl: String }

  loadTemplate(event) {
    event.preventDefault()
    const templateId = `template-${event.params.template}`
    const content = document.getElementById(templateId)?.textContent
    if (content !== undefined) {
      this.textareaTarget.value = content
      this.textareaTarget.focus()
    }
  }

  schedulePost() {
    navigator.clipboard.writeText(this.stravaText())
    window.open(this.stravaUrlValue, "_blank")
  }

  handleSubmitEnd(event) {
    if (event.detail.success) {
      this.submitButtonTargets.forEach(btn => {
        btn.disabled = true
        btn.classList.remove("bg-blue-600", "hover:bg-blue-700", "cursor-pointer")
        btn.classList.add("bg-gray-400", "cursor-not-allowed")
      })
    }
  }

  stravaText() {
    const urlPattern = new RegExp(this.siteUrlValue.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\\S*", "g")
    return this.textareaTarget.value.replace(urlPattern, STRAVA_URL_REPLACEMENT)
  }
}
