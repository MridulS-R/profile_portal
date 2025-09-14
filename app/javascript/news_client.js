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

  function buildCompactItem(a) {
    const item = document.createElement('div');
    item.className = 'news-item';
    if (a.image_url) {
      const thumb = document.createElement('div');
      thumb.className = 'thumb';
      const img = document.createElement('img');
      img.src = a.image_url; img.alt = 'thumbnail';
      thumb.appendChild(img);
      item.appendChild(thumb);
    }
    const body = document.createElement('div');
    const title = document.createElement('div');
    title.className = 'title';
    const link = document.createElement('a');
    link.href = a.url || '#';
    link.textContent = a.title || 'Untitled';
    link.target = '_blank'; link.rel = 'noopener';
    title.appendChild(link);
    const meta = document.createElement('div');
    meta.className = 'meta';
    const parts = [];
    if (a.source) parts.push(a.source);
    if (a.published_at) {
      try { parts.push(timeSince(new Date(a.published_at)) + ' ago'); } catch(_){}
    }
    meta.textContent = parts.join(' • ');
    const desc = document.createElement('div');
    desc.className = 'small text-muted';
    desc.textContent = a.description || '';
    body.appendChild(title);
    body.appendChild(meta);
    body.appendChild(desc);
    item.appendChild(body);
    return item;
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

  function buildTopSection(section) {
    const wrapper = document.createElement('div');
    wrapper.className = 'mb-4';
    const title = document.createElement('h4');
    title.className = 'h5 section-title';
    title.textContent = section.title || 'Top Stories';
    const row = document.createElement('div');
    row.className = 'row g-3';
    (section.articles || []).forEach(a => row.appendChild(buildCard(a)));
    wrapper.appendChild(title);
    wrapper.appendChild(row);
    return wrapper;
  }

  async function loadNews() {
    const list = document.getElementById('news-list');
    const top = document.getElementById('news-top');
    const pagination = document.getElementById('news-pagination');
    if (!list) return;
    const url = new URL(window.location.href);
    url.searchParams.set('category', list.dataset.category || 'general');
    url.searchParams.set('format', 'json');
    const page = parseInt(url.searchParams.get('page') || '1');
    const pageSize = parseInt(url.searchParams.get('page_size') || '12');
    const jsonUrl = `${url.pathname}${url.search}`;
    try {
      const res = await fetch(jsonUrl, { headers: { 'Accept': 'application/json' } });
      const data = await res.json();
      if (top) {
        top.innerHTML = '';
        if (data.top_stories && data.top_stories.length) {
          const fragTop = document.createDocumentFragment();
          data.top_stories.forEach(sec => fragTop.appendChild(buildTopSection(sec)));
          top.appendChild(fragTop);
        } else {
          top.innerHTML = '<div class="text-muted">No top stories at this time.</div>';
        }
      }
      // Render list in chosen mode
      const view = (localStorage.getItem('news_view') || 'cards');
      list.innerHTML = '';
      if (view === 'compact') {
        list.classList.add('news-compact');
        list.classList.remove('row','g-3');
        if (!data.articles || data.articles.length === 0) {
          list.innerHTML = '<div class="text-muted">No news found for this category.</div>';
        } else {
          const frag = document.createDocumentFragment();
          data.articles.forEach(a => frag.appendChild(buildCompactItem(a)));
          list.appendChild(frag);
        }
      } else {
        list.classList.remove('news-compact');
        list.classList.add('row','g-3');
        if (!data.articles || data.articles.length === 0) {
          const empty = document.createElement('div');
          empty.className = 'col-12 text-muted';
          empty.textContent = 'No news found for this category.';
          list.appendChild(empty);
        } else {
          const frag = document.createDocumentFragment();
          data.articles.forEach(a => frag.appendChild(buildCard(a)));
          list.appendChild(frag);
        }
      }

      // Pagination controls
      if (pagination) {
        const total = parseInt(data.total || 0);
        const totalPages = Math.max(1, Math.ceil(total / (data.page_size || pageSize)));
        const curPage = data.page || page;
        const prevBtn = document.getElementById('prev-page');
        const nextBtn = document.getElementById('next-page');
        const info = document.getElementById('page-info');
        if (info) info.textContent = `Page ${curPage} of ${totalPages}`;
        if (prevBtn) prevBtn.disabled = curPage <= 1;
        if (nextBtn) nextBtn.disabled = curPage >= totalPages;
        const changePage = (newPage) => {
          const newUrl = new URL(window.location.href);
          newUrl.searchParams.set('page', String(newPage));
          history.pushState({}, '', newUrl.toString());
          loadNews();
        };
        if (prevBtn) prevBtn.onclick = () => curPage > 1 && changePage(curPage - 1);
        if (nextBtn) nextBtn.onclick = () => curPage < totalPages && changePage(curPage + 1);
      }
    } catch (e) {
      list.innerHTML = '<div class="col-12 text-danger">Failed to load news.</div>';
    }
  }

  document.addEventListener('turbo:load', loadNews);
  document.addEventListener('DOMContentLoaded', loadNews);

  // View toggle buttons
  function initViewToggles() {
    const btnCards = document.getElementById('view-cards');
    const btnCompact = document.getElementById('view-compact');
    const setView = (v) => { try { localStorage.setItem('news_view', v); } catch(_){} loadNews(); };
    if (btnCards) btnCards.onclick = () => setView('cards');
    if (btnCompact) btnCompact.onclick = () => setView('compact');
  }
  document.addEventListener('turbo:load', initViewToggles);
  document.addEventListener('DOMContentLoaded', initViewToggles);
})();
