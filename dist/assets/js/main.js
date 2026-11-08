/* Massar Services - progressive enhancement
   No dependencies. All user-facing strings come from the document. */
(function () {
  "use strict";

  var doc = document;
  var body = doc.body;
  var header = doc.querySelector("[data-site-header]");
  var menuToggle = doc.querySelector("[data-menu-toggle]");
  var siteNav = doc.querySelector("[data-site-nav]");
  var DESKTOP = 960;

  function setExpanded(el, value) {
    if (el) { el.setAttribute("aria-expanded", value ? "true" : "false"); }
  }

  function closeSubmenus(except) {
    var open = doc.querySelectorAll(".nav__item.is-open");
    for (var i = 0; i < open.length; i++) {
      if (open[i] === except) { continue; }
      open[i].classList.remove("is-open");
      var btn = open[i].querySelector(".nav__toggle");
      setExpanded(btn, false);
    }
  }

  function closeNav(returnFocus) {
    if (!menuToggle) { return; }
    body.classList.remove("nav-open");
    setExpanded(menuToggle, false);
    closeSubmenus(null);
    if (returnFocus) { menuToggle.focus(); }
  }

  /* ---------------------------------------------------------- mobile menu */
  if (menuToggle && siteNav) {
    setExpanded(menuToggle, false);
    menuToggle.addEventListener("click", function () {
      var open = body.classList.toggle("nav-open");
      setExpanded(menuToggle, open);
      if (!open) { closeSubmenus(null); }
    });

    doc.addEventListener("keydown", function (e) {
      if (e.key === "Escape" || e.key === "Esc") {
        if (body.classList.contains("nav-open")) {
          closeNav(true);
        } else {
          closeSubmenus(null);
        }
      }
    });

    window.addEventListener("resize", function () {
      if (window.innerWidth > DESKTOP && body.classList.contains("nav-open")) {
        body.classList.remove("nav-open");
        setExpanded(menuToggle, false);
      }
    });
  }

  /* ---------------------------------------------------------- dropdowns */
  var toggles = doc.querySelectorAll(".nav__toggle");
  for (var t = 0; t < toggles.length; t++) {
    toggles[t].addEventListener("click", function (e) {
      e.preventDefault();
      var item = this.closest(".nav__item");
      if (!item) { return; }
      var open = item.classList.contains("is-open");
      closeSubmenus(item);
      item.classList.toggle("is-open", !open);
      setExpanded(this, !open);
    });
  }

  doc.addEventListener("click", function (e) {
    if (header && !header.contains(e.target)) {
      closeSubmenus(null);
    }
  });

  /* ---------------------------------------------------------- header state */
  if (header) {
    var onScroll = function () {
      header.classList.toggle("is-scrolled", window.scrollY > 8);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
  }

  /* ---------------------------------------------------------- table of contents */
  var tocLinks = doc.querySelectorAll(".toc a[href^='#']");
  if (tocLinks.length && "IntersectionObserver" in window) {
    var map = {};
    for (var k = 0; k < tocLinks.length; k++) {
      var id = tocLinks[k].getAttribute("href").slice(1);
      var target = doc.getElementById(id);
      if (target) { map[id] = tocLinks[k]; }
    }
    var current = null;
    var observer = new IntersectionObserver(function (entries) {
      for (var i = 0; i < entries.length; i++) {
        if (!entries[i].isIntersecting) { continue; }
        var link = map[entries[i].target.id];
        if (link && link !== current) {
          if (current) { current.classList.remove("is-active"); }
          link.classList.add("is-active");
          current = link;
        }
      }
    }, { rootMargin: "-18% 0px -68% 0px", threshold: 0 });
    for (var key in map) {
      if (Object.prototype.hasOwnProperty.call(map, key)) {
        observer.observe(doc.getElementById(key));
      }
    }
  }

  /* ---------------------------------------------------------- contact form */
  var contact = doc.querySelector("[data-contact-form]");
  if (contact) {
    var status = contact.querySelector("[data-form-status]");
    var submit = contact.querySelector("[data-contact-submit]");
    var ts = contact.querySelector("[data-contact-ts]");
    var submitLabel = submit ? submit.querySelector("span") : null;
    var originalLabel = submitLabel ? submitLabel.textContent : "";
    var sendingLabel = contact.getAttribute("data-msg-sending") || "";

    var setStatus = function (message, kind) {
      if (!status) { return; }
      status.textContent = message || "";
      status.classList.remove("is-success", "is-error");
      if (kind) { status.classList.add("is-" + kind); }
      status.focus();
    };

    if (ts) { ts.value = String(Math.floor(Date.now() / 1000)); }

    contact.addEventListener("submit", function (e) {
      if (!contact.checkValidity()) {
        e.preventDefault();
        contact.reportValidity();
        setStatus(contact.getAttribute("data-msg-validation"), "error");
        return;
      }

      e.preventDefault();
      if (!window.fetch || !window.FormData) {
        contact.submit();
        return;
      }

      contact.setAttribute("aria-busy", "true");
      if (submit) { submit.disabled = true; }
      if (submitLabel && sendingLabel) { submitLabel.textContent = sendingLabel; }
      setStatus(sendingLabel, null);

      var data = new FormData(contact);
      fetch(contact.getAttribute("action") || "/contact.php", {
        method: "POST",
        body: data,
        headers: { "Accept": "application/json" },
        credentials: "same-origin"
      }).then(function (response) {
        return response.json().catch(function () {
          throw new Error("bad-response");
        }).then(function (payload) {
          if (!response.ok || !payload || payload.ok !== true) {
            throw new Error((payload && payload.message) || "send-failed");
          }
          return payload;
        });
      }).then(function () {
        setStatus(contact.getAttribute("data-msg-success"), "success");
        contact.reset();
        if (ts) { ts.value = String(Math.floor(Date.now() / 1000)); }
      }).catch(function () {
        setStatus(contact.getAttribute("data-msg-error"), "error");
      }).then(function () {
        contact.removeAttribute("aria-busy");
        if (submit) { submit.disabled = false; }
        if (submitLabel && originalLabel) { submitLabel.textContent = originalLabel; }
      });
    });
  }

  /* ---------------------------------------------------------- search */
  var searchRoot = doc.querySelector("[data-search-root]");
  if (searchRoot) {
    var input = doc.getElementById("q-search");
    var form = doc.querySelector("[data-search-form]");
    var resultsBox = searchRoot.querySelector("[data-search-results]");
    var statusBox = searchRoot.querySelector("[data-search-status]");
    var lang = (doc.documentElement.getAttribute("lang") || "ar").slice(0, 2);
    var index = null;
    var loading = false;
    var timer = null;

    var msg = {
      count: searchRoot.getAttribute("data-msg-count") || "",
      none: searchRoot.getAttribute("data-msg-noresults") || "",
      loading: searchRoot.getAttribute("data-msg-loading") || "",
      error: searchRoot.getAttribute("data-msg-error") || "",
      popular: searchRoot.getAttribute("data-msg-popular") || ""
    };

    var diacritics = /[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]/g;

    function normalize(value) {
      var s = String(value || "").toLowerCase();
      s = s.replace(diacritics, "");
      s = s.replace(/[\u0623\u0625\u0622\u0671]/g, "\u0627");
      s = s.replace(/\u0649/g, "\u064A");
      s = s.replace(/\u0629/g, "\u0647");
      s = s.replace(/\u0640/g, "");
      s = s.replace(/[^\w\s\u0600-\u06FF]/g, " ");
      return s.replace(/\s+/g, " ").trim();
    }

    function loadIndex() {
      if (index) { return Promise.resolve(index); }
      if (loading) { return loading; }
      loading = fetch("/search-index.json", { credentials: "same-origin" })
        .then(function (r) {
          if (!r.ok) { throw new Error("index"); }
          return r.json();
        })
        .then(function (data) {
          index = (data || []).filter(function (item) { return item.l === lang; });
          return index;
        })
        .catch(function (err) {
          loading = false;
          throw err;
        });
      return loading;
    }

    function render(items, query) {
      if (!resultsBox) { return; }
      resultsBox.textContent = "";
      var frag = doc.createDocumentFragment();
      for (var i = 0; i < items.length; i++) {
        var item = items[i];
        var article = doc.createElement("article");
        article.className = "result";

        if (item.k) {
          var kicker = doc.createElement("p");
          kicker.className = "result__kicker";
          kicker.textContent = item.k;
          article.appendChild(kicker);
        }

        var h2 = doc.createElement("h2");
        h2.className = "result__title";
        var a = doc.createElement("a");
        a.href = item.u;
        a.textContent = item.t;
        h2.appendChild(a);
        article.appendChild(h2);

        var summary = doc.createElement("p");
        summary.className = "result__summary";
        summary.textContent = item.s || "";
        article.appendChild(summary);

        var url = doc.createElement("p");
        url.className = "result__url";
        url.dir = "auto";
        url.textContent = item.u;
        article.appendChild(url);

        frag.appendChild(article);
      }
      resultsBox.appendChild(frag);
    }

    function setStatus(text) {
      if (statusBox) { statusBox.textContent = text || ""; }
    }

    function run(query, updateUrl) {
      var q = String(query || "").trim();
      if (updateUrl && window.history && window.history.replaceState) {
        var url = window.location.pathname + (q ? "?q=" + encodeURIComponent(q) : "");
        window.history.replaceState(null, "", url);
      }

      setStatus(msg.loading);
      loadIndex().then(function (items) {
        if (!q) {
          setStatus(msg.popular);
          render(items.slice(0, 8), "");
          return;
        }
        var tokens = normalize(q).split(" ").filter(Boolean);
        if (!tokens.length) {
          setStatus(msg.none);
          render([], "");
          return;
        }
        var found = [];
        for (var i = 0; i < items.length; i++) {
          var item = items[i];
          var title = normalize(item.t);
          var kicker = normalize(item.k);
          var summary = normalize(item.s);
          var body = normalize(item.b);
          var haystack = title + " " + kicker + " " + summary + " " + body;
          var ok = true;
          var score = 0;
          for (var j = 0; j < tokens.length; j++) {
            var token = tokens[j];
            if (haystack.indexOf(token) === -1) { ok = false; break; }
            if (title.indexOf(token) !== -1) { score += 8; }
            if (kicker.indexOf(token) !== -1) { score += 3; }
            if (summary.indexOf(token) !== -1) { score += 4; }
            if (body.indexOf(token) !== -1) { score += 1; }
          }
          if (!ok) { continue; }
          if (title.indexOf(normalize(q)) !== -1) { score += 10; }
          found.push({ item: item, score: score });
        }
        found.sort(function (a, b) {
          if (b.score !== a.score) { return b.score - a.score; }
          return a.item.t.localeCompare(b.item.t, lang);
        });
        var list = found.slice(0, 30).map(function (entry) { return entry.item; });
        if (!list.length) {
          setStatus(msg.none);
        } else {
          setStatus(msg.count + ": " + list.length);
        }
        render(list, q);
      }).catch(function () {
        setStatus(msg.error);
      });
    }

    if (form) {
      form.addEventListener("submit", function (e) {
        e.preventDefault();
        run(input ? input.value : "", true);
      });
    }

    if (input) {
      input.addEventListener("input", function () {
        if (timer) { clearTimeout(timer); }
        var value = input.value;
        timer = setTimeout(function () { run(value, false); }, 220);
      });
    }

    var params = new URLSearchParams(window.location.search);
    var initial = params.get("q") || "";
    if (input) { input.value = initial; }
    run(initial, false);
  }
})();
