# ontoportal-bubastis

A Ruby gem that ships the [bubastis](https://github.com/ncbo/bubastis) ontology
diff jar, so OntoPortal projects can depend on a versioned gem instead of
committing the binary.

The jar is built and released by [ncbo/bubastis](https://github.com/ncbo/bubastis/releases).
This repository only packages it: the jar is not committed here, it is
downloaded at build time and checked against the SHA-256 recorded in
`jars.sha256`.

## Usage

```ruby
gem 'ontoportal-bubastis'
```

```ruby
require 'ontoportal/bubastis'

Ontoportal::Bubastis.jar_path    # => ".../gems/ontoportal-bubastis-1.4.1/jars/bubastis-1.4.1.jar"
Ontoportal::Bubastis.jar_version # => "1.4.1"

system('java', '-jar', Ontoportal::Bubastis.jar_path,
       '-ontology1', old_file, '-ontology2', new_file,
       '-output', 'diff.xml', '-format', 'xml')
```

Bubastis needs Java 11 or later. It **exits 0 even when it cannot load an
input**, so check that the output file exists and is non-empty instead of
relying on the exit status.

## Versions

The gem version is the version of the jar it ships: gem 1.4.1 contains
`bubastis-1.4.1.jar`. A fix to the packaging alone, with the same jar, gets a
fourth segment (1.4.1.1). The jar version comes from `BUBASTIS_VERSION`; the
gem version comes from the release tag, and the build refuses a gem version
that does not start with the jar version.

Install from RubyGems. Using this repository as a Bundler `git:` source does
not work, because the jar is not in git.

## Development

Needs Ruby (with rake) and Java 11+.

```bash
rake jar:fetch   # download bubastis-$(cat BUBASTIS_VERSION).jar and verify its SHA-256
rake build       # fetch, then gem build
rake smoke       # build, gem install --local, run the smoke test against the installed gem
```

`script/smoke-test [jar]` diffs `test/smoke/v1.owl` and `v2.owl` (one class
added) and checks the XML report says `numberNewClasses` is 1. With no
argument it uses `Ontoportal::Bubastis.jar_path` from the installed gem.

`BUBASTIS_REPO=owner/repo` fetches from a different repository's releases
(for example a fork).

### Moving to a new bubastis release

1. Release the jar in ncbo/bubastis (tag `vX.Y.Z`, asset `bubastis-X.Y.Z.jar`).
2. Here, run `rake "jar:add[X.Y.Z]"`. It downloads the asset, appends its
   SHA-256 to `jars.sha256` and writes `BUBASTIS_VERSION`.
3. Compare the recorded checksum with the asset digest on the bubastis
   release (`gh release view vX.Y.Z -R ncbo/bubastis --json assets`).
4. Run `rake smoke`, commit, push, and check CI.

## Releasing

Publishing a GitHub release tagged `vX.Y.Z` (or `vX.Y.Z.N` for a
packaging-only fix) runs `.github/workflows/release.yml`. It fetches and
verifies the jar, builds the gem with `GEM_VERSION` taken from the tag,
smoke-tests the installed gem, attaches the `.gem` to the GitHub release and
pushes it to RubyGems.

RubyGems uses [trusted publishing](https://guides.rubygems.org/trusted-publishing/)
(OIDC), so no API key is stored in the repository. Before the first release, a
rubygems.org account that will own the gem must add a **pending trusted
publisher** (rubygems.org → Settings → Trusted Publishers, or
https://rubygems.org/profile/oidc/pending_trusted_publishers/new) with:

| Field | Value |
|---|---|
| Gem name | `ontoportal-bubastis` |
| Repository owner | `ncbo` |
| Repository name | `ontoportal-bubastis` |
| Workflow filename | `release.yml` |
| Environment | `rubygems` |

The repository also needs a GitHub environment named `rubygems` (Settings →
Environments); add required reviewers there to gate pushes. After the first
push the pending publisher becomes a normal trusted publisher on the gem.

## License

Apache License 2.0, the same as bubastis. See `LICENSE`.
