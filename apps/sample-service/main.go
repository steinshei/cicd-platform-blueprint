package main

import (
	"io"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	http.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, "sample-service running\n")
	})

	// nosemgrep: go.lang.security.audit.net.use-tls.use-tls
	// TLS is terminated at ingress/load balancer in this demo service.
	_ = http.ListenAndServe(":"+port, nil)
}
