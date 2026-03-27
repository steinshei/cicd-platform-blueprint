FROM golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod ./
COPY . .
ARG TARGETOS
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} go build -o /out/sample-service ./main.go

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/sample-service /sample-service
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["/sample-service"]
