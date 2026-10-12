import { Controller } from "@hotwired/stimulus"

const loadClerk = () => {
  if (!window.Clerk) {
    throw new Error("ClerkJS failed to load")
  }

  window.clerkLoadPromise ||= window.Clerk.load({
    ui: { ClerkUI: window.__internal_ClerkUICtor },
  })

  return window.clerkLoadPromise
}

export default class extends Controller {
  static targets = ["signIn", "signUp", "userButton", "error"]
  static values = {
    signInUrl: String,
    signUpUrl: String,
    redirectUrl: String,
  }

  async connect() {
    try {
      await loadClerk()
      if (!this.element.isConnected) return

      if (this.hasSignInTarget) {
        window.Clerk.mountSignIn(this.signInTarget, {
          signUpUrl: this.signUpUrlValue,
          fallbackRedirectUrl: this.redirectUrlValue,
        })
      }

      if (this.hasSignUpTarget) {
        window.Clerk.mountSignUp(this.signUpTarget, {
          signInUrl: this.signInUrlValue,
          fallbackRedirectUrl: this.redirectUrlValue,
        })
      }

      if (this.hasUserButtonTarget) {
        window.Clerk.mountUserButton(this.userButtonTarget, {
          afterSignOutUrl: "/",
        })
      }
    } catch (error) {
      console.error("Failed to initialize Clerk authentication UI", error)
      if (this.hasErrorTarget) {
        this.errorTarget.textContent = "認証画面の読み込みに失敗しました。時間をおいて再度お試しください。"
        this.errorTarget.hidden = false
      }
    }
  }

  disconnect() {
    if (!window.Clerk) return

    if (this.hasSignInTarget) window.Clerk.unmountSignIn(this.signInTarget)
    if (this.hasSignUpTarget) window.Clerk.unmountSignUp(this.signUpTarget)
    if (this.hasUserButtonTarget) window.Clerk.unmountUserButton(this.userButtonTarget)
  }
}
