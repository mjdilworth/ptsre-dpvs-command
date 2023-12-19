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
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/mjdilworth/ptsre-dpvs-command/api"
)

var (
	InfoLogger  *log.Logger
	WarnLogger  *log.Logger
	ErrorLogger *log.Logger
)

func main() {

	//flags
	serverPort := flag.String("port", ":8080", "specify the port the server listens on")

	flag.Parse()

	//set up logging

	InfoLogger = log.New(os.Stdout, "INFO: ", log.Ldate|log.Ltime|log.Lshortfile)
	WarnLogger = log.New(os.Stdout, "WARN: ", log.Ldate|log.Ltime|log.Lshortfile)
	ErrorLogger = log.New(os.Stdout, "ERROR: ", log.Ldate|log.Ltime|log.Lshortfile)

	//start command goroutine
	command := make(chan string)
	go cmdInfo(command)
	command <- "Pause"

	srv := &http.Server{
		Addr: *serverPort,
	}

	//simple
	http.HandleFunc("/health/", api.Health)
	http.HandleFunc("/", api.Root)
	http.HandleFunc("/secret/", api.Auth)
	http.HandleFunc("/spacepeeps/", api.Spacepeeps)

	th := api.TimeHandler(time.RFC1123)
	http.Handle("/time", th)

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
	var status = "play"
	var level = "info"
	var gap = 1

	count := 0
	var commandPat = regexp.MustCompile(`^time=.`)

	for {

		select {

		case cmd := <-command:
			fmt.Println(cmd)
			switch cmd {
			case "stop":
				status = "stop"
			case "info":
				level = "info"
			case "warn":
				level = "warn"
			case "error":
				level = "error"

			default:
				if commandPat.MatchString(cmd) {
					pair := strings.Split(cmd, "=")
					gap, _ = strconv.Atoi(pair[1])
				}
				status = "play"
			}

		case <-time.After(time.Duration(gap) * time.Second):
			if status == "play" {
				count = count + 1
				switch level {
				case "info":
					InfoLogger.Println(count)
				case "warn":
					WarnLogger.Println(count)
				case "error":
					ErrorLogger.Println(count)
				}
			}
		}
	}
}
