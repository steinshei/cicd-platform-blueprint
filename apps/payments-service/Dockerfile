FROM golang:1.26-alpine AS build
WORKDIR /src
COPY . .
RUN go build -o /out/app .

FROM alpine:3.20
RUN adduser -D -u 10001 appuser
USER 10001
COPY --from=build /out/app /app
EXPOSE 8080
ENTRYPOINT ["/app"]
