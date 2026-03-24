FROM golang:1.22-alpine AS build
WORKDIR /src
COPY go.mod ./
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/sample-service ./main.go

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/sample-service /sample-service
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/sample-service"]
