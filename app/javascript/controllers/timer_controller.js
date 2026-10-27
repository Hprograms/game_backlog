import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "time", "floating"]

  connect() {
    this.intervalId = null
    this.startedAt = null
    this.elapsedSeconds = 0
  }

  disconnect() {
    this.clearTimer()
  }

  floatingTargetConnected() {
    if (this.intervalId) {
      this.floatingTarget.hidden = false
      this.titleTarget.textContent = this.gameTitle
      this.updateTime()
    }
  }

  start(event) {
    const { gameId, gameTitle } = event.currentTarget.dataset
    this.gameId = gameId
    this.gameTitle = gameTitle
    this.titleTarget.textContent = this.gameTitle
    this.elapsedSeconds = 0
    this.startedAt = Date.now()
    this.timeTarget.textContent = "00:00:00"
    this.floatingTarget.hidden = false

    this.clearTimer()
    this.intervalId = setInterval(() => this.updateTime(), 1000)
  }

  stop() {
    this.elapsedSeconds = Math.floor((Date.now() - this.startedAt) / 1000)
    this.clearTimer()
    this.floatingTarget.hidden = true
    alert(`プレイ時間: ${Math.floor(this.elapsedSeconds / 60)}分`)
  }

  updateTime() {
    this.elapsedSeconds = Math.floor((Date.now() - this.startedAt) / 1000)
    const hours = Math.floor(this.elapsedSeconds / 3600)
    const minutes = Math.floor((this.elapsedSeconds % 3600) / 60)
    const seconds = this.elapsedSeconds % 60
    this.timeTarget.textContent = [hours, minutes, seconds]
      .map(value => String(value).padStart(2, "0"))
      .join(":")
  }

  clearTimer() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
  }
}
