import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["claimSelf", "claimFriend", "toggleCheckbox"]

  connect() {
    this.updateView()
  }

  showFriendForm(event) {
    event.preventDefault()
    // Show friend form temporarily without enabling helper mode
    if (this.hasClaimSelfTarget) this.claimSelfTarget.classList.add("hidden")
    if (this.hasClaimFriendTarget) this.claimFriendTarget.classList.remove("hidden")
  }

  toggle(event) {
    const enabled = event.target.checked
    localStorage.setItem("finishHelperMode", enabled.toString())
    this.updateView()
  }

  updateView() {
    const enabled = localStorage.getItem("finishHelperMode") === "true"

    // Sync checkbox state with localStorage
    if (this.hasToggleCheckboxTarget) {
      this.toggleCheckboxTarget.checked = enabled
    }

    if (enabled) {
      // Show friend form, hide self claim
      if (this.hasClaimSelfTarget) this.claimSelfTarget.classList.add("hidden")
      if (this.hasClaimFriendTarget) this.claimFriendTarget.classList.remove("hidden")
    } else {
      // Show self claim, hide friend form
      if (this.hasClaimSelfTarget) this.claimSelfTarget.classList.remove("hidden")
      if (this.hasClaimFriendTarget) this.claimFriendTarget.classList.add("hidden")
    }
  }
}
