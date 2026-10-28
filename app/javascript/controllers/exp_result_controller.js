import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "levelText", "levelUpMessage", "expText"]
  static values = {
    prevLevel: Number,
    newLevel: Number,
    prevPercentage: Number,
    newPercentage: Number,
    newExpText: String
  }

  connect() {
    this.track = this.barTarget.closest('[role="progressbar"]')
    this.barTarget.style.width = `${this.prevPercentageValue}%`
    this.track?.setAttribute("aria-valuenow", this.prevPercentageValue)
    this.animationTimeout = setTimeout(() => {
      this.animationFrame = requestAnimationFrame(() => this.animateProgress(this.prevLevelValue))
    }, 500)
  }

  disconnect() {
    cancelAnimationFrame(this.animationFrame)
    clearTimeout(this.animationTimeout)
  }

  close(event) {
    event.preventDefault()
    this.element.remove()
  }

  animateProgress(level) {
    if (level >= this.newLevelValue) {
      if (this.hasExpTextTarget) {
        this.expTextTarget.textContent = this.newExpTextValue
      }
      this.levelTextTarget.textContent = `Lv. ${this.newLevelValue}`
      this.animateBar(this.newPercentageValue)
      if (this.prevLevelValue !== this.newLevelValue) {
        this.animationTimeout = setTimeout(() => {
          this.levelUpMessageTarget.hidden = false
        }, 950)
      }
      return
    }

    this.animateBar(100)
    this.animationTimeout = setTimeout(() => {
      const nextLevel = level + 1
      this.levelTextTarget.textContent = `Lv. ${nextLevel}`

      this.barTarget.style.transition = "none"
      this.animateBar(0)
      
      this.barTarget.offsetWidth 

      this.barTarget.style.transition = ""

      this.animationTimeout = setTimeout(() => this.animateProgress(nextLevel), 80)
    }, 950)
  }

  animateBar(percentage) {
    this.barTarget.style.width = `${percentage}%`
    this.track?.setAttribute("aria-valuenow", percentage)
  }
}
