package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/mjdilworth/ptsre-dpvs-command/api"
)

func main() {

	//flags
	serverPort := flag.String("port", ":8080", "specify the port the server listens on")

	flag.Parse()

	//start command goroutine
	command := make(chan string)
	go cmdInfo(command)
	command <- "Pause"

	srv := &http.Server{
		Addr: *serverPort,
	}

	th := api.TimeHandler(time.RFC1123)
	http.Handle("/time", th)

	http.HandleFunc("/health/", api.Health)
	http.HandleFunc("/", api.Root)
	http.HandleFunc("/secret/", api.Auth)
	http.HandleFunc("/spacepeeps/", api.Spacepeeps)
	lh := api.LogHandler(command)
	http.Handle("/log/", lh)
	http.HandleFunc("/log/help", api.Help)

	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
	}()
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt)
	<-quit
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal(err)
	}

}

func cmdInfo(command <-chan string) {
	var status = "Play"

	count := 0
	for {
		select {
		case cmd := <-command:
			fmt.Println(cmd)
			switch cmd {
			case "stop":
				return
			case "pause":
				status = "pause"
			case "info":
				status = "info"
			case "warn":
				status = "warn"
			case "error":
				status = "error"
			default:
				status = "play"
			}
		case <-time.After(1 * time.Second):
			if status == "play" {
				count = count + 1
			}
		}
	}
}
