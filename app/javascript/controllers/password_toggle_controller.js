import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "fields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const show = this.checkboxTarget.checked
    this.fieldsTarget.classList.toggle("hidden", !show)

    // Find all form controls inside fieldsTarget and set required based on visibility
    const inputs = this.fieldsTarget.querySelectorAll("input, select, textarea")
    inputs.forEach(input => {
      input.required = show
    })
  }
}
