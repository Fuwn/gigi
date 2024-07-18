package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

const (
	maximumCommandLength = 256
	modeStatic           = 0
	modeDynamic          = 1
)

func main() {
	fingerPortOption := os.Getenv("GIGI_PORT")
	modeOption := os.Getenv("GIGI_DYNAMIC")
	mode := modeStatic

	if fingerPortOption == "" {
		fingerPortOption = "79"
	}

	if modeOption != "" {
		if mode, _ = strconv.Atoi(modeOption); mode > 0 {
			mode = modeDynamic
		}
	}

	listener, listenerError := net.Listen("tcp", fmt.Sprintf(":%s", fingerPortOption))

	if listenerError != nil {
		log.Fatalf("error: %s\n", listenerError.Error())
	}

	for {
		connection, connectionError := listener.Accept()

		if connectionError != nil {
			log.Println("warn: listener could not accept connection")
		}

		go handleConnection(connection, mode)
	}
}

func handleConnection(connection net.Conn, mode int) {
	defer connection.Close()

	connectionReadBuffer := make([]byte, maximumCommandLength)
	_, readError := connection.Read(connectionReadBuffer)

	if readError != nil {
		log.Println("warn: could not read from connection")

		return
	}

	bufferContent := strings.Replace(
		strings.Replace(
			strings.Replace(string(connectionReadBuffer), "\x00", "", -1),
			"\n", "", -1), "\r", "", -1)

	if len(bufferContent) == 0 {
		bufferContent = "default"
	}

	var fileContent string
	var fileReadError error

	switch mode {
	case modeDynamic:
		fileContent, fileReadError = runFile(bufferContent)

	default:
		fileContent, fileReadError = readFile(bufferContent)
	}

	if fileReadError != nil {
		log.Printf("warn: could not read from file: %s", bufferContent)

		return
	}

	connection.Write([]byte(fileContent))
	log.Printf("info: success: %s", bufferContent)
}

func readFile(filename string) (string, error) {
	fileContent, fileReadError := os.ReadFile(fmt.Sprintf("./.gigi/%s", filename))

	if fileReadError != nil {
		fileContent, fileReadError = os.ReadFile("./.gigi/default")

		if fileReadError != nil {
			log.Printf("error: could not read from file: %s\n", filename)

			return "", fileReadError
		}
	}

	return string(fileContent), nil
}

func runFile(arguments string) (string, error) {
	command := exec.Command("./.gigi/do", arguments)
	commandOutput, commandError := command.Output()

	if commandError != nil {
		log.Printf("error: could not run command: %s\n", commandError)

		return "", commandError
	}

	return string(commandOutput), nil
}
