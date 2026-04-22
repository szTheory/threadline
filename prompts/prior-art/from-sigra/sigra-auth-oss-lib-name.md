# Brand background for `Sigra`

## Working name
**Sigra**

## Why this name

`Sigra` was chosen as a name for an Elixir / Plug / Phoenix authentication library intended to become a default, foundational choice for web apps.

The name works because it sits in a narrow sweet spot:

- it has a subtle connection to **signing**, **sign-in**, **signature**, **proof**, and **identity**
- it sounds like a **library/tool**, not a flashy startup or hosted auth vendor
- it is short, easy to say, and easy to remember
- it stands apart from the usual auth naming clichés like `Auth`, `Guard`, `Shield`, `Passport`, `Secure`, or `Vault`
- it feels calm, technical, and infrastructure-grade rather than noisy or gimmicky

## Semantic motivation

`Sigra` is not meant to be a literal descriptive name. It is meant to feel **adjacent to the core ideas of authentication**:

- **identity**
- **verification**
- **signatures**
- **claims**
- **proof**
- **trust at the boundary of an application**

That makes it a good root brand for a library that could grow beyond simple login flows into:

- sessions
- password auth
- magic links
- passkeys / WebAuthn
- OAuth / OIDC integrations
- token issuance and verification
- account lifecycle flows
- Phoenix / LiveView integration

In other words, `Sigra` suggests the *conceptual territory* of auth without sounding like a generic auth package.

## Why it is a good OSS library name

A strong OSS infrastructure name should usually be:

- short
- pronounceable
- distinct in a dependency list
- not overly literal
- not too “product/company” sounding
- broad enough to age well as the project expands

`Sigra` fits that profile well.

It feels closer to names like `Plug`, `Ecto`, `Oban`, or `Req` in spirit: compact, ownable, and usable as a package root. It can support a package family naturally, for example:

- `sigra`
- `sigra_phoenix`
- `sigra_plug`
- `sigra_liveview`
- `sigra_oauth`
- `sigra_passkey`

## Why not a more literal auth name

The auth ecosystem is already crowded with highly recognizable names. In Elixir/Phoenix alone, prominent names include **Pow**, **Guardian**, **Ueberauth**, and Phoenix’s built-in `phx.gen.auth`; outside Elixir, developers also already know names like **Devise**, **Rodauth**, **Clearance**, **Authlogic**, **Passport**, **Lucia**, and **Auth.js**. A new library name that sounds too obviously like “another auth lib” risks blending into that noise instead of standing apart.  [oai_citation:0‡Hex](https://hex.pm/packages?_utf8=%E2%9C%93&search=authentication&sort=recent_downloads&utm_source=chatgpt.com)

`Sigra` avoids that trap. It has enough auth-adjacent meaning to feel relevant, but enough abstraction to become its own brand.

## Distinctiveness / collision note

On a quick web pass, I did **not** find an obvious exact-match Hex package for `Sigra`, which is a good sign for Elixir package naming. I *did* find unrelated OSS usage of the similar spelling **SiGra** in computational biology, so the name is not globally unique across all software domains, but it does not appear to collide with the major Elixir/Phoenix auth-library naming space.  [oai_citation:1‡Hex](https://hex.pm/?utm_source=chatgpt.com)

So the practical positioning is:

- **clean enough for Elixir/Hex branding**
- **not obviously overlapping with existing Elixir auth incumbents**
- **not trapped in generic auth terminology**
- **still worth doing a final package / repo / org / trademark availability check before launch**

## Tone and brand feel

The intended feel of `Sigra` is:

- **trustworthy**
- **technical**
- **quietly authoritative**
- **minimal**
- **modern, but not trendy**
- **serious enough for infrastructure**

It should feel like a library developers can trust at the center of their app, not a marketing-heavy product name.

## Positioning statement

**Sigra** is a foundational authentication library for Elixir, Plug, and Phoenix: modular, secure, ergonomic, and built to become the canonical auth layer for modern Elixir web applications.

## One-sentence rationale

`Sigra` works because it evokes signing, identity, and proof while still sounding like a durable OSS library name rather than generic auth noise.