import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static classes = [ "active", "inactive" ]
  static targets = [ "btn", "tab" ]
  static values = {defaultTab: String}

  connect() {
    // First, hide all tabs and deactivate all buttons
    this.tabTargets.map(x => x.hidden = true)
    this.btnTargets.map(x => x.classList.remove(...this.activeClasses))
    this.btnTargets.map(x => x.classList.add(...this.inactiveClasses))

    // Then, show the default tab...
    let selectedTab = this.tabTargets.find(element => element.id === this.defaultTabValue)
    selectedTab.hidden = false

    // ...and activate the selected button
    let selectedBtn = this.btnTargets.find(element => element.id === this.defaultTabValue)
    selectedBtn.classList.remove(...this.inactiveClasses)
    selectedBtn.classList.add(...this.activeClasses)
  }

  select(event) {
    // First, find tab with same id as the clicked button
    let selectedTab = this.tabTargets.find(element => element.id === event.currentTarget.id)

    if (selectedTab.hidden) {
      // Hide everything if selection is changing...
      this.tabTargets.map(x => x.hidden = true)
      this.btnTargets.map(x => x.classList.remove(...this.activeClasses))
      this.btnTargets.map(x => x.classList.add(...this.inactiveClasses))

      // ...then show selected tab...
      selectedTab.hidden = false

      // ...and activate the clicked button
      event.currentTarget.classList.remove(...this.inactiveClasses)
      event.currentTarget.classList.add(...this.activeClasses)
    }
  }
}
