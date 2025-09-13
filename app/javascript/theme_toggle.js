(() => {
  const btnSelector = '#theme-toggle';
  const getMeta = (name) => document.querySelector(`meta[name="${name}"]`)?.getAttribute('content');
  const csrfToken = getMeta('csrf-token');

  function applyTheme(theme) {
    const body = document.body;
    body.classList.remove('bg-light', 'bg-dark', 'text-light');
    if (theme === 'dark') {
      body.classList.add('bg-dark', 'text-light');
    } else {
      body.classList.add('bg-light');
    }
  }

  function persist(theme) {
    try { localStorage.setItem('theme', theme); } catch(e) {}
  }

  document.addEventListener('turbo:load', () => {
    const btn = document.querySelector(btnSelector);
    if (!btn) return;
    // Initialize from localStorage if present
    const stored = localStorage.getItem('theme');
    if (stored) applyTheme(stored);
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const currentDark = document.body.classList.contains('bg-dark');
      const next = currentDark ? 'light' : 'dark';
      applyTheme(next);
      persist(next);
      const url = btn.dataset.updateUrl;
      const canPersistServer = btn.dataset.canPersist === 'true';
      if (canPersistServer && url && csrfToken) {
        fetch(url, {
          method: 'PATCH',
          headers: { 'X-CSRF-Token': csrfToken, 'Accept': 'text/vnd.turbo-stream.html' },
          body: new URLSearchParams({ 'user[theme]': next })
        }).catch(() => {});
      }
    });
  });
})();

