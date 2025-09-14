(() => {
  function buildCard(a) {
    const col = document.createElement('div');
    col.className = 'col-12 col-sm-6 col-lg-4';
    col.innerHTML = `
      <div class="card card-news h-100">
        <div class="card-body">
          <h5 class="card-title mt-1"></h5>
          <div class="meta mb-2"></div>
          <p class="card-text"></p>
          <div class="mt-auto d-flex justify-content-between align-items-center">
            <small class="text-muted time"></small>
            <a class="btn btn-soft-primary btn-sm" target="_blank" rel="noopener">Read More</a>
          </div>
        </div>
      </div>`;
    col.querySelector('.card-title').textContent = a.title || 'Untitled';
    const metaEl = col.querySelector('.meta');
    metaEl.textContent = a.source ? `Source: ${a.source}` : '';
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

  function buildPill(a) {
    const link = document.createElement('a');
    link.className = 'pill';
    link.href = a.url || '#';
    link.target = '_blank'; link.rel = 'noopener';
    link.textContent = a.title || 'Untitled';
    return link;
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
    const hero = document.getElementById('news-hero');
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
      // Render hero from first category article (fallback to first top story)
      if (hero) {
        const heroEl = hero.querySelector('.news-hero');
        const content = heroEl.querySelector('.content');
        const titleEl = content.querySelector('.title');
        const metaEl = content.querySelector('.meta');
        const actionsEl = content.querySelector('.actions');
        let heroArticle = (data.articles && data.articles[0]) || (data.top_stories && data.top_stories[0] && data.top_stories[0].articles && data.top_stories[0].articles[0]) || null;
        if (heroArticle) {
          titleEl.textContent = heroArticle.title || 'Untitled';
          const parts = [];
          if (heroArticle.source) parts.push(heroArticle.source);
          if (heroArticle.published_at) { try { parts.push(timeSince(new Date(heroArticle.published_at)) + ' ago'); } catch(_){} }
          metaEl.textContent = parts.join(' • ');
          actionsEl.innerHTML = '';
          const btn = document.createElement('a');
          btn.href = heroArticle.url || '#';
          btn.target = '_blank'; btn.rel = 'noopener';
          btn.className = 'btn btn-soft-primary btn-sm';
          btn.textContent = 'Read More';
          actionsEl.appendChild(btn);
        }
      }
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
        list.classList.remove('news-pills');
        if (!data.articles || data.articles.length === 0) {
          list.innerHTML = '<div class="text-muted">No news found for this category.</div>';
        } else {
          const frag = document.createDocumentFragment();
          const items = data.articles.slice( (hero ? 1 : 0) );
          items.forEach(a => frag.appendChild(buildCompactItem(a)));
          list.appendChild(frag);
        }
      } else if (view === 'pills') {
        list.classList.remove('news-compact');
        list.classList.remove('row','g-3');
        list.classList.add('news-pills');
        if (!data.articles || data.articles.length === 0) {
          list.innerHTML = '<div class="text-muted">No news found for this category.</div>';
        } else {
          const frag = document.createDocumentFragment();
          const items = data.articles.slice( (hero ? 1 : 0) );
          items.forEach(a => frag.appendChild(buildPill(a)));
          list.appendChild(frag);
        }
      } else {
        list.classList.remove('news-compact');
        list.classList.add('row','g-3');
        list.classList.remove('news-pills');
        if (!data.articles || data.articles.length === 0) {
          const empty = document.createElement('div');
          empty.className = 'col-12 text-muted';
          empty.textContent = 'No news found for this category.';
          list.appendChild(empty);
        } else {
          const frag = document.createDocumentFragment();
          const items = data.articles.slice( (hero ? 1 : 0) );
          items.forEach(a => frag.appendChild(buildCard(a)));
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
    const btnPills = document.getElementById('view-pills');
    const setView = (v) => { try { localStorage.setItem('news_view', v); } catch(_){} loadNews(); };
    if (btnCards) btnCards.onclick = () => setView('cards');
    if (btnCompact) btnCompact.onclick = () => setView('compact');
    if (btnPills) btnPills.onclick = () => setView('pills');
  }
  document.addEventListener('turbo:load', initViewToggles);
  document.addEventListener('DOMContentLoaded', initViewToggles);
})();
