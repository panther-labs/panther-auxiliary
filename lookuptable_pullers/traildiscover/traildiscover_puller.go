package main

import (
	"bytes"
	"encoding/json"
	"io"
	"os"
	"path/filepath"
	"slices"
)

type Event struct {
	EventName string `json:"eventName"`
}

func main() {

	var eventsDirectory = "./events"
	var outputFileDirectory = "./docs/traildiscover.jsonl"

	fileList := make([]string, 0, 10)
	eventNamesList := make([]string, 0, 10)

	_ = filepath.Walk(eventsDirectory, func(path string, info os.FileInfo, err error) error {
		if filepath.Ext(path) == ".json" {
			fileList = append(fileList, path)
		}
		return nil
	})

	outputFile, _ := os.OpenFile(outputFileDirectory, os.O_APPEND|os.O_CREATE|os.O_WRONLY, os.ModePerm)

	for _, file := range fileList {
		jsonFile, _ := os.Open(file)
		defer jsonFile.Close()

		byteValue, _ := io.ReadAll(jsonFile)

		var event Event
		_ = json.Unmarshal(byteValue, &event)

		buffer := new(bytes.Buffer)
		_ = json.Compact(buffer, byteValue)
		trimmedByteValue := buffer.Bytes()

		if !slices.Contains(eventNamesList, event.EventName) {
			eventNamesList = append(eventNamesList, event.EventName)

			outputFile.Write(trimmedByteValue)
			outputFile.Write([]byte("\n"))
		}
	}
	println("Compiled events into", outputFileDirectory, "successfully.")
	defer outputFile.Close()
}
