document.addEventListener('turbo:load', function() {
  const togglePassword = document.querySelector('#toggle-password');
  const passwordInput = document.querySelector('#password-input');
  const toggleIcon = document.querySelector('#toggle-icon');

  if (togglePassword && passwordInput) {
    togglePassword.addEventListener('click', function () {
      // type属性をパスワードからテキストに切り替え
      const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
      passwordInput.setAttribute('type', type);
      
      // アイコンの切り替え (eye <-> eye-slash)
      toggleIcon.classList.toggle('fa-eye');
      toggleIcon.classList.toggle('fa-eye-slash');
    });
  }
});