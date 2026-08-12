(function () {
  function initializeTabs() {
    document.querySelectorAll('[data-tab-root]').forEach(function (root) {
      var buttons = root.querySelectorAll('button[data-tab-target]');
      var panels = root.querySelectorAll('.tab-panel');

      function activate(targetId) {
        buttons.forEach(function (btn) {
          var isActive = btn.getAttribute('data-tab-target') === targetId;
          btn.classList.toggle('active', isActive);
          btn.setAttribute('aria-selected', isActive ? 'true' : 'false');
          btn.setAttribute('tabindex', isActive ? '0' : '-1');
        });

        panels.forEach(function (panel) {
          var isActive = panel.id === targetId;
          panel.classList.toggle('active', isActive);
          panel.setAttribute('aria-hidden', isActive ? 'false' : 'true');
        });
      }

      buttons.forEach(function (button, index) {
        button.setAttribute('role', 'tab');
        button.setAttribute('aria-selected', index === 0 ? 'true' : 'false');
        button.setAttribute('tabindex', index === 0 ? '0' : '-1');
        button.addEventListener('click', function (event) {
          event.preventDefault();
          var targetId = button.getAttribute('data-tab-target');
          if (targetId) {
            activate(targetId);
          }
        });
      });

      panels.forEach(function (panel, index) {
        panel.setAttribute('role', 'tabpanel');
        panel.setAttribute('aria-hidden', index === 0 ? 'false' : 'true');
        if (index === 0) {
          panel.classList.add('active');
        }
      });
    });
  }

  function initializeManagedDetailToggles() {
    document.querySelectorAll('[data-toggle-detail]').forEach(function (button) {
      button.addEventListener('click', function () {
        var targetId = button.getAttribute('data-toggle-detail');
        var detailRow = targetId ? document.getElementById(targetId) : null;
        if (!detailRow) {
          return;
        }

        var isOpen = detailRow.style.display !== 'none';
        detailRow.style.display = isOpen ? 'none' : 'table-row';
        button.setAttribute('aria-expanded', isOpen ? 'false' : 'true');
      });
    });
  }

  function initializePageBehavior() {
    initializeTabs();
    initializeManagedDetailToggles();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializePageBehavior);
  } else {
    initializePageBehavior();
  }
})();
