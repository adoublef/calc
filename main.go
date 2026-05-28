package main

import (
	"fmt"
	"net/http"

	"github.com/adoublef/priv/math"
)

func main() {
	panic(run())
}

func run() error {
	return http.ListenAndServe(":8080", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// add numbers
		res := math.Add(1, 2)
		fmt.Fprintf(w, "%d\n", res)
	}))
}
