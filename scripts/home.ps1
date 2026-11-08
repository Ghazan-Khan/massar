# Massar Services - composed page templates (home, contact, 404)
# Pure ASCII source.

function Get-HomeRecord {
    param($Slug, $Pages, $Lang)
    return (Get-PageBySlug $Pages $Lang $Slug)
}

function New-HomePage {
    param($Page, $Site, $Ui, $Pages, $HomeData, $Translation)

    $sb = New-Object System.Text.StringBuilder

    # ---------------------------------------------------------------- hero
    $h = $HomeData.hero
    [void]$sb.AppendLine('<section class="hero" aria-labelledby="hero-title">')
    [void]$sb.AppendLine('<div class="container hero__grid">')
    [void]$sb.AppendLine('<div class="hero__content">')
    [void]$sb.AppendLine('<p class="eyebrow eyebrow--hero">' + (HtmlEncode $h.eyebrow) + '</p>')
    [void]$sb.AppendLine('<h1 id="hero-title">' + (HtmlEncode $h.title) + '</h1>')
    [void]$sb.AppendLine('<p class="hero__lead">' + (HtmlEncode $h.lead) + '</p>')
    [void]$sb.AppendLine('<div class="hero__actions">')
    [void]$sb.AppendLine('<a class="btn btn--primary" href="' + (Get-EncodedPath $h.primary.href) + '">' + (HtmlEncode $h.primary.label) + (Get-Icon 'arrow' 'icon icon--sm') + '</a>')
    [void]$sb.AppendLine('<a class="btn btn--ghost" href="' + (Get-EncodedPath $h.secondary.href) + '">' + (HtmlEncode $h.secondary.label) + '</a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<p class="hero__note">' + (Get-Icon 'shield' 'icon icon--sm') + '<span>' + (HtmlEncode $h.note) + '</span></p>')
    [void]$sb.AppendLine('<ul class="pillars">')
    foreach ($p in $HomeData.pillars) {
        [void]$sb.AppendLine('<li><span class="pillars__icon">' + (Get-Icon $p.icon 'icon icon--sm') + '</span><span><strong>' + (HtmlEncode $p.title) + '</strong><small>' + (HtmlEncode $p.text) + '</small></span></li>')
    }
    [void]$sb.AppendLine('</ul>')
    [void]$sb.AppendLine('</div>')

    [void]$sb.AppendLine('<aside class="hero-panel" aria-labelledby="panel-title">')
    [void]$sb.AppendLine('<div class="hero-panel__head">')
    [void]$sb.AppendLine('<p class="eyebrow">' + (HtmlEncode $h.eyebrow) + '</p>')
    [void]$sb.AppendLine('<h2 id="panel-title">' + (HtmlEncode $h.panelTitle) + '</h2>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $h.panelLead) + '</p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<ul class="quick-links">')
    foreach ($q in $h.panel) {
        [void]$sb.AppendLine('<li><a class="quick-link" href="' + (Get-EncodedPath $q.href) + '">')
        [void]$sb.AppendLine('<span class="quick-link__icon">' + (Get-Icon $q.icon) + '</span>')
        [void]$sb.AppendLine('<span class="quick-link__text"><strong>' + (HtmlEncode $q.title) + '</strong><small>' + (HtmlEncode $q.text) + '</small></span>')
        [void]$sb.AppendLine('<span class="quick-link__arrow">' + (Get-Icon 'arrow' 'icon icon--sm') + '</span>')
        [void]$sb.AppendLine('</a></li>')
    }
    [void]$sb.AppendLine('</ul>')
    [void]$sb.AppendLine('<div class="hero-panel__official">')
    [void]$sb.AppendLine('<p class="hero-panel__official-title">' + (Get-Icon 'external' 'icon icon--sm') + (HtmlEncode $h.officialTitle) + '</p>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $h.officialText) + '</p>')
    [void]$sb.AppendLine('<p class="hero-panel__official-links">')
    foreach ($l in $h.officialLinks) {
        [void]$sb.AppendLine('<a href="' + (HtmlEncode $l.href) + '" rel="noopener noreferrer">' + (HtmlEncode $l.label) + '</a>')
    }
    [void]$sb.AppendLine('</p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</aside>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')

    # ---------------------------------------------------------------- finder
    $f = $HomeData.finder
    [void]$sb.AppendLine('<section class="section section--tint" aria-labelledby="finder-title">')
    [void]$sb.AppendLine('<div class="container">')
    [void]$sb.AppendLine('<div class="section-heading section-heading--center">')
    [void]$sb.AppendLine('<p class="eyebrow">' + (HtmlEncode $f.eyebrow) + '</p>')
    [void]$sb.AppendLine('<h2 id="finder-title">' + (HtmlEncode $f.title) + '</h2>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $f.lead) + '</p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="finder-grid">')
    foreach ($c in $f.cards) {
        [void]$sb.AppendLine('<a class="finder-card" href="' + (Get-EncodedPath $c.href) + '">')
        [void]$sb.AppendLine('<span class="finder-card__icon">' + (Get-Icon $c.icon) + '</span>')
        [void]$sb.AppendLine('<h3 class="finder-card__title">' + (HtmlEncode $c.title) + '</h3>')
        [void]$sb.AppendLine('<p>' + (HtmlEncode $c.text) + '</p>')
        [void]$sb.AppendLine('<span class="finder-card__cta">' + (HtmlEncode $c.cta) + (Get-Icon 'arrow' 'icon icon--sm') + '</span>')
        [void]$sb.AppendLine('</a>')
    }
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')

    # ---------------------------------------------------------------- about
    $a = $HomeData.about
    [void]$sb.AppendLine('<section class="section" aria-labelledby="about-title">')
    [void]$sb.AppendLine('<div class="container split">')
    [void]$sb.AppendLine('<div class="split__main">')
    [void]$sb.AppendLine('<p class="eyebrow">' + (HtmlEncode $a.eyebrow) + '</p>')
    [void]$sb.AppendLine('<h2 id="about-title">' + (HtmlEncode $a.title) + '</h2>')
    foreach ($para in $a.paras) {
        [void]$sb.AppendLine('<p>' + (HtmlEncode $para) + '</p>')
    }
    [void]$sb.AppendLine('<ul class="check-list">')
    foreach ($pt in $a.points) {
        [void]$sb.AppendLine('<li>' + (Get-Icon 'check' 'icon icon--sm') + '<span>' + (HtmlEncode $pt) + '</span></li>')
    }
    [void]$sb.AppendLine('</ul>')
    [void]$sb.AppendLine('<a class="text-link" href="' + (Get-EncodedPath $a.link.href) + '">' + (HtmlEncode $a.link.label) + (Get-Icon 'arrow' 'icon icon--sm') + '</a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<aside class="service-map" aria-labelledby="map-title">')
    [void]$sb.AppendLine('<p class="eyebrow">' + (HtmlEncode $a.eyebrow) + '</p>')
    [void]$sb.AppendLine('<h2 id="map-title">' + (HtmlEncode $a.asideTitle) + '</h2>')
    [void]$sb.AppendLine('<ol>')
    $n = 0
    foreach ($s in $a.services) {
        $n++
        [void]$sb.AppendLine('<li><a href="' + (Get-EncodedPath $s.href) + '">')
        [void]$sb.AppendLine('<span class="service-map__num">' + $n.ToString('00') + '</span>')
        [void]$sb.AppendLine('<span class="service-map__body"><strong>' + (HtmlEncode $s.title) + '</strong><small>' + (HtmlEncode $s.text) + '</small></span>')
        [void]$sb.AppendLine((Get-Icon 'arrow' 'icon icon--sm'))
        [void]$sb.AppendLine('</a></li>')
    }
    [void]$sb.AppendLine('</ol>')
    [void]$sb.AppendLine('</aside>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')

    # ---------------------------------------------------------------- guides
    $g = $HomeData.guides
    [void]$sb.AppendLine('<section class="section section--sand" aria-labelledby="guides-title">')
    [void]$sb.AppendLine('<div class="container">')
    [void]$sb.AppendLine('<div class="section-heading section-heading--row">')
    [void]$sb.AppendLine('<div><p class="eyebrow">' + (HtmlEncode $g.eyebrow) + '</p><h2 id="guides-title">' + (HtmlEncode $g.title) + '</h2><p>' + (HtmlEncode $g.lead) + '</p></div>')
    [void]$sb.AppendLine('<a class="btn btn--outline" href="' + (Get-EncodedPath $g.cta.href) + '">' + (HtmlEncode $g.cta.label) + (Get-Icon 'arrow' 'icon icon--sm') + '</a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="card-grid card-grid--3">')
    foreach ($s in $g.items) {
        $rec = Get-HomeRecord $s $Pages $Page.lang
        if ($rec) { [void]$sb.AppendLine((New-Card $rec $Ui)) }
    }
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')

    # ---------------------------------------------------------------- steps
    $st = $HomeData.steps
    [void]$sb.AppendLine('<section class="section section--dark" aria-labelledby="steps-title">')
    [void]$sb.AppendLine('<div class="container">')
    [void]$sb.AppendLine('<div class="section-heading section-heading--center">')
    [void]$sb.AppendLine('<p class="eyebrow eyebrow--hero">' + (HtmlEncode $st.eyebrow) + '</p>')
    [void]$sb.AppendLine('<h2 id="steps-title">' + (HtmlEncode $st.title) + '</h2>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $st.lead) + '</p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<ol class="step-grid">')
    $i = 0
    foreach ($s in $st.items) {
        $i++
        [void]$sb.AppendLine('<li class="step"><span class="step__num">' + $i.ToString('00') + '</span><h3>' + (HtmlEncode $s.title) + '</h3><p>' + (HtmlEncode $s.text) + '</p></li>')
    }
    [void]$sb.AppendLine('</ol>')
    [void]$sb.AppendLine('<p class="center"><a class="btn btn--light" href="' + (Get-EncodedPath $st.cta.href) + '">' + (HtmlEncode $st.cta.label) + (Get-Icon 'arrow' 'icon icon--sm') + '</a></p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')

    # ---------------------------------------------------------------- grades vs results
    $sp = $HomeData.split
    [void]$sb.AppendLine('<section class="section" aria-labelledby="split-title">')
    [void]$sb.AppendLine('<div class="container">')
    [void]$sb.AppendLine('<div class="section-heading section-heading--center">')
    [void]$sb.AppendLine('<p class="eyebrow">' + (HtmlEncode $sp.eyebrow) + '</p>')
    [void]$sb.AppendLine('<h2 id="split-title">' + (HtmlEncode $sp.title) + '</h2>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="panel-grid">')
    foreach ($col in @($sp.colA, $sp.colB)) {
        [void]$sb.AppendLine('<article class="info-panel">')
        [void]$sb.AppendLine('<h3>' + (HtmlEncode $col.title) + '</h3>')
        [void]$sb.AppendLine('<p>' + (HtmlEncode $col.text) + '</p>')
        [void]$sb.AppendLine('<ul class="dot-list">')
        foreach ($it in $col.items) {
            [void]$sb.AppendLine('<li>' + (HtmlEncode $it) + '</li>')
        }
        [void]$sb.AppendLine('</ul>')
        [void]$sb.AppendLine('<a class="text-link" href="' + (Get-EncodedPath $col.link.href) + '">' + (HtmlEncode $col.link.label) + (Get-Icon 'arrow' 'icon icon--sm') + '</a>')
        [void]$sb.AppendLine('</article>')
    }
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')

    # ---------------------------------------------------------------- security
    $sec = $HomeData.security
    [void]$sb.AppendLine('<section class="section section--security" aria-labelledby="security-title">')
    [void]$sb.AppendLine('<div class="container security-band">')
    [void]$sb.AppendLine('<div class="security-band__text">')
    [void]$sb.AppendLine('<p class="eyebrow">' + (HtmlEncode $sec.eyebrow) + '</p>')
    [void]$sb.AppendLine('<h2 id="security-title">' + (HtmlEncode $sec.title) + '</h2>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $sec.text) + '</p>')
    [void]$sb.AppendLine('<a class="text-link text-link--light" href="' + (Get-EncodedPath $sec.link.href) + '">' + (HtmlEncode $sec.link.label) + (Get-Icon 'arrow' 'icon icon--sm') + '</a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<ul class="security-band__list">')
    foreach ($it in $sec.items) {
        [void]$sb.AppendLine('<li>' + (Get-Icon 'shield' 'icon icon--sm') + '<span>' + (HtmlEncode $it) + '</span></li>')
    }
    [void]$sb.AppendLine('</ul>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')

    # ---------------------------------------------------------------- news
    $nw = $HomeData.news
    [void]$sb.AppendLine('<section class="section" aria-labelledby="news-title">')
    [void]$sb.AppendLine('<div class="container">')
    [void]$sb.AppendLine('<div class="section-heading section-heading--row">')
    [void]$sb.AppendLine('<div><p class="eyebrow">' + (HtmlEncode $nw.eyebrow) + '</p><h2 id="news-title">' + (HtmlEncode $nw.title) + '</h2><p>' + (HtmlEncode $nw.lead) + '</p></div>')
    [void]$sb.AppendLine('<a class="btn btn--outline" href="' + (Get-EncodedPath $nw.cta.href) + '">' + (HtmlEncode $nw.cta.label) + (Get-Icon 'arrow' 'icon icon--sm') + '</a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="card-grid card-grid--2">')
    foreach ($s in $nw.items) {
        $rec = Get-HomeRecord $s $Pages $Page.lang
        if ($rec) { [void]$sb.AppendLine((New-Card $rec $Ui)) }
    }
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')

    # ---------------------------------------------------------------- trust
    $tr = $HomeData.trust
    [void]$sb.AppendLine('<section class="section section--tint" aria-labelledby="trust-title">')
    [void]$sb.AppendLine('<div class="container">')
    [void]$sb.AppendLine('<div class="section-heading section-heading--center">')
    [void]$sb.AppendLine('<p class="eyebrow">' + (HtmlEncode $tr.eyebrow) + '</p>')
    [void]$sb.AppendLine('<h2 id="trust-title">' + (HtmlEncode $tr.title) + '</h2>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $tr.lead) + '</p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="trust-grid">')
    foreach ($c in $tr.cards) {
        [void]$sb.AppendLine('<article class="trust-card"><span class="trust-card__icon">' + (Get-Icon $c.icon) + '</span><h3>' + (HtmlEncode $c.title) + '</h3><p>' + (HtmlEncode $c.text) + '</p></article>')
    }
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<p class="disclaimer-box">' + (Get-Icon 'info' 'icon icon--sm') + '<span>' + (HtmlEncode $tr.disclaimer) + '</span></p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')

    # ---------------------------------------------------------------- faq
    $fq = $HomeData.faq
    [void]$sb.AppendLine('<section class="section" aria-labelledby="faq-title">')
    [void]$sb.AppendLine('<div class="container container--narrow">')
    [void]$sb.AppendLine('<div class="section-heading section-heading--center">')
    [void]$sb.AppendLine('<p class="eyebrow">' + (HtmlEncode $Ui.faqEyebrow) + '</p>')
    [void]$sb.AppendLine('<h2 id="faq-title">' + (HtmlEncode $fq.title) + '</h2>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $fq.lead) + '</p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="faq__list">')
    foreach ($f in $fq.items) {
        [void]$sb.AppendLine('<details class="faq__item"><summary><span>' + (HtmlEncode $f.q) + '</span>' + (Get-Icon 'chevron' 'icon icon--sm faq__chev') + '</summary><div class="faq__answer"><p>' + (Convert-Inline $f.a) + '</p></div></details>')
    }
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<p class="center"><a class="text-link" href="' + (Get-EncodedPath $fq.cta.href) + '">' + (HtmlEncode $fq.cta.label) + (Get-Icon 'arrow' 'icon icon--sm') + '</a></p>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')

    # ---------------------------------------------------------------- final CTA
    $cta = $HomeData.cta
    [void]$sb.AppendLine('<section class="section section--cta">')
    [void]$sb.AppendLine('<div class="container cta-panel">')
    [void]$sb.AppendLine('<div><h2>' + (HtmlEncode $cta.title) + '</h2><p>' + (HtmlEncode $cta.text) + '</p></div>')
    [void]$sb.AppendLine('<div class="cta-panel__actions">')
    [void]$sb.AppendLine('<a class="btn btn--primary" href="' + (Get-EncodedPath $cta.primary.href) + '">' + (HtmlEncode $cta.primary.label) + (Get-Icon 'arrow' 'icon icon--sm') + '</a>')
    [void]$sb.AppendLine('<a class="btn btn--ghost" href="' + (Get-EncodedPath $cta.secondary.href) + '">' + (HtmlEncode $cta.secondary.label) + '</a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')

    return (New-PageShell $Page $Site $Ui $Pages $Translation $sb.ToString())
}

function New-ContactPage {
    param($Page, $Site, $Ui, $Pages, $Translation)
    $c = $Ui.contact
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine((New-PageHero $Page $Ui $Pages))
    [void]$sb.AppendLine('<div class="container page-layout">')
    [void]$sb.AppendLine('<div class="contact-main">')

    [void]$sb.AppendLine('<div class="prose prose--intro">' + $Page.bodyHtml + '</div>')

    [void]$sb.AppendLine('<section class="contact-form-wrap" aria-labelledby="contact-form-title">')
    [void]$sb.AppendLine('<h2 id="contact-form-title">' + (HtmlEncode $c.formTitle) + '</h2>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $c.formLead) + '</p>')
    [void]$sb.AppendLine('<form class="contact-form" action="/contact.php" method="post" data-contact-form data-msg-success="' + (HtmlEncode $c.success) + '" data-msg-error="' + (HtmlEncode $c.error) + '" data-msg-validation="' + (HtmlEncode $c.validation) + '" data-msg-sending="' + (HtmlEncode $c.sending) + '">')
    [void]$sb.AppendLine('<input type="hidden" name="lang" value="' + $Ui.htmlLang + '">')
    [void]$sb.AppendLine('<div class="field">')
    [void]$sb.AppendLine('<label for="cf-name">' + (HtmlEncode $c.name) + ' <span aria-hidden="true">*</span></label>')
    [void]$sb.AppendLine('<input id="cf-name" name="name" type="text" autocomplete="name" required maxlength="120" placeholder="' + (HtmlEncode $c.namePlaceholder) + '">')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="field">')
    [void]$sb.AppendLine('<label for="cf-email">' + (HtmlEncode $c.email) + ' <span aria-hidden="true">*</span></label>')
    [void]$sb.AppendLine('<input id="cf-email" name="email" type="email" autocomplete="email" required maxlength="180" placeholder="' + (HtmlEncode $c.emailPlaceholder) + '">')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="field">')
    [void]$sb.AppendLine('<label for="cf-topic">' + (HtmlEncode $c.topic) + ' <span aria-hidden="true">*</span></label>')
    [void]$sb.AppendLine('<select id="cf-topic" name="topic" required>')
    [void]$sb.AppendLine('<option value="">' + (HtmlEncode $c.topicPlaceholder) + '</option>')
    foreach ($t in $c.topics) {
        [void]$sb.AppendLine('<option value="' + (HtmlEncode $t) + '">' + (HtmlEncode $t) + '</option>')
    }
    [void]$sb.AppendLine('</select>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="field">')
    [void]$sb.AppendLine('<label for="cf-page">' + (HtmlEncode $c.page) + '</label>')
    [void]$sb.AppendLine('<input id="cf-page" name="page" type="text" maxlength="300" placeholder="' + (HtmlEncode $c.pagePlaceholder) + '" dir="ltr">')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="field">')
    [void]$sb.AppendLine('<label for="cf-message">' + (HtmlEncode $c.message) + ' <span aria-hidden="true">*</span></label>')
    [void]$sb.AppendLine('<textarea id="cf-message" name="message" rows="7" required maxlength="5000" placeholder="' + (HtmlEncode $c.messagePlaceholder) + '"></textarea>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="field field--check">')
    [void]$sb.AppendLine('<input id="cf-consent" name="consent" type="checkbox" value="1" required>')
    [void]$sb.AppendLine('<label for="cf-consent">' + (HtmlEncode $c.consent) + ' <a href="' + (Get-EncodedPath $Ui.footer.legal[0].href) + '">' + (HtmlEncode $c.privacyLink) + '</a>.</label>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="hp-field" aria-hidden="true">')
    [void]$sb.AppendLine('<label for="cf-website">' + (HtmlEncode $c.honeypot) + '</label>')
    [void]$sb.AppendLine('<input id="cf-website" name="website" type="text" tabindex="-1" autocomplete="off">')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<input type="hidden" name="ts" value="" data-contact-ts>')
    [void]$sb.AppendLine('<p class="required-note">' + (HtmlEncode $c.requiredNote) + '</p>')
    [void]$sb.AppendLine('<button class="btn btn--primary btn--wide" type="submit" data-contact-submit>' + (Get-Icon 'mail' 'icon icon--sm') + '<span>' + (HtmlEncode $c.submit) + '</span></button>')
    [void]$sb.AppendLine('<p class="form-status" role="status" aria-live="polite" tabindex="-1" data-form-status></p>')
    [void]$sb.AppendLine('</form>')
    [void]$sb.AppendLine('<div id="sent" class="form-status form-status--panel is-success" role="status" tabindex="-1"><p>' + (HtmlEncode $c.success) + '</p></div>')
    [void]$sb.AppendLine('<p class="contact-direct">' + (HtmlEncode $c.directEmail) + ' <a href="mailto:' + (HtmlEncode $Site.email) + '">' + (HtmlEncode $Site.email) + '</a></p>')
    [void]$sb.AppendLine('<p class="security-note">' + (Get-Icon 'shield' 'icon icon--sm') + '<span>' + (HtmlEncode $c.securityNote) + '</span></p>')
    [void]$sb.AppendLine('</section>')

    [void]$sb.AppendLine('<section class="contact-before" aria-labelledby="before-title">')
    [void]$sb.AppendLine('<h2 id="before-title">' + (HtmlEncode $c.beforeTitle) + '</h2>')
    [void]$sb.AppendLine('<p>' + (HtmlEncode $c.beforeText) + '</p>')
    [void]$sb.AppendLine('<p><a class="text-link" href="' + (Get-EncodedPath $Ui.faqSlug) + '">' + (HtmlEncode $Ui.allFaq) + (Get-Icon 'arrow' 'icon icon--sm') + '</a></p>')
    [void]$sb.AppendLine('</section>')

    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<aside class="sidebar contact-sidebar">')
    [void]$sb.AppendLine('<div class="help-card">')
    [void]$sb.AppendLine('<p class="help-card__title">' + (Get-Icon 'check' 'icon icon--sm') + (HtmlEncode $c.whatTitle) + '</p>')
    [void]$sb.AppendLine('<ul class="check-list check-list--compact">')
    foreach ($it in $c.whatItems) {
        [void]$sb.AppendLine('<li>' + (Get-Icon 'check' 'icon icon--xs') + '<span>' + (HtmlEncode $it) + '</span></li>')
    }
    [void]$sb.AppendLine('</ul>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('<div class="help-card help-card--warning">')
    [void]$sb.AppendLine('<p class="help-card__title">' + (Get-Icon 'alert' 'icon icon--sm') + (HtmlEncode $c.cannotTitle) + '</p>')
    [void]$sb.AppendLine('<ul class="dot-list dot-list--compact">')
    foreach ($it in $c.cannotItems) {
        [void]$sb.AppendLine('<li>' + (HtmlEncode $it) + '</li>')
    }
    [void]$sb.AppendLine('</ul>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine((New-Sidebar $Page $Ui))
    [void]$sb.AppendLine('</aside>')
    [void]$sb.AppendLine('</div>')
    return (New-PageShell $Page $Site $Ui $Pages $Translation $sb.ToString())
}

function New-NotFoundPage {
    param($Page, $Site, $Ui, $Pages, $Translation)
    $n = $Ui.notFound
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<section class="page-hero page-hero--error">')
    [void]$sb.AppendLine('<div class="container">')
    [void]$sb.AppendLine('<p class="error-code">404</p>')
    [void]$sb.AppendLine('<h1>' + (HtmlEncode $n.title) + '</h1>')
    [void]$sb.AppendLine('<p class="page-hero__lead">' + (HtmlEncode $n.lead) + '</p>')
    [void]$sb.AppendLine('<div class="hero__actions">')
    [void]$sb.AppendLine('<a class="btn btn--primary" href="' + (Get-EncodedPath $Ui.homeSlug) + '">' + (HtmlEncode $n.home) + (Get-Icon 'arrow' 'icon icon--sm') + '</a>')
    [void]$sb.AppendLine('<a class="btn btn--ghost" href="' + (Get-EncodedPath $Ui.searchSlug) + '">' + (HtmlEncode $n.search) + '</a>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine('</section>')
    [void]$sb.AppendLine('<div class="container container--narrow error-links">')
    [void]$sb.AppendLine('<h2>' + (HtmlEncode $n.popular) + '</h2>')
    [void]$sb.AppendLine('<ul class="link-list">')
    [void]$sb.AppendLine('<li><a href="' + (Get-EncodedPath $Ui.searchSlug) + '">' + (HtmlEncode $n.search) + '</a><span>' + (HtmlEncode $Ui.searchPage.hint) + '</span></li>')
    [void]$sb.AppendLine('<li><a href="' + (Get-EncodedPath $Ui.guidesSlug) + '">' + (HtmlEncode $n.guides) + '</a><span>' + (HtmlEncode $Ui.footer.description) + '</span></li>')
    [void]$sb.AppendLine('<li><a href="' + (Get-EncodedPath $Ui.faqSlug) + '">' + (HtmlEncode $n.faq) + '</a><span>' + (HtmlEncode $Ui.faqLead) + '</span></li>')
    [void]$sb.AppendLine('</ul>')
    [void]$sb.AppendLine('</div>')
    return (New-PageShell $Page $Site $Ui $Pages $Translation $sb.ToString())
}
