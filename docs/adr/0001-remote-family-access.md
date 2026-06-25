# ADR-0001: Secure remote access to scans for family

**Status:** Proposed
**Date:** 2026-06-25
**Deciders:** woodie

## Context

`scandalous` was designed for the home network only -- the README says so
explicitly ("no concern about having others access the scans"). Files are
served over plain HTTP with no auth, which is fine on a trusted LAN but
breaks down the moment family members need to fetch a scan from outside
the house: modern browsers/OSes increasingly distrust HTTP downloads, and
there's no authentication gate to put in front of remote access anyway.

Three options were raised:

1. Self-sign a TLS cert on the Pi.
2. Nginx + OAuth2-Proxy + certbot on the Pi, with port 443 opened on the
   home firewall.
3. Relay/serve files through Google App Engine instead, with auth there.

This ADR also adds a fourth option (Cloudflare Tunnel) that wasn't on the
original list, because it directly answers the "expose a home server
without opening firewall ports" problem and is worth weighing alongside
the other three.

No constraints were supplied beyond the three options themselves (the
intake form was skipped), so the assessment below leans on what's
already visible in the repos: `scandalous` already does manual iptables
port-forwarding for ports 80 and 25 (`DEVELOPMENT.md`), so some comfort
with home-network exposure is already established. There's also existing
familiarity with Google App Engine elsewhere in this workspace
(`remix-app-server-gae`, `starter-express-app-engine`), a real factor in
Option 3's "super easy" claim being credible specifically for this
person. **Update:** `casa.netpress.com` already points at the home fiber
interface, so the domain/DNS half of Option 2 (and optionally Option 4,
which can reuse the same hostname as a CNAME target) is already done --
this was the main practical blocker to self-hosting and it's resolved.
There's also `scans.netpress.com`, already resolving internally to
`10.0.1.111` -- the Pi's LAN address -- confirming the `netpress.com`
zone is fully self-managed, with split internal/external records already
a working pattern. That gives Option 2/4 a clean shape: the external
hostname (`casa.netpress.com`) terminates TLS/auth at the edge (Nginx or
Cloudflare) and proxies through to the existing internal service at
`scans.netpress.com`/`10.0.1.111`, with no change needed to how scandalous
serves files today.

**Second update:** the goalposts moved. Two new factors:

1. Even though DDNS turned out not to be strictly necessary (the fiber IP
   is already working as a static-enough record), maintaining a
   DDNS-style dependency at all is something the deciders would rather
   avoid going forward, which weighs against Option 2 even with the CGNAT
   risk resolved -- it's a maintenance-taste objection, not just a
   technical one.
2. The goal is no longer just "my family, my one Pi." There's real
   interest in selling a pre-configured Pi (a "Pi nano") to other people
   with the same scanner-without-HTTPS problem, with **no external
   interface at all** -- not even an open outbound tunnel -- and minimal
   setup for a non-technical buyer. That changes which dimensions matter
   most: per-deployment DNS/cert/router work that's a one-time chore for
   *this* household becomes a recurring support burden multiplied across
   every customer's different router, ISP, and CGNAT situation.

Two more approaches were raised and are addressed below: running a
private CA instead of a publicly-trusted one, and a tip from Nate
Berkopec about the `socketry/localhost` gem.

**Third update -- the implementation target itself changes.** `scandalous`
was a proof of concept; once the HTTP-download pain showed up, the
deciders pivoted to `lambada` (Go) as the actual successor. `lambada`
today is a single-binary SMTP receiver: it listens on 2525, parses the
incoming scan email, decodes the attachment, and writes it straight into
a directory that's Samba-shared on the LAN. It has **no HTTP server, no
cloud upload, no OAuth, no file-watcher** -- it's intentionally minimal,
and it already replaces both scandalous's MTA *and* its file-serving job
(via Samba instead of HTTP). That means the actual SMB-not-HTTPS problem
this ADR was written for now lives in `lambada`, not `scandalous`, and
any new option's implementation should target `lambada`. This matters
for the decision: `lambada` already touches every new file at the exact
moment it's written (inside its SMTP backend's write path), so an
outbound cloud upload can be a single added call right there -- no
separate file-watcher needed. Conversely, any option that needs a local
HTTP listener (1, 1b, 2, 4) requires building one from scratch in
`lambada`, since neither it nor a retired PoC are a given HTTP server to
reuse anymore.

## Decision

