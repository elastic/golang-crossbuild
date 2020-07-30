// Licensed to Elasticsearch B.V. under one or more contributor
// license agreements. See the NOTICE file distributed with
// this work for additional information regarding copyright
// ownership. Elasticsearch B.V. licenses this file to you under
// the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package main

import (
	"bytes"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"text/template"
)

var usageText = `
Usage: template -t <tmpl file> [-o output]
  This command renders the specified template file using the Go text/template
  package. It makes the current environment available as variables.
Options:
`[1:]

var (
	templateFile string
	outputFile   string
)

func init() {
	flag.StringVar(&templateFile, "t", "", "template file")
	flag.StringVar(&outputFile, "o", "", "output file")
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, usageText)
		flag.PrintDefaults()
	}
}

func main() {
	flag.Parse()
	log.SetFlags(0)

	if templateFile == "" {
		log.Fatal("Template file (-t) is required.")
	}

	t := template.Must(template.
		New(filepath.Base(templateFile)).
		ParseFiles(templateFile))

	data := envVars()
	buf := new(bytes.Buffer)
	if err := t.Execute(buf, data); err != nil {
		log.Fatal(err)
	}

	if outputFile == "-" || outputFile == "" {
		fmt.Println(buf.String())
	} else {
		if err := ioutil.WriteFile(outputFile, buf.Bytes(), 0644); err != nil {
			log.Fatal(err)
		}
	}
}

func envVars() map[string]string {
	env := map[string]string{}
	for _, e := range os.Environ() {
		parts := strings.SplitN(e, "=", 2)
		env[parts[0]] = parts[1]
	}
	return env
}
