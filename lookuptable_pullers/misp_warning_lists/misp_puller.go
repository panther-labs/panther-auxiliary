package main

import (
	"encoding/json"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
)

type RawWarningList struct {
	Name        string   `json:"name"`
	Version     int      `json:"version"`
	Description string   `json:"description"`
	List        []string `json:"list"`
	Type        string   `json:"type"`
}

type WarningList struct {
	Description []string `json:"description"`
	Name        []string `json:"name"`
	Version     []int    `json:"version"`
	ID          []string `json:"id"`
	CIDR        string   `json:"cidr"`
}

func normalizeIPv6(cidr string) string {
	// If it's already in IPv4-mapped IPv6 format, just add /128 if needed
	if strings.HasPrefix(cidr, "::ffff:") {
		if !strings.Contains(cidr, "/") {
			return cidr + "/128"
		}
		return cidr
	}

	ip, ipnet, err := net.ParseCIDR(cidr)
	if err != nil {
		return cidr
	}
	bits, _ := ipnet.Mask.Size()
	return fmt.Sprintf("%s/%d", ip.String(), bits)
}

func main() {
	baseDir := "misp-warninglists-main/lists"
	entries := make(map[string]WarningList)

	var jsonFiles []string
	err := filepath.Walk(baseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && strings.HasSuffix(path, ".json") {
			jsonFiles = append(jsonFiles, path)
		}
		return nil
	})
	if err != nil {
		fmt.Printf("Error walking directory: %v\n", err)
		return
	}

	for _, jsonFile := range jsonFiles {
		dirName := filepath.Base(filepath.Dir(jsonFile))
		if dirName == "vpn-ipv4" {
			continue
		}

		content, err := os.ReadFile(jsonFile)
		if err != nil {
			continue
		}

		var rawList RawWarningList
		if err := json.Unmarshal(content, &rawList); err != nil {
			continue
		}

		if rawList.Type != "cidr" {
			continue
		}

		for _, item := range rawList.List {
			if strings.Contains(item, "/") || net.ParseIP(item) != nil {
				cidr := item
				if net.ParseIP(item) != nil {
					if strings.Contains(item, ":") {
						cidr = item + "/128"
					} else {
						cidr = item + "/32"
					}
				}

				if strings.Contains(cidr, ":") {
					cidr = normalizeIPv6(cidr)
				}

				if entry, exists := entries[cidr]; exists {
					entry.Description = append(entry.Description, rawList.Description)
					entry.Name = append(entry.Name, rawList.Name)
					entry.Version = append(entry.Version, rawList.Version)
					entry.ID = append(entry.ID, dirName)
					entries[cidr] = entry
				} else {
					entries[cidr] = WarningList{
						Description: []string{rawList.Description},
						Name:        []string{rawList.Name},
						Version:     []int{rawList.Version},
						ID:          []string{dirName},
						CIDR:        cidr,
					}
				}
			}
		}
	}

	outputFile := "misp-warninglists-go.jsonl"
	f, err := os.Create(outputFile)
	if err != nil {
		fmt.Printf("Error creating output file: %v\n", err)
		return
	}
	defer f.Close()

	encoder := json.NewEncoder(f)
	for _, entry := range entries {
		if err := encoder.Encode(entry); err != nil {
			fmt.Printf("Error encoding entry: %v\n", err)
			continue
		}
	}
}
