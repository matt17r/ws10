import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "row"]

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()

    this.rowTargets.forEach(row => {
      const text = row.dataset.searchText.toLowerCase()
      row.hidden = !text.includes(query)
    })
  }
}
