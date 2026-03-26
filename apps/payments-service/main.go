package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprint(w, "ok")
	})
	log.Println("listening on :8080")
	// nosemgrep: go.lang.security.audit.net.use-tls.use-tls
	// In-cluster service traffic is terminated by ingress/service mesh; app listens on plain HTTP internally.
	log.Fatal(http.ListenAndServe(":8080", nil))
}
