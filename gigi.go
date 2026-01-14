package main

import (
	"log"
	"net"
	"os"
	"os/exec"
	"strconv"
	"sync"
)

const (
	maximumCommandLength = 256
	modeStatic           = 0
	modeDynamic          = 1
)

var bufferPool = sync.Pool{
	New: func() interface{} {
		b := make([]byte, maximumCommandLength)

		return &b
	},
}

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

	listener, listenerError := net.Listen("tcp", ":"+fingerPortOption)

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
	connectionReadBuffer := bufferPool.Get().(*[]byte)

	defer bufferPool.Put(connectionReadBuffer)
	defer connection.Close()

	n, readError := connection.Read(*connectionReadBuffer)

	if readError != nil {
		log.Println("warn: could not read from connection")

		return
	}

	filename := cleanBuffer((*connectionReadBuffer)[:n])

	if len(filename) == 0 {
		filename = "default"
	}

	var fileContent []byte
	var fileReadError error

	switch mode {
	case modeDynamic:
		fileContent, fileReadError = runFile(filename)
	default:
		fileContent, fileReadError = readFile(filename)
	}

	if fileReadError != nil {
		log.Printf("warn: could not read from file: %s", filename)

		return
	}

	if _, connectionWriteError := connection.Write(fileContent); connectionWriteError != nil {
		log.Printf("warn: could not write to connection: %s", connectionWriteError.Error())
	} else {
		log.Printf("info: success: %s", filename)
	}
}

func cleanBuffer(buf []byte) string {
	result := make([]byte, 0, len(buf))

	for _, b := range buf {
		if b != 0 && b != '\n' && b != '\r' {
			result = append(result, b)
		}
	}

	return string(result)
}

func readFile(filename string) ([]byte, error) {
	fileContent, fileReadError := os.ReadFile("./.gigi/" + filename)

	if fileReadError != nil {
		fileContent, fileReadError = os.ReadFile("./.gigi/default")

		if fileReadError != nil {
			log.Printf("error: could not read from file: %s\n", filename)

			return nil, fileReadError
		}
	}

	return fileContent, nil
}

func runFile(arguments string) ([]byte, error) {
	command := exec.Command("./.gigi/do", arguments)
	commandOutput, commandError := command.Output()

	if commandError != nil {
		log.Printf("error: could not run command: %s\n", commandError)

		return nil, commandError
	}

	return commandOutput, nil
}
