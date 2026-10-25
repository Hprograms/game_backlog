import { Controller } from "@hotwired/stimulus"

const waitForClerk = () => {
  return new Promise((resolve, reject) => {
    if (window.Clerk) return resolve();
    let attempts = 0;
    const interval = setInterval(() => {
      if (window.Clerk) {
        clearInterval(interval);
        resolve();
      } else if (attempts > 50) {
        clearInterval(interval);
        reject(new Error("ClerkJS failed to load"));
      }
      attempts++;
    }, 100);
  });
};

const loadClerk = async () => {
  await waitForClerk();

  let localization;

  try {
    const loc = await import("https://cdn.jsdelivr.net/npm/@clerk/localizations@3/+esm");
    localization = loc.jaJP;
  } catch (e) {
    console.warn("Clerkの日本語化パッケージの取得に失敗しました。デフォルト設定で起動します。", e);
  }

  const customLocalization = localization ? {
    ...localization,
    signIn: {
      ...localization.signIn,
      start: {
        title: "ログイン",
        subtitle: "おかえりなさい！ゲームの記録を続けましょう",
        actionText: "アカウントをお持ちでないですか？",
        actionLink: "新規登録",
      },
    },
    signUp: {
      ...localization.signUp,
      start: {
        title: "新規登録",
        subtitle: "アカウントを作成してゲームの記録を始めましょう",
        actionText: "すでにアカウントをお持ちですか？",
        actionLink: "ログイン",
      },
    },
  } : undefined;

  window.clerkLoadPromise ||= window.Clerk.load({
    ui: { ClerkUI: window.__internal_ClerkUICtor },
    localization: customLocalization,
  });
  return window.clerkLoadPromise;
};

export default class extends Controller {
  static targets = ["signIn", "signUp", "userButton", "error"]
  static values = {
    signInUrl: String,
    signUpUrl: String,
    redirectUrl: String,
  }

  async connect() {
    try {
      await loadClerk();
      if (!this.element.isConnected) return;

      if (this.hasSignInTarget) {
        window.Clerk.mountSignIn(this.signInTarget, {
          signUpUrl: this.signUpUrlValue,
          fallbackRedirectUrl: this.redirectUrlValue,
        });
      }

      if (this.hasSignUpTarget) {
        window.Clerk.mountSignUp(this.signUpTarget, {
          signInUrl: this.signInUrlValue,
          fallbackRedirectUrl: this.redirectUrlValue,
        });
      }

      if (this.hasUserButtonTarget) {
        window.Clerk.mountUserButton(this.userButtonTarget, {
          afterSignOutUrl: "/",
        });
      }
    } catch (error) {
      console.error("Failed to initialize Clerk authentication UI", error);
      if (this.hasErrorTarget) {
        this.errorTarget.textContent = "認証UIの読み込みに失敗しました。ページをリロードしてください。";
        this.errorTarget.hidden = false;
      }
    }
  }

  disconnect() {
    if (!window.Clerk) return;

    if (this.hasSignInTarget) {
      window.Clerk.unmountSignIn(this.signInTarget);
      this.signInTarget.innerHTML = "";
    }

    if (this.hasSignUpTarget) {
      window.Clerk.unmountSignUp(this.signUpTarget);
      this.signUpTarget.innerHTML = "";
    }

    if (this.hasUserButtonTarget) {
      window.Clerk.unmountUserButton(this.userButtonTarget);
      this.userButtonTarget.innerHTML = "";
    }
  }
}