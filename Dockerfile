# Copyright 2021 Synology Inc.

############## Build stage ##############
# Upstream pins golang:1.21.4-alpine (Go 1.21, unsupported since Aug 2024); its
# stdlib is compiled into the static binary, so build with a supported Go.
FROM --platform=$BUILDPLATFORM golang:1.27-alpine AS builder
LABEL stage=synobuilder

RUN apk add --no-cache alpine-sdk
WORKDIR /go/src/synok8scsiplugin
COPY go.mod go.sum ./
RUN go mod download

COPY Makefile .

ARG TARGETPLATFORM

COPY main.go .
COPY pkg ./pkg
COPY synocli ./synocli
RUN env GOARCH=$(echo "$TARGETPLATFORM" | cut -f2 -d/) \
        GOARM=$(echo "$TARGETPLATFORM" | cut -f3 -d/ | cut -c2-) \
        make

############## Final stage ##############
# Ceres fork: upstream v1.4.0 moved to a UBI9 base whose packages (e2fsprogs,
# xfsprogs, nfs-utils, cifs-utils) need a RHEL entitlement to install, so it
# cannot be built on a GitHub runner. Keep the pre-v1.4.0 Alpine base instead.
FROM alpine:latest
LABEL maintainers="Synology Authors" \
      description="Synology CSI Plugin (Ceres Imaging fork)"

RUN apk add --no-cache e2fsprogs e2fsprogs-extra xfsprogs xfsprogs-extra blkid util-linux iproute2 bash btrfs-progs ca-certificates cifs-utils nfs-utils nvme-cli

WORKDIR /

# Copy and run CSI driver
COPY --from=builder /go/src/synok8scsiplugin/bin/synology-csi-driver synology-csi-driver

# As upstream v1.4.0: controller and snapshotter run unprivileged; the node
# DaemonSet overrides this with runAsUser: 0 for mount/format/chroot.
USER 1000

ENTRYPOINT ["/synology-csi-driver"]
