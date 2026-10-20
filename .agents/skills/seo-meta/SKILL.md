---
name: seo-meta
description: Use for public pages before launch — titles, descriptions, canonical URLs, OG and Twitter cards, sitemap, robots, structured data, and Core Web Vitals. Not for visual design (use ui-ux).
---

# SEO and meta

Do the boring parts once, then verify them on the deployed page.

## Per page

```html
<title>Primary keyword — Brand (<= 60 chars)</title>
<meta name="description" content="What this page gives the visitor, 140-160 chars." />
<link rel="canonical" href="https://example.com/page" />
<meta property="og:title" content="..." />
<meta property="og:description" content="..." />
<meta property="og:image" content="https://example.com/og/page.png" />
<meta property="og:url" content="https://example.com/page" />
<meta property="og:type" content="website" />
<meta name="twitter:card" content="summary_large_image" />
```

- One `<h1>` per page, matching the title's promise. Headings in order.
- OG image 1200×630, text legible at thumbnail size, absolute URL.
- No duplicate titles or descriptions across pages.
- Private or app pages: `noindex`, and keep them out of the sitemap.

## Crawl

`robots.txt` (allow what matters, point at the sitemap), a sitemap generated at build, one canonical host (apex or www, not both), 301s for renamed URLs.

## Structured data

JSON-LD only for what the page is: `Organization` on home, `Product` with `Offer` on a product page, `Article` on posts, `FAQPage` only when the FAQ is visible. Validate with the Rich Results test.

## Core Web Vitals budgets

LCP < 2.5s · CLS < 0.1 · INP < 200ms. Common fixes: preload the hero image, explicit width and height, `font-display: swap`, no layout-shifting banners, defer non-critical JS.

## Verify on the deployed URL

```bash
curl -s https://example.com | grep -E '<title>|og:image|canonical'
```

Then run Lighthouse mobile and the OG debugger. Local metadata proves nothing about what crawlers see.
