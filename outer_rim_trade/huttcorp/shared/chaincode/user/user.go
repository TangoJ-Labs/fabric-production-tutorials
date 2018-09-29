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

/*
TangoJ Labs, LLC changes:
  - Some functions renamed
  - Function content rewritten
*/

package main

import (
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// ChaincodeUser is a blank structure to represent the chaincode object
type ChaincodeUser struct{}

// Init initializes the chaincode
func (c *ChaincodeUser) Init(stub shim.ChaincodeStubInterface) pb.Response {

	// Init does not need to set any initial values on the ledger
	return shim.Success(nil)
}

// Invoke uses a shim - the first passed argument determines the function
// required and remaining arguments are passed to helper function
// Shim accepted functions: "create", "delete", "query"
func (c *ChaincodeUser) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("User CC Invoke")
	// Get the passed function name (for the shim), and the arguments
	// The first returned value is the function name
	function, args := stub.GetFunctionAndParameters()
	if function == "create" {
		return c.create(stub, args)
	} else if function == "delete" {
		return c.delete(stub, args)
	} else if function == "query" {
		return c.query(stub, args)
	}
	return shim.Error("Invalid invoke function name. Expecting \"create\" \"delete\" \"query\"")
}

func (c *ChaincodeUser) create(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	// Prepare the needed variables and check to ensure the passed args are the number expected
	var username, passHash string
	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	// The arguments are strings and the password has already been hashed (bcrypt)
	username = args[0]
	passHash = args[1]
	fmt.Println("ccUser: CREATE user: " + username)

	// Write the state to the ledger
	err := stub.PutState(username, []byte(passHash))
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

func (c *ChaincodeUser) delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	return shim.Error("Account deletion is not activated on this chaincode at this time.")
}

func (c *ChaincodeUser) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	// Prepare the needed variables and check to ensure the passed args are the number expected
	var username string
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	// The arguments are strings and the password has already been hashed (bcrypt)
	username = args[0]
	fmt.Println("ccUser: QUERY user: " + username)

	// Get the state from the ledger
	passHashBytes, err := stub.GetState(username)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get passHash for " + username + "\"}"
		return shim.Error(jsonResp)
	}

	// If the username is not found DO NOT RETURN ERROR
	// Just return success with the nil value - the client will handle
	// a missing user - otherwise the client cannot distinguish between
	// a missing user and other errors

	return shim.Success(passHashBytes)
}

func main() {
	err := shim.Start(new(ChaincodeUser))
	if err != nil {
		fmt.Printf("Error starting Account chaincode: %s", err)
	}
}
