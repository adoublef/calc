ARG GO_VERSION="1.26.3"

FROM --platform=${BUILDPLATFORM} golang:${GO_VERSION}-bookworm AS base

ARG TARGETOS
ARG TARGETARCH
ENV GOOS=${TARGETOS}
ENV GOARCH=${TARGETARCH}
ENV CGO_ENABLED=0
ENV GOPRIVATE="github.com/adoublef/*"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

WORKDIR /src

FROM base AS vendor

COPY go.* .

RUN --mount=type=ssh <<EOT
    set -e
    echo "Setting Git SSH protocol"
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    (
        set +e
        ssh -T git@github.com
        if [ ! "$?" = "1" ]; then
            echo "No GitHub SSH key loaded exiting..."
            exit 1
        fi
    )
EOT

RUN --mount=target=bind,target=. \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=ssh \
    go mod download -x
# RUN go vet -v
# RUN go test -v

FROM vendor AS build

COPY . .

RUN --mount=type=bind,target=. \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache \
    go build \
    -tags=osusergo,netgo,timetzdata \
    -o=/usr/local/bin/a.out .

# setting '--platform=${TARGETPLATFORM}' here is redundant as this is the default
FROM gcr.io/distroless/static-debian12 AS runtime

COPY --from=build /usr/local/bin/a.out /usr/local/bin/a.out

ENTRYPOINT [ "a.out" ]
