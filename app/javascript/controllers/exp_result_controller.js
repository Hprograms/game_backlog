import { Controller } from "@hotwired/stimulus"
import confetti from "canvas-confetti"

export default class extends Controller {
  static targets = ["bar", "levelText", "levelUpLogo", "expText", "closeButton"]
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
    clearTimeout(this.confettiTimeout)
    clearTimeout(this.closeButtonTimeout)
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
      const transitionDuration = 950

      if (this.prevLevelValue !== this.newLevelValue) {
        this.animationTimeout = setTimeout(() => {
          if (this.hasLevelUpLogoTarget) {
            this.levelUpLogoTarget.hidden = false
          }
          this.confettiTimeout = setTimeout(() => this.fireCrossConfetti(), 150)
          this.showCloseButton(1400)
        }, transitionDuration)
      } else {
        this.showCloseButton(transitionDuration)
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

  showCloseButton(delay) {
    this.closeButtonTimeout = setTimeout(() => {
      if (this.hasCloseButtonTarget) {
        this.closeButtonTarget.hidden = false
        this.closeButtonTarget.classList.add("animate-in")
      }
    }, delay)
  }

  fireCrossConfetti() {
    const leftBounds = this.levelUpLogoTarget.querySelector(".cracker-left").getBoundingClientRect()
    const rightBounds = this.levelUpLogoTarget.querySelector(".cracker-right").getBoundingClientRect()
    const commonOptions = {
      particleCount: 30,
      spread: 60,
      shapes: ["square"],
      flat: true,
      scalar: 1.2,
      colors: ["#f8b700", "#f83800", "#00b800", "#008888", "#fcbc20", "#f878f8"],
      disableForReducedMotion: true,
      zIndex: 1300
    }

    confetti({
      ...commonOptions,
      angle: 45,
      origin: {
        x: (leftBounds.left + leftBounds.width / 2) / window.innerWidth,
        y: (leftBounds.top + leftBounds.height / 2) / window.innerHeight
      }
    })

    confetti({
      ...commonOptions,
      angle: 135,
      origin: {
        x: (rightBounds.left + rightBounds.width / 2) / window.innerWidth,
        y: (rightBounds.top + rightBounds.height / 2) / window.innerHeight
      }
    })
  }
}
