import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "levelText", "levelUpMessage"]
  static values = {
    prevLevel: Number,
    newLevel: Number,
    prevPercentage: Number,
    newPercentage: Number
  }

  connect() {
    this.animationTimeouts = new Set()
    this.barTarget.style.width = `${this.prevPercentageValue}%`
    this.animateProgress()
  }

  disconnect() {
    this.animationTimeouts.forEach(clearTimeout)
    this.animationTimeouts.clear()
  }

  close() {
    this.element.remove()
  }

  async animateProgress() {
    await this.wait(300)
    if (!this.element.isConnected) return

    const levelsGained = this.newLevelValue - this.prevLevelValue
    if (levelsGained <= 0) {
      this.barTarget.style.width = `${this.newPercentageValue}%`
      return
    }

    let currentLevel = this.prevLevelValue
    for (let level = 0; level < levelsGained; level += 1) {
      this.barTarget.style.width = "100%"
      await this.wait(500)
      if (!this.element.isConnected) return

      this.barTarget.style.transition = "none"
      this.barTarget.style.width = "0%"
      this.barTarget.offsetWidth
      this.barTarget.style.transition = ""

      currentLevel += 1
      this.levelTextTarget.textContent = `Lv. ${currentLevel}`
    }

    this.barTarget.style.width = `${this.newPercentageValue}%`
    this.levelUpMessageTarget.hidden = false
  }

  wait(duration) {
    return new Promise((resolve) => {
      const timeout = setTimeout(() => {
        this.animationTimeouts.delete(timeout)
        resolve()
      }, duration)
      this.animationTimeouts.add(timeout)
    })
  }
}
