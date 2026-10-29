import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "time", "floating", "content", "statusModal", "resultTime", "error", "warning", "clearCheck", "clearWarning", "saveButton"]

  connect() {
    this.intervalId = null
    this.startedAt = null
    this.elapsedSeconds = 0
  }

  disconnect() {
    this.clearTimer()
    clearTimeout(this.warningTimeout)
  }

  floatingTargetConnected() {
    if (this.intervalId) {
      this.floatingTarget.hidden = false
      this.titleTarget.textContent = this.gameTitle
      this.updateTime()
    }
  }

  start(event) {
    if (this.intervalId || this.startedAt) {
      if (this.hasWarningTarget) {
        this.warningTarget.hidden = false
        clearTimeout(this.warningTimeout)
        this.warningTimeout = setTimeout(() => { this.warningTarget.hidden = true }, 3000)
      }
      return
    }

    const { gameId, gameTitle } = event.currentTarget.dataset
    this.gameId = gameId
    this.gameTitle = gameTitle
    this.titleTarget.textContent = this.gameTitle
    this.elapsedSeconds = 0
    this.startedAt = Date.now()
    this.contentTarget.hidden = false
    this.statusModalTarget.hidden = true
    this.errorTarget.hidden = true
    this.errorTarget.textContent = ""
    this.timeTarget.textContent = "00:00:00"
    this.floatingTarget.hidden = false
    clearTimeout(this.warningTimeout)
    if (this.hasWarningTarget) this.warningTarget.hidden = true

    this.clearTimer()
    this.intervalId = setInterval(() => this.updateTime(), 1000)
    this.highlightCard(this.gameId)
  }

  stop() {
    if (!this.startedAt) return

    this.elapsedSeconds = Math.floor((Date.now() - this.startedAt) / 1000)
    this.clearTimer()
    this.resultMinutes = Math.floor(this.elapsedSeconds / 60)
    this.resultTimeTarget.textContent = this.resultMinutes
    this.contentTarget.hidden = true
    this.statusModalTarget.hidden = false
  }

  toggleClearWarning() {
    if (this.clearCheckTarget.checked) {
      this.clearWarningTarget.hidden = false
      this.saveButtonTarget.textContent = "クリアしてEXPを獲得！"
      this.saveButtonTarget.classList.replace("btn-primary", "btn-warning")
    } else {
      this.clearWarningTarget.hidden = true
      this.saveButtonTarget.textContent = "EXPを獲得する"
      this.saveButtonTarget.classList.replace("btn-warning", "btn-primary")
    }
  }

  save(event) {
    event.preventDefault()
    const status = this.clearCheckTarget.checked ? "クリア済" : "プレイ中"
    this.submitTimerResult(status)
  }

  cancel(event) {
    event.preventDefault()
    if (!window.confirm("これまでの計測時間が失われます。本当に破棄しますか？")) return

    this.clearTimer()
    this.statusModalTarget.hidden = true
    this.floatingTarget.hidden = true
    this.startedAt = null
    this.gameId = null
    this.removeHighlight()
    this.resetClearCheck()
  }

  async submitTimerResult(status) {
    if (this.submitting || !this.gameId) return

    this.submitting = true
    this.errorTarget.hidden = true
    this.errorTarget.textContent = ""

    try {
      const response = await fetch(`/games/${encodeURIComponent(this.gameId)}/timer_update`, {
        method: "POST",
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || ""
        },
        body: JSON.stringify({
          play_time_minutes: this.resultMinutes,
          status
        })
      })

      if (!response.ok) {
        const message = (await response.text()).trim()
        throw new Error(message || "プレイ記録を保存できませんでした。")
      }

      const stream = await response.text()
      if (!window.Turbo?.renderStreamMessage) {
        throw new Error("EXPリザルトを表示できませんでした。ページを再読み込みしてください。")
      }
      window.Turbo.renderStreamMessage(stream)
      this.floatingTarget.hidden = true
      this.startedAt = null
      this.gameId = null
      this.removeHighlight()
    } catch (error) {
      this.errorTarget.textContent = error.message || "プレイ記録を保存できませんでした。"
      this.errorTarget.hidden = false
    } finally {
      this.submitting = false
      this.resetClearCheck()
    }
  }

  resetClearCheck() {
    if (this.hasClearCheckTarget) {
      this.clearCheckTarget.checked = false
      this.toggleClearWarning()
    }
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

  highlightCard(gameId) {
    const playButton = document.querySelector(`button[data-game-id="${gameId}"]`)
    playButton?.closest(".game-poster-card")?.classList.add("is-active-timer")
  }

  removeHighlight() {
    document.querySelectorAll(".game-poster-card.is-active-timer").forEach(card => {
      card.classList.remove("is-active-timer")
    })
  }
}
