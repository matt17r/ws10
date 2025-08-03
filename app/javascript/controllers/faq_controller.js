import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const hash = window.location.hash
    this.addCopyButtons()

    if (hash) {
      const target = document.querySelector(hash)
      if (target && target.tagName === "DT") {
        this.highlight(target)
      }
    }
  }

  addCopyButtons() {
    const dts = this.element.querySelectorAll("dt[id]")
    dts.forEach(dt => {
      if (!dt.querySelector("button")) {
        const button = document.createElement("button")
        button.textContent = "🔗"
        button.className = "ml-2 text-sm text-[#DB2955] cursor-pointer"
        button.addEventListener("click", () => this.copyLink(dt, button))
        dt.appendChild(button)
      }
    })
  }

  copyLink(dt, button) {
    const id = dt.id
    const url = `${window.location.origin}${window.location.pathname}#${id}`
    navigator.clipboard.writeText(url).then(() => {
      button.textContent = "Link copied"
      setTimeout(() => (button.textContent = "🔗"), 1000)
    }).catch(err => {
      console.error("Failed to copy: ", err)
    })
  }

  highlight(dt) {
    dt.classList.add("bg-yellow-100", "transition-colours", "duration-1000")
    setTimeout(() => {
      dt.classList.remove("bg-yellow-100")
    }, 3000)
  }
}
