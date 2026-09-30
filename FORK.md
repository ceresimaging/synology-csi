# Ceres Imaging fork of synology-csi

Downstream build of [SynologyOpenSource/synology-csi](https://github.com/SynologyOpenSource/synology-csi). Not affiliated with Synology: report driver bugs upstream.

## Why this fork

- Upstream v1.4.0 was released on GitHub but never pushed to [Docker Hub](https://hub.docker.com/r/synology/synology-csi) (latest there is v1.3.1), so its manifests fail with `ImagePullBackOff`.
- v1.4.0 moved the image to Red Hat UBI9, and `e2fsprogs`, `xfsprogs`, `nfs-utils` and `cifs-utils` only come from entitled RHEL repos, so it can't be built on a stock host or CI runner. This fork builds the v1.4.0 driver code on the Alpine base image used up to v1.3.1.
- We carry patches not yet merged upstream (see [Patches](#patches)).

## Images

`ghcr.io/ceresimaging/synology-csi`, public, for `linux/amd64`, `linux/arm64` and `linux/arm/v7`.

| Tag | Built from | Content |
|---|---|---|
| `vX.Y.Z-alpine.N` | `alpine` | Stock upstream release code, Alpine base, current Go toolchain |
| `vX.Y.Z-ceres.N` | `ceres` | The above plus our patches |
| `alpine`, `ceres`, `sha-<commit>` | Branch pushes | Moving tags for testing; pin the release tags above |

Differences from the upstream v1.4.0 image: Alpine instead of UBI9 base, built with a supported Go (upstream pins unsupported Go 1.21), `btrfs-progs` included, no Red Hat certification labels. Like upstream it runs as `USER 1000`, so the node DaemonSet needs `runAsUser: 0` (set in `deploy/`).

## Branches

| Branch | Content |
|---|---|
| `main` | Fast-forward mirror of upstream `main`; never commit to it |
| `alpine` | Upstream release tag + one packaging commit (Dockerfile, CI, this file, image references) |
| `ceres` (default) | `alpine` + patches + one commit pointing `deploy/` at the `ceres` image |

## Releasing

New upstream release `vX.Y.Z`:

```sh
gh repo sync ceresimaging/synology-csi -b main
git fetch origin --tags                  # origin = upstream
git rebase --onto vX.Y.Z <old-tag> alpine   # then update image tags in deploy/ and README
git rebase --onto alpine <old-alpine> ceres # patches merged upstream drop out here
git push --force-with-lease ceres alpine ceres
git tag -a vX.Y.Z-alpine.1 alpine -m "..." && git tag -a vX.Y.Z-ceres.1 ceres -m "..."
git push ceres vX.Y.Z-alpine.1 vX.Y.Z-ceres.1
```

The `alpine` and `ceres` branches are protected against force-push and deletion; the rebase above needs a repository admin (ruleset bypass).

Bump `N` (both lines) for packaging changes or a rebuild on a newer Alpine base or Go toolchain, and in `-ceres.N` when the patches change. Images are only rebuilt on pushes or a manual run of *Build and publish images* (`workflow_dispatch`); there is no scheduled rebuild. When the builder's Go minor version (`golang:1.27-alpine` in the Dockerfile) goes out of support, bump it.

## Patches

Carried on `ceres` only:

| Patch | Upstream | Status |
|---|---|---|
