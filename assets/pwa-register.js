// 是甜姐呀 PWA 注册与安装提示
(function () {
  const isStandalone = window.matchMedia('(display-mode: standalone)').matches
    || navigator.standalone === true
    || window.navigator.standalone;

  // 注册 Service Worker
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('../sw.js', { scope: '../' })
      .then((reg) => console.log('[PWA] SW registered:', reg.scope))
      .catch((err) => console.warn('[PWA] SW registration failed:', err));
  }

  // 注入横幅样式
  const style = document.createElement('style');
  style.textContent = `
    #pwa-install-banner {
      position: fixed;
      left: 0; right: 0; bottom: 0;
      z-index: 9999;
      padding: 10px 14px calc(10px + env(safe-area-inset-bottom));
      background: rgba(255,255,255,0.95);
      backdrop-filter: blur(8px);
      border-top: 1px solid var(--line, #F2ECEE);
      box-shadow: 0 -4px 20px rgba(74,63,69,0.08);
      font-family: var(--font-sans, system-ui, sans-serif);
    }
    .pwa-banner-inner {
      display: flex; align-items: center; gap: 10px;
      max-width: 420px; margin: 0 auto;
    }
    .pwa-banner-inner span {
      flex: 1; font-size: 13px; color: var(--ink, #4A3F45); line-height: 1.4;
    }
    .pwa-banner-btn {
      flex-shrink: 0;
      padding: 7px 14px;
      border-radius: 999px;
      background: var(--brand, #FF6B9B);
      color: #fff;
      font-size: 13px; font-weight: 600;
      text-decoration: none;
    }
    .pwa-banner-close {
      flex-shrink: 0;
      width: 26px; height: 26px;
      border: 0; border-radius: 50%;
      background: var(--surface-2, #FFF0F5);
      color: var(--ink-2, #6B5E65);
      font-size: 18px; line-height: 1;
      cursor: pointer;
    }
  `;
  document.head.appendChild(style);

  // 在浏览器里显示"添加到主屏幕"横幅提示（仅首页，且 24h 内关闭过不再弹）
  if (!isStandalone && location.pathname.endsWith('home.html')) {
    const lastClosed = parseInt(localStorage.getItem('tianjie-install-banner-closed') || '0', 10);
    if (Date.now() - lastClosed > 24 * 60 * 60 * 1000) {
      let banner = document.getElementById('pwa-install-banner');
      if (!banner) {
        banner = document.createElement('div');
        banner.id = 'pwa-install-banner';
        banner.innerHTML = `
          <div class="pwa-banner-inner">
            <span>🍎 把“是甜姐呀”添加到主屏幕，像 App 一样使用</span>
            <a href="./install.html" class="pwa-banner-btn" data-dom-id="home-banner-install">查看方法</a>
            <button class="pwa-banner-close" aria-label="关闭">×</button>
          </div>
        `;
        document.body.appendChild(banner);
        banner.querySelector('.pwa-banner-close').addEventListener('click', () => {
          banner.style.display = 'none';
          localStorage.setItem('tianjie-install-banner-closed', Date.now());
        });
      }
    }
  }
})();
