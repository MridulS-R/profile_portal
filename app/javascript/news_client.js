(() => {
  function buildCard(a) {
    const col = document.createElement('div');
    col.className = 'col-md-6';
    col.innerHTML = `
      <div class="card h-100 shadow-sm">
        <div class="card-body d-flex flex-column">
          <h5 class="card-title"></h5>
          <div class="meta small text-muted mb-2"></div>
          <div class="thumb"></div>
          <p class="card-text"></p>
          <div class="mt-auto d-flex justify-content-between align-items-center">
            <small class="text-muted time"></small>
            <a class="btn btn-outline-primary btn-sm" target="_blank" rel="noopener">Read More</a>
          </div>
        </div>
      </div>`;
    col.querySelector('.card-title').textContent = a.title || 'Untitled';
    if (a.source) col.querySelector('.meta').textContent = `Source: ${a.source}`;
    else col.querySelector('.meta').remove();
    if (a.image_url) {
      const img = document.createElement('img');
      img.src = a.image_url;
      img.alt = 'thumbnail';
      img.className = 'img-fluid rounded mb-2';
      col.querySelector('.thumb').appendChild(img);
    } else {
      col.querySelector('.thumb').remove();
    }
    col.querySelector('.card-text').textContent = a.description || '';
    const link = col.querySelector('a');
    link.href = a.url || '#';
    const timeEl = col.querySelector('.time');
    if (a.published_at) {
      try {
        const dt = new Date(a.published_at);
        const ago = timeSince(dt);
        timeEl.textContent = `${ago} ago`;
      } catch (_) { timeEl.remove(); }
    } else {
      timeEl.remove();
    }
    return col;
  }

  function timeSince(date) {
    const seconds = Math.floor((new Date() - date) / 1000);
    const intervals = [
      ['year', 31536000], ['month', 2592000], ['day', 86400], ['hour', 3600], ['minute', 60]
    ];
    for (const [name, secs] of intervals) {
      const val = Math.floor(seconds / secs);
      if (val >= 1) return `${val} ${name}${val>1?'s':''}`;
    }
    return `${seconds} seconds`;
  }

  async function loadNews() {
    const list = document.getElementById('news-list');
    if (!list) return;
    const url = new URL(window.location.href);
    url.searchParams.set('category', list.dataset.category || 'general');
    url.searchParams.set('format', 'json');
    const jsonUrl = `${url.pathname}${url.search}`;
    try {
      const res = await fetch(jsonUrl, { headers: { 'Accept': 'application/json' } });
      const data = await res.json();
      list.innerHTML = '';
      if (!data.articles || data.articles.length === 0) {
        const empty = document.createElement('div');
        empty.className = 'col-12 text-muted';
        empty.textContent = 'No news found for this category.';
        list.appendChild(empty);
        return;
      }
      const frag = document.createDocumentFragment();
      data.articles.forEach(a => frag.appendChild(buildCard(a)));
      list.appendChild(frag);
    } catch (e) {
      list.innerHTML = '<div class="col-12 text-danger">Failed to load news.</div>';
    }
  }

  document.addEventListener('turbo:load', loadNews);
  document.addEventListener('DOMContentLoaded', loadNews);
})();
