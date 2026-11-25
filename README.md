# programielabs-web

Static websites for Programie Labs EOOD.

| Folder     | Live at                          | Host                         |
|------------|----------------------------------|------------------------------|
| `company/` | https://programielabs.com        | GitHub Pages (A records)     |
| `tya/`     | https://tya.programielabs.com    | Cloudflare Pages (CNAME)     |
| `shared/`  | copied into each site at `/assets/` | –                         |

Plain HTML and CSS. The only build step is `scripts/build.sh`, which copies files and **refuses to build
if a permanent URL is missing**. A failed build leaves the previous version live.

```sh
sh scripts/build.sh company   # → dist/company
sh scripts/build.sh tya       # → dist/tya
python3 -m http.server -d dist/tya 8000   # preview locally
```

## Permanent URLs — never change these

These go into App Store Connect, Play Console and the app's own consent screens. Old app builds keep linking to them indefinitely.
The list in `scripts/permanent-urls.txt` is enforced by the build.

| URL | Where it's used |
|---|---|
| `https://programielabs.com` | Apple and Google organisation enrolment (company website) |
| `https://tya.programielabs.com/privacy` | App Store Connect → App Privacy → Privacy Policy URL; Play Console → App content → Privacy policy; in-app consent |
| `https://tya.programielabs.com/terms` | In-app consent; App Store licence agreement if you use a custom EULA |
| `https://tya.programielabs.com/support` | App Store Connect → Support URL |
| `https://tya.programielabs.com/delete-account` | Play Console → App content → Data safety → Delete account URL |
| `https://tya.programielabs.com` | App Store Marketing URL (optional); Play Console website |

The Tya landing page will **replace `tya/index.html` at the same URL**. Its redesign can't touch the legal pages.
The landing page will probably need scripts. When it does, relax `script-src` in `tya/_headers`, which is currently `'none'`.

---

## One-time setup

Work through these steps in order. Steps 3–5 change DNS. **Take a screenshot of the full Porkbun record list before you start.**

### 0. Before going live
- [x] Registered address (15 Samokov Street, Sofia 1113) matches the D-U-N-S record on the company page, privacy policy and terms.

### 1. GitHub repository
- [x] Plan: GitHub Free, so the repo is **public**. Only commit legal text once it has been signed off, because the history is public too.
- [ ] Create the repo `teodora-k/programielabs-web` and push this folder to `main`.

### 2. Verify the domain with GitHub (prevents takeover)
- [ ] github.com/settings/pages → **Add a domain** → `programielabs.com`.
- [ ] GitHub shows a TXT record: host `_github-pages-challenge-teodora-k`, with a value. Add it at Porkbun (step 3), then click **Verify**.

### 3. Porkbun DNS (Domain Management → programielabs.com → DNS)

**Do not touch** any of these. They are your Zoho Mail records:
- the `MX` records (`mx.zoho.eu`, `mx2.zoho.eu`, `mx3.zoho.eu`)
- the `TXT` on `@` starting `v=spf1` (SPF)
- the `TXT` on `zmail._domainkey` (DKIM)
- any `TXT` on `_dmarc`, and any `zoho-verification` TXT

**Delete** Porkbun's parking records, if present:
- `ALIAS` on `@` pointing to `uixie.porkbun.com`
- `CNAME` on `*` pointing to `uixie.porkbun.com` (GitHub warns against wildcard records)

**Add:**

| Type | Host | Answer |
|---|---|---|
| A | *(blank / @)* | 185.199.108.153 |
| A | *(blank / @)* | 185.199.109.153 |
| A | *(blank / @)* | 185.199.110.153 |
| A | *(blank / @)* | 185.199.111.153 |
| AAAA | *(blank / @)* | 2606:50c0:8000::153 |
| AAAA | *(blank / @)* | 2606:50c0:8001::153 |
| AAAA | *(blank / @)* | 2606:50c0:8002::153 |
| AAAA | *(blank / @)* | 2606:50c0:8003::153 |
| CNAME | www | teodora-k.github.io |
| TXT | _github-pages-challenge-teodora-k | *(value from step 2)* |

Use A records only for the apex. Don't keep an ALIAS on `@` as well, because having both is a known cause of GitHub HTTPS certificates failing.
If a `CAA` record exists, it must allow `letsencrypt.org` and `pki.goog`.

### 4. GitHub Pages → programielabs.com
- [ ] Repo → Settings → Pages → **Source: GitHub Actions**.
- [ ] Actions → *Deploy programielabs.com* → **Run workflow**.
- [ ] Settings → Pages → Custom domain: `programielabs.com` → Save. Once the certificate is issued (minutes, sometimes an hour), tick **Enforce HTTPS**.

### 5. Cloudflare Pages → tya.programielabs.com
- [ ] Create a free Cloudflare account. **Don't add the domain as a zone and don't change nameservers.**
- [ ] Workers & Pages → Create → **Pages** → Connect to Git → `programielabs-web`.
  - Production branch: `main`
  - Framework preset: None
  - Build command: `sh scripts/build.sh tya`
  - Build output directory: `dist/tya`
- [ ] After the first deploy: project → Custom domains → **Set up a custom domain** → `tya.programielabs.com` → choose **My DNS provider**.
- [ ] At Porkbun add: `CNAME` · host `tya` · answer `<your-project>.pages.dev` (exactly as Cloudflare shows it).

### 6. Google Search Console (for Play organisation verification)
- [ ] Sign in with **the same Google account you'll use for Play Console**, so the website-association request is approved automatically.
- [ ] Add property → **Domain** → `programielabs.com`. This one property covers the apex and every subdomain.
- [ ] Add the `TXT` record it gives you on `@` at Porkbun. It sits alongside the SPF record; don't merge the two.

### 7. Check
- [ ] `https://programielabs.com`, `https://www.programielabs.com` (should redirect) and all five Tya URLs load over HTTPS.
- [ ] `https://tya.programielabs.com/does-not-exist` shows the Tya 404 page, not the home page.
- [ ] Send yourself an email to `hello@programielabs.com` from an outside account. Mail still arrives.
- [ ] Actions → *Check live URLs* → **Run workflow**. It goes green, then runs every Monday from then on.

### Before store submission
- [ ] Replace every placeholder and remove each `.draft-banner` once your lawyer has signed off.
- [ ] Fill in the "Last updated" dates.
- [ ] Make sure the in-app links use exactly the URLs in the table above.
