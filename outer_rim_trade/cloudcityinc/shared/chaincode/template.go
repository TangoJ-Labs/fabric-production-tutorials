/*
Copyright IBM Corp. 2016 All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

		 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// ChaincodeTemplate is a empty structure to represent the chaincode object
type ChaincodeTemplate struct{}

// Init initializes the chaincode
func (c *ChaincodeTemplate) Init(stub shim.ChaincodeStubInterface) pb.Response {

	_, args := stub.GetFunctionAndParameters()

	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	// Write the initial key:value pair to the ledger
	err := stub.PutState(args[0], []byte(args[1]))
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

// Invoke uses a shim - the first passed argument determines the function
// required and remaining arguments are passed to helper function
// Shim accepted functions: "invoke", "delete", "query"
func (c *ChaincodeTemplate) Invoke(stub shim.ChaincodeStubInterface) pb.Response {

	// Get the passed function name (for the shim), and the arguments
	// The first returned value is the function name
	function, args := stub.GetFunctionAndParameters()
	if function == "invoke" {
		return c.invoke(stub, args)
	} else if function == "delete" {
		return c.delete(stub, args)
	} else if function == "query" {
		return c.query(stub, args)
	}
	return shim.Error("Invalid invoke function name. Expecting \"invoke\" \"delete\" \"query\"")
}

func (c *ChaincodeTemplate) invoke(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	fmt.Printf("key: %s, value: %s\n", args[0], args[1])

	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	// Write the initial key:value pair to the ledger
	err := stub.PutState(args[0], []byte(args[1]))
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

func (c *ChaincodeTemplate) delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	// Delete the passed key from the ledger
	err := stub.DelState(args[0])
	if err != nil {
		return shim.Error("Failed to delete key")
	}

	return shim.Success(nil)
}

func (c *ChaincodeTemplate) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	fmt.Printf("query: %s\n", args[0])

	// Get the state from the ledger
	valueBytes, err := stub.GetState(args[0])
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get value for " + args[0] + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(valueBytes)
}

func main() {
	err := shim.Start(new(ChaincodeTemplate))
	if err != nil {
		fmt.Printf("Error starting chaincode: %s", err)
	}
}
