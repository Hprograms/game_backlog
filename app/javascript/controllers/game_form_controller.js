import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "file", "rating", "star", "title", "suggestions", "metadata", "metascore", "averagePlaytime", "metascoreLabel", "playtimeLabel", "imageUrl", "platform", "genre"]
  static values = { searchUrl: String }

  connect() {
    this.updateStars(parseInt(this.ratingTarget.value) || 0)
    this.selectedSuggestionIndex = -1
  }

  // --- 画像アップロードの処理 ---
  triggerUpload(event) {
    if (event.target.closest('.btn-clear-image')) return
    this.fileTarget.click()
  }

  previewImage(event) {
    const file = event.target.files[0]
    if (file) {
      this.imageUrlTarget.value = ""
      const reader = new FileReader()
      reader.onload = (e) => {
        this.previewTarget.src = e.target.result
        this.previewTarget.classList.remove('d-none')
      }
      reader.readAsDataURL(file)
    }
  }

  clearImage(event) {
    event.preventDefault()
    event.stopPropagation()
    this.fileTarget.value = ""
    this.imageUrlTarget.value = ""
    this.previewTarget.src = ""
    this.previewTarget.classList.add('d-none')
  }

  search() {
    clearTimeout(this.searchTimeout)
    const query = this.titleTarget.value.trim()
    if (query.length < 2) {
      this.closeSuggestions()
      return
    }

    this.searchTimeout = setTimeout(() => this.fetchSuggestions(query), 300)
  }

  async fetchSuggestions(query) {
    this.abortController?.abort()
    this.abortController = new AbortController()

    try {
      const url = new URL(this.searchUrlValue, window.location.origin)
      url.searchParams.set("query", query)
      const response = await fetch(url, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })
      if (!response.ok) throw new Error("ゲーム候補を取得できませんでした")
      const games = await response.json()
      if (query !== this.titleTarget.value.trim()) return
      this.renderSuggestions(games)
    } catch (error) {
      if (error.name !== "AbortError") this.closeSuggestions()
    }
  }

  renderSuggestions(games) {
    this.suggestionsTarget.replaceChildren()
    this.selectedSuggestionIndex = -1

    games.forEach((game, index) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "suggestion-item"
      button.setAttribute("role", "option")
      button.dataset.index = index
      button.addEventListener("click", () => this.selectSuggestion(game))

      if (game.image) {
        const image = document.createElement("img")
        image.src = game.image
        image.alt = ""
        image.loading = "lazy"
        button.append(image)
      } else {
        const placeholder = document.createElement("span")
        placeholder.className = "suggestion-placeholder material-symbols-outlined"
        placeholder.textContent = "sports_esports"
        button.append(placeholder)
      }

      const name = document.createElement("span")
      name.className = "suggestion-name"
      name.textContent = game.name
      button.append(name)
      this.suggestionsTarget.append(button)
    })

    this.suggestionsTarget.hidden = games.length === 0
  }

  selectSuggestion(game) {
    this.titleTarget.value = game.name || ""
    this.metascoreTarget.value = game.metacritic ?? ""
    this.averagePlaytimeTarget.value = game.playtime ?? ""
    this.metascoreLabelTarget.textContent = game.metacritic ?? "--"
    this.playtimeLabelTarget.textContent = game.playtime ? `${game.playtime}h` : "--"
    this.metadataTarget.hidden = false
    this.imageUrlTarget.value = game.image || ""

    if (game.image) {
      this.previewTarget.src = game.image
      this.previewTarget.classList.remove("d-none")
    }
    this.selectMatchingOption(this.platformTarget, game.platforms)
    this.selectMatchingOption(this.genreTarget, game.genres)
    this.closeSuggestions()
  }

  selectMatchingOption(select, values) {
    const matchingOption = Array.from(select.options).find(option => values?.includes(option.value))
    if (matchingOption) select.value = matchingOption.value
  }

  navigateSuggestions(event) {
    const items = Array.from(this.suggestionsTarget.querySelectorAll(".suggestion-item"))
    if (this.suggestionsTarget.hidden || items.length === 0) return

    if (event.key === "Escape") {
      this.closeSuggestions()
      return
    }
    if (event.key === "Enter" && this.selectedSuggestionIndex >= 0) {
      event.preventDefault()
      const selectedItem = items[this.selectedSuggestionIndex]
      selectedItem?.click()
      return
    }
    if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return

    event.preventDefault()
    const direction = event.key === "ArrowDown" ? 1 : -1
    this.selectedSuggestionIndex = this.selectedSuggestionIndex < 0
      ? (direction === 1 ? 0 : items.length - 1)
      : (this.selectedSuggestionIndex + direction + items.length) % items.length
    items.forEach((item, index) => item.setAttribute("aria-selected", index === this.selectedSuggestionIndex))
    items[this.selectedSuggestionIndex].scrollIntoView({ block: "nearest" })
  }

  closeSuggestions() {
    this.suggestionsTarget.hidden = true
    this.suggestionsTarget.replaceChildren()
    this.selectedSuggestionIndex = -1
  }

  // --- 星評価の処理 ---
  hoverStar(event) {
    this.updateStars(parseInt(event.currentTarget.dataset.value))
  }

  clickStar(event) {
    event.preventDefault()
    this.ratingTarget.value = parseInt(event.currentTarget.dataset.value, 10)
    this.updateStars(parseInt(this.ratingTarget.value, 10))
  }

  resetStars() {
    this.updateStars(parseInt(this.ratingTarget.value) || 0)
  }

  updateStars(value) {
    this.starTargets.forEach(star => {
      if (parseInt(star.dataset.value, 10) <= value) {
        star.classList.add('active')
        star.style.fontVariationSettings = "'FILL' 1"
      } else {
        star.classList.remove('active')
        star.style.fontVariationSettings = "'FILL' 0"
      }
    })
  }
}