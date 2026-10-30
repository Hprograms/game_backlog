import { Controller } from "@hotwired/stimulus"
import confetti from "canvas-confetti"

export default class extends Controller {
  static targets = ["closeButton"]

  connect() {
    this.confettiTimeout = setTimeout(() => {
      confetti({
        particleCount: 120,
        spread: 85,
        origin: { y: 0.6 },
        colors: ["#fbbf24", "#67e8f9", "#c084fc", "#f8fafc"],
        disableForReducedMotion: true,
        zIndex: 1300
      })
      if (this.hasCloseButtonTarget) {
        this.closeButtonTarget.hidden = false
        this.closeButtonTarget.classList.add("animate-in")
      }
    }, 300)
  }

  disconnect() {
    clearTimeout(this.confettiTimeout)
  }

  close(event) {
    event.preventDefault()
    this.element.remove()
  }
}
