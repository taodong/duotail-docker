# Patch instructions: `haraka-plugin-mailauth` breaks on Haraka 3.3.x

**Repo/dir for this work:** `duotail-docker/images/haraka`
**Written:** 2026-09-02 — diagnosed from prod logs of `haraka-5b6fcccb48-*` (release 0.4.0 testing)
**Status:** ready to implement. This document is the design doc for the change.

---

## 1. Symptom

All inbound mail is dropped. The collector logs, for every message:

```
c.d.c.s.cachestorage.LoadingMailStorage : Skip DB logging due to missing owner or process status in event <emailId>
```

The Kafka `message-summary` payload always carries `spfCheck=unknown, dkimCheck=fail`, even for
correctly-signed Gmail mail.

## 2. Root cause

`haraka-plugin-mailauth@1.1.1` crashes on **every** transaction, in both of its hooks, so SPF/DKIM
are never evaluated at all.

Haraka container log (`/var/log/haraka/*-out.log`):

```
[CRIT] Plugin mailauth failed: TypeError: params[0].address is not a function
    at exports.hook_mail (/haraka-duotail/node_modules/haraka-plugin-mailauth/index.js:65:30)

[ERROR] [mailauth] TypeError: Cannot set properties of undefined (setting 'dkim')
    at hookDataPostAsync (/haraka-duotail/node_modules/haraka-plugin-mailauth/index.js:121:33)
```

The second error is a consequence of the first: `hook_mail` throws before assigning
`txn.notes.mailauth`, so `hook_data_post` writes `.dkim` onto `undefined`.

### Why `.address()` is no longer a function

Haraka core migrated its address parser. `Dockerfile` pins `HARAKA_VERSION=3.3.3`, which depends on
`@haraka/email-address ~3.1.6`, where `address` is a **getter**, not a method:

```js
// @haraka/email-address 3.1.6 — lib/address.js:117
get address() {
  if (!this.user) return ''
  if (!this.original_host && !this.host) return this.user
  return `${this.user}@${this.original_host || this.host}`
}
```

Core passes the raw parsed Address straight to the hook, unwrapped:

```js
// Haraka 3.3.3 — connection.js (cmd_mail)
plugins.run_hooks('mail', this, [from, params])
```

Haraka 3.2.x had a compat shim (`address.js`, using `asLegacy()`) that made both `.address` and
`.address()` work. It was removed in 3.3.1: *"change: remove @haraka/email-address wrapper #3598"*.

The plugin still uses the old method contract, at exactly one call site:

```js
// haraka-plugin-mailauth 1.1.1 — index.js:65
const sender = params[0].address();
```

`address-rfc2821` is not installed anywhere in the image — this is an API break, not a duplicate-dependency
problem.

### No upstream fix exists

`npm view haraka-plugin-mailauth versions` → `1.0.0, 1.0.1, 1.0.2, 1.1.0, 1.1.1`. `1.1.1` is latest,
published ~a year ago. Bumping the dependency will not help; we must carry the patch.

## 3. Decision: patch, do not downgrade Haraka

Downgrading to Haraka 3.2.1 would work (its shim makes `.address()` callable), but it gives up
3.3.3's log-injection hardening, including **GHSA-4gxg-q43p-hfr2** (`fix(conn): sanitize Message-ID
before logging`). The duotail plugin logs `mid=` and the full summary JSON on every message, so that
advisory is directly in our path. The 3.2.x shim is also marked `SUNSET 2027`.

**Keep `HARAKA_VERSION=3.3.3`. Patch the plugin at image build time.**

## 4. The change

### 4.1 Pin the patch target

In `package.json`, change the caret range to an exact pin so the patched line can't shift under us:

```diff
-    "haraka-plugin-mailauth": "^1.1.1",
+    "haraka-plugin-mailauth": "1.1.1",
```

### 4.2 Apply the patch in the Dockerfile

Insert this **after** the existing `RUN cd /haraka-duotail && npm install` line and **before** the
`cp -r ... plugins/duotail` line:

```dockerfile
# PATCH: haraka-plugin-mailauth 1.1.1 predates Haraka 3.3's address API change.
# Core now passes an @haraka/email-address Address whose `.address` is a getter,
# not a method, so the plugin's `params[0].address()` throws in hook_mail and
# SPF/DKIM never run. Upstream is unmaintained (1.1.1 is latest, ~1yr old).
# The grep guards make the build FAIL LOUDLY if upstream ever changes this line,
# rather than silently producing an image with no DKIM checking.
# See mailauth-patch-instructions.md. Remove if upstream ships a Haraka 3.3 fix.
RUN cd /haraka-duotail/node_modules/haraka-plugin-mailauth && \
    grep -q 'const sender = params\[0\]\.address();' index.js && \
    sed -i 's/const sender = params\[0\]\.address();/const sender = params[0].address;/' index.js && \
    grep -q 'const sender = params\[0\]\.address;' index.js
```

That is the whole functional change: one call site, `.address()` → `.address`.

**Behavior note:** null reverse-paths (our `0_` VERP bounce traffic) stay correct — the getter
returns `''` for an empty user, matching what the old method returned.

### 4.3 Alternative considered

`patch-package` with a checked-in `patches/` file is the more conventional route, but it needs a new
dev dependency plus a `postinstall` hook, and this image runs a bare `npm install` with no lockfile.
The guarded `sed` gives the same build-time failure signal with no new tooling. Use `patch-package`
instead if the image later gains a lockfile and more patches.

## 5. Verification

Build and inspect the patched line before shipping:

```bash
docker build -t haraka-patch-test images/haraka
docker run --rm haraka-patch-test \
  sed -n '65p' /haraka-duotail/node_modules/haraka-plugin-mailauth/index.js
# expect: const sender = params[0].address;
```

Then deploy and send one test message through. In `/var/log/haraka/*-out.log`, confirm:

- **absent:** `Plugin mailauth failed: TypeError: params[0].address is not a function`
- **absent:** `Cannot set properties of undefined (setting 'dkim')`
- **present:** the `[duotail] Processed email:` line now shows `\"dkimCheck\":\"pass\"` for a
  signed sender (e.g. Gmail)

Then confirm in the collector log that the message routes instead of producing
`Skip DB logging due to missing owner or process status`.

## 6. Rollback

Delete the `RUN` block and rebuild. Nothing else in the image depends on it. While the fix is being
built/reviewed, the collector-side stopgap is `allow-unsecure-mail=true`, which opens the DKIM gate
without touching this image — riskier (all unauthenticated mail passes), so hours, not days.

## 7. Out of scope — track separately

These are real, were found in the same investigation, and do **not** belong in this repo:

1. **`hakara-plugin-duotail/index.js:159`** — `extractDkimResult` maps a missing/empty mailauth
   result to `'fail'`, while its SPF sibling (line 156) maps the same absence to `'unknown'`. That
   asymmetry is what converted a crashed verifier into silently blackholed mail. Should return
   `'unknown'` when the `mailauth` transaction note is absent.
2. **`duotail-message-collector` `MessageFilterService.filter()`** — the DELETE fall-through emits no
   log line explaining *why* a message was dropped, so the only evidence was a misleading downstream
   ERROR. Needs a warn with emailId, dkim/spf values, and rcptTo.
3. **TLS is not configured in prod** — `tls key/cert /haraka-duotail/config/haraka-duotail/certs/*.pem
   could not be loaded` and `[ERROR] [tls] no valid TLS config`; every connection logs `tls=N`.
   Unrelated to this bug, but inbound mail is arriving in plaintext.