Superseding the prior recommendation, on two grounds now: the goal is "no
external interface, sellable to other people, minimal setup," *and* the
actual implementation target is `lambada` (Go), which has no HTTP server
to reuse. **Option 5 (cloud storage relay)** is the clear lead. It's the
only option where the device has zero inbound exposure (not
outbound-tunnel-zero, *actually* zero -- no DDNS, no certs, no
port-forwarding, no tunnel daemon) and the only one that needs **no new
server on the device at all** -- just one outbound SDK call added at the
point `lambada` already writes each file. Every other option needs a
brand-new local HTTP listener built from scratch in `lambada`, since
neither it nor the retired `scandalous` PoC hands one over for free
anymore -- that's a real, previously uncounted cost against Options 1,
1b, 2, and 4. Option 4 (Cloudflare Tunnel) is still the right fallback if
"scans should never leave the device" is a hard requirement, but it now
also means building that HTTP server *and* asking every customer to set
up a Cloudflare account -- real setup friction Option 5 doesn't have (a
customer just gets a Google/email login, no new device-side server).
Option 2 (Nginx + certbot) is dropped: the DDNS-adjacent maintenance is
unwanted, it doesn't scale to arbitrary customers' home networks, and it
now also needs a new HTTP server to put Nginx in front of. Option 3 (full
App Engine app) is superseded by Option 5's thinner auth+signed-URL
gateway. Option 1 (self-signed) and Option 1b (private CA) are not
recommended -- see below.

## Options Considered

### Option 1: Self-signed TLS on the Pi

| Dimension | Assessment |
|---|---|
| Complexity | Low |
| Cost | Free |
| Solves "painful HTTPS downloads"? | No |
| Solves "family authenticate"? | No |
| Exposes home network? | Only if also port-forwarded (not included in this option as described) |

**Pros:** Quick, no new infrastructure, no domain needed.
**Cons:** Self-signed certs trigger "untrusted certificate" warnings in
every browser, every visit -- arguably scarier to non-technical family
than the plain-HTTP warning this is meant to replace. It also does
nothing for authentication, and does nothing for remote reachability
(NAT traversal/firewall still unsolved). This option treats a symptom,
not the actual problem. **Implementation note:** `lambada` has no HTTP
server today (it's SMTP-in, Samba-out) -- this would mean building one
from scratch just to terminate a cert nobody will trust anyway.

### Option 1b: Private CA (self-hosted root certificate authority)

| Dimension | Assessment |
|---|---|
| Complexity | Low to generate (`step-ca`, `mkcert`, even plain `openssl`); high to distribute |
| Cost | Free |
| Solves "painful HTTPS downloads"? | Only after the root cert is trusted on every device that needs access |
| Solves "family authenticate"? | No -- a CA proves the *connection* is encrypted to the right host, not *who's* connecting |
| Exposes home network? | Only if also reachable (still needs Option 2-style reachability or a tunnel) |

Also addresses Nate Berkopec's `socketry/localhost` suggestion: that gem
automates exactly this (it generates a local root CA and per-host leaf
certs, with tooling to add the root to your OS/browser trust store) but
it's built for *local development* -- getting `https://foo.localhost`
working without warnings while coding, on the one machine doing the
developing. It solves the cert-trust half on a single device; it doesn't
touch reachability (the actual blocker here) and doesn't make trusting
the root any easier across a family's heterogeneous phones/laptops.
Repurposing it for this doesn't remove the real cost below.

**Pros:** No public CA dependency, no Let's Encrypt rate limits, no
domain strictly required, conceptually clean.
**Cons:** The entire cost moves to distribution: every device that needs
access has to install and trust a root certificate you generated, which
on iOS/Android is a fiddly multi-step settings dance (install profile,
then separately flip "full trust"), and varies by OS version. That's a
one-time favor you can walk your own family through; it's a support
nightmare multiplied across other people's families if this gets sold,
and a security-conscious buyer should be wary of trusting a vendor-issued
root CA in the first place (it can MITM anything else that device trusts
it for). Doesn't solve authentication at all on its own -- it needs to be
paired with something else for that. Not recommended for either the
family case or the resale case. **Implementation note:** also needs a new
HTTP server built in `lambada`, same as Option 1.

### Option 2: Nginx + OAuth2-Proxy + certbot, port 443 open

| Dimension | Assessment |
|---|---|
| Complexity | Medium-high (reverse proxy, OAuth2-Proxy config, cert renewal, ongoing patching) |
| Cost | ~Free (a domain, if not already owned, is the only real cost) |
| Solves "painful HTTPS downloads"? | Yes -- real CA-signed cert |
| Solves "family authenticate"? | Yes -- OAuth2-Proxy can gate on Google accounts |
| Exposes home network? | Yes -- the Pi becomes a permanent internet-facing host |

**Pros:** Full control, no recurring cloud bill, a reusable gateway for
anything else run on the Pi later, a very standard self-hosting pattern.
**Cons:** The Pi (and by extension the home network) becomes directly
reachable from the internet permanently, raising the patching/maintenance
bar. CGNAT isn't a blocker for this specific fiber connection, but the
deciders have said plainly they'd rather not carry DDNS-style upkeep
going forward regardless. It also doesn't generalize to resale: every
future customer has a different router and a different chance of sitting
behind CGNAT, turning "open port 443" into per-customer tech support.
**Implementation note:** `lambada` has no HTTP server to put Nginx in
front of -- one would need to be written first.

### Option 3: Relay through Google App Engine

| Dimension | Assessment |
|---|---|
| Complexity | Medium (new sync/upload path from Pi to GAE; reuses existing GAE familiarity) |
| Cost | Likely near $0/month at this traffic level (App Engine free tier) |
| Solves "painful HTTPS downloads"? | Yes -- managed TLS, no renewal to babysit |
| Solves "family authenticate"? | Yes -- App Engine's built-in `login: required`/IAP-style auth is genuinely low-effort |
| Exposes home network? | No -- Pi only makes outbound calls, no inbound ports needed |

**Pros:** Sidesteps CGNAT/port-forwarding/dynamic-DNS entirely, reuses
infra already used elsewhere in this workspace, fully managed TLS and
auth.
**Cons:** Requires building a new piece that doesn't exist yet -- syncing
newly-scanned files from the device up to GAE (or a Cloud Storage bucket)
right after they're saved locally. Also a genuine values trade-off, not
just a technical one: the original design explicitly kept scans home-only
for privacy; this option puts them in Google's cloud instead. Worth a
deliberate yes/no, not an assumption.

### Option 4: Cloudflare Tunnel (not in the original list)

| Dimension | Assessment |
|---|---|
| Complexity | Low (`cloudflared` daemon on the Pi, config in Cloudflare's dashboard) |
| Cost | Free tier covers this easily |
| Solves "painful HTTPS downloads"? | Yes -- managed TLS via Cloudflare |
| Solves "family authenticate"? | Yes -- Cloudflare Access supports Google OAuth as an identity provider, same idea as Option 2's OAuth2-Proxy but with nothing to patch |
| Exposes home network? | No -- outbound-only tunnel, no port-forwarding, no CGNAT problem |

**Pros:** Solves the actual stated problem (HTTPS + auth + reachability)
with the least new infrastructure, no firewall changes, no cert renewal
cron, and scans never leave the Pi -- closest to the README's original
"stays on my home network" intent while still being reachable by family.
**Cons:** Adds a dependency on Cloudflare as a third party sitting in
front of the traffic (not literally storing files, but routing/auth do
flow through them) and a daemon to keep running on the device. For
resale, every customer also needs their own Cloudflare account and
Tunnel/Access configuration -- real, if modest, setup friction.
**Implementation note:** `cloudflared` tunnels to a *local* HTTP service
-- `lambada` doesn't have one (it only does SMTP-in/Samba-out), so this
option also means writing a small HTTP server in `lambada` first, not
just running a daemon in front of something that already exists.

### Option 5: Cloud storage relay -- S3/GCS bucket + thin authenticated gateway

| Dimension | Assessment |
|---|---|
| Complexity | Low (one new SDK call added inside `lambada`'s existing write path); a small serverless app for login + signed URLs |
| Cost | Pennies -- object storage + a Cloud Run/App Engine or Lambda function, free tier likely covers it |
| Solves "painful HTTPS downloads"? | Yes -- TLS is the cloud provider's problem, not the device's |
| Solves "family authenticate"? | Yes -- Google Sign-In (or any OAuth) in front of the gateway |
| Exposes home network? | No -- the device only ever makes outbound HTTPS calls, nothing listens |

`lambada` already writes every incoming attachment to disk inside its
SMTP backend's session handler -- the only new step is one outbound
upload call (AWS SDK or `google.golang.org/cloud` for GCS) added right
after that write, no separate file-watcher needed and no new local server
of any kind. A small serverless app -- Cloud Run or App Engine, reusing
the same "super easy" OAuth pattern already familiar from other projects
in this workspace -- handles login, lists each user's objects, and mints
short-lived signed URLs so the browser pulls bytes directly from blob
storage instead of through the app server.

**Pros:** Genuinely zero inbound exposure -- no DDNS, no certs, no open
port, no tunnel daemon, **no new server in `lambada` at all**. Generalizes
cleanly to resale: a new customer is "provision a bucket/prefix and
scoped credentials," not "walk them through their router." All the
HTTPS/auth complexity lives once, in infrastructure the vendor controls,
instead of being re-solved on every device in the field. Matches the
"this sounds more fun than overloading the little Pi" instinct -- the
device's job stays exactly as simple as it is today, plus one SDK call.
**Cons:** Scans now leave the home network for any customer who wants
remote access -- the same values trade-off Option 3 had, stated plainly
rather than assumed. Requires building the upload step and the
login/signed-URL gateway, neither of which exist yet (though the gateway
is simpler than a full Option 3-style app). Ties the product to a cloud
provider's storage pricing and OAuth setup per tenant.

## Trade-off Analysis

The decision now turns on two questions, not one. First: is "scans never
leave the device" a hard requirement? If yes, Option 4 (Cloudflare
Tunnel) is the answer -- it's the only remaining option with zero inbound
exposure that also never sends files anywhere else, though it now carries
a cost it didn't have when `scandalous` was the target: `lambada` has no
HTTP server for `cloudflared` to tunnel to, so a small one has to be
written first. If "never leave the device" is a soft preference rather
than a hard line, Option 5 (cloud storage relay) wins outright -- it
needs no new server in `lambada` at all:
it has the same zero-inbound-exposure property, removes DDNS/cert/router
concerns entirely, and -- the second question -- it's the one that
actually generalizes to "sell this to other people with minimal setup,"
since onboarding a new customer becomes a credentials/bucket provisioning
step instead of a per-router networking conversation. Option 2 is taken
off the table less because it's technically broken (it isn't, the domain
already works) and more because the deciders don't want the DDNS-adjacent
upkeep, and it doesn't scale to arbitrary customers' home networks.
Option 3 is subsumed by Option 5. Option 1 and Option 1b don't belong in
the final decision: 1 doesn't solve either original problem, and 1b
solves the cert half but pushes a real distribution/trust cost onto every
end user, which gets worse, not better, at resale scale.

## Consequences

- Choosing 5 means scans leave the home network for any customer who
  wants remote access -- a real change from "home network only," worth
  deciding deliberately rather than by default.
- Choosing 5 means a new, small serverless component to build and run
  (login + signed-URL gateway) and a cloud storage bill that scales with
  usage -- but no DNS, certs, or router config, ever, for any deployment.
- Choosing 4 keeps scans on the device but adds a Cloudflare account/
  Tunnel per deployment -- fine for one household, real friction times N
  for resale.
- Either choice retires Option 2's open-port-on-this-fiber-connection
  plan and the DDNS question that came with it.

## Action Items

1. [x] Domain/DNS resolved -- `casa.netpress.com` points at the fiber
   connection's external interface, `scans.netpress.com` resolves
   internally to the Pi (`10.0.1.111`), and the zone is fully
   self-managed. No longer load-bearing for the current direction (5 and
   4 both need no public DNS record at all), but useful if a friendly,
   memorable URL is still wanted for the gateway later.
2. [ ] Decide whether "scans never leave the device" is a hard
   requirement (-> Option 4) or a soft preference (-> Option 5, and the
   one that's actually sellable as a product).
3. [ ] Pick AWS (S3 + Lambda/CloudFront) or GCP (GCS + Cloud Run/App
   Engine) for Option 5 -- existing App Engine familiarity is a real tie-
   breaker toward GCP unless there's a reason to prefer AWS.
4. [ ] Prototype the upload step (Pi -> bucket) and the login + signed-URL
   gateway as a spike before touching the resale/multi-tenant story --
   get one household working end-to-end first.
5. [ ] If resale is pursued: design the per-customer provisioning step
   (bucket/prefix + scoped credentials + which Google account maps to
   which tenant) before building anything else customer-facing.
6. [ ] Decide where this ADR should actually live going forward --
   `scandalous` is the retired PoC that motivated it, but `lambada` is
   where the implementation lands. Consider copying or linking it into
   `lambada/docs/adr/` once work starts there.
