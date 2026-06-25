import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "file", "rating", "star"]

  connect() {
    this.updateStars(parseInt(this.ratingTarget.value) || 0)
  }

  // --- 画像アップロードの処理 ---
  triggerUpload(event) {
    if (event.target.closest('.btn-clear-image')) return
    this.fileTarget.click()
  }

  previewImage(event) {
    const file = event.target.files[0]
    if (file) {
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
    this.previewTarget.src = ""
    this.previewTarget.classList.add('d-none')
  }

  // --- 星評価の処理 ---
  hoverStar(event) {
    this.updateStars(parseInt(event.currentTarget.dataset.value))
  }

  clickStar(event) {
    event.preventDefault()
    this.ratingTarget.value = parseInt(event.currentTarget.dataset.value)
    this.updateStars(this.ratingTarget.value)
  }

  resetStars() {
    this.updateStars(parseInt(this.ratingTarget.value) || 0)
  }

  updateStars(value) {
    this.starTargets.forEach(s => {
      if (parseInt(s.dataset.value) <= value) {
        s.classList.add('active')
        s.style.fontVariationSettings = "'FILL' 1" 
      } else {
        s.classList.remove('active')
        s.style.fontVariationSettings = "'FILL' 0"
      }
    })
  }
}