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
  - Custom functions added
  - Function content rewritten
*/

package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// ChaincodeWallet is a empty structure to represent the chaincode object
type ChaincodeWallet struct{}

type wallet struct {
	ObjectType string  `json:"docType"` //docType is used to distinguish the various types of objects in state database
	Owner      string  `json:"owner"`
	Balance    float64 `json:"balance"`
	Status     string  `json:"status"`
}

// Init initializes the chaincode
func (c *ChaincodeWallet) Init(stub shim.ChaincodeStubInterface) pb.Response {

	// For this example we will not initialize with any ledger entries
	return shim.Success(nil)
}

// Invoke handles all actions on this chaincode
// the first argument passed specifies the function
func (c *ChaincodeWallet) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("Wallet CC Invoke")
	function, args := stub.GetFunctionAndParameters()
	if function == "create" {
		// Creates a new wallet
		return c.create(stub, args)
	} else if function == "deposit" {
		// Deposit credits into an account
		return c.deposit(stub, args)
	} else if function == "transfer" {
		// Make payment from the logged in user to another account
		return c.transfer(stub, args)
	} else if function == "delete" {
		// Delete a wallet
		return c.delete(stub, args)
	} else if function == "query" {
		// Queries the ledger for a wallet value
		return c.query(stub, args)
	}

	return shim.Error("Invalid invoke function name. Expecting 'create', 'deposit', 'transfer', delete', 'query'")
}

// Creates a new wallet with the standard initial amount
func (c *ChaincodeWallet) create(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	// Input sanitation
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting name of wallet owner")
	}
	if len(args[0]) <= 0 {
		return shim.Error("Argument must be a non-empty string")
	}

	// Get the wallet owner name
	owner := args[0]
	fmt.Printf("ccWallet: CREATE wallet for user: %s\n", owner)

	// Check if a wallet for that owner already exists
	walletAsBytes, err := stub.GetState(owner)
	if err != nil {
		return shim.Error("Failed to get wallet: " + err.Error())
	} else if walletAsBytes != nil {
		return shim.Error("A wallet already exists for owner: " + owner)
	}

	// Create the wallet based on owner name
	objectType := "wallet"
	balance := 0.0
	status := "active"
	wallet := &wallet{objectType, owner, balance, status}
	walletJSONasBytes, err := json.Marshal(wallet)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Save wallet to state
	err = stub.PutState(owner, walletJSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(walletJSONasBytes)
}

// Deposit adds an amount to a current wallet account
func (c *ChaincodeWallet) deposit(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	// Input sanitation
	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}
	if len(args[0]) <= 0 && len(args[1]) <= 0 {
		return shim.Error("All arguments must be non-empty strings")
	}

	// Get the wallet owner name
	owner := args[0]
	amount, err := strconv.ParseFloat(args[1], 64)
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Printf("ccWallet: DEPOSIT %f into wallet: %s\n", amount, owner)

	// ============== GET WALLET ==============
	// Get the current balance for updating
	walletAsBytes, err := stub.GetState(owner)
	if err != nil {
		return shim.Error("Failed to get wallet: " + err.Error())
	}

	wallet := wallet{}
	err = json.Unmarshal(walletAsBytes, &wallet) //similar to JSON.parse()
	if err != nil {
		return shim.Error(err.Error())
	}
	wallet.Balance = wallet.Balance + amount

	// ============== SET WALLET ==============
	// Save wallet to state
	walletJSONasBytes, err := json.Marshal(wallet)
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.PutState(owner, walletJSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Return the updated wallet as bytes to update the GUI
	return shim.Success(walletJSONasBytes)
}

// Transfer makes payment of from one account to another
func (c *ChaincodeWallet) transfer(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	// Input sanitation
	if len(args) != 3 {
		return shim.Error("Incorrect number of arguments. Expecting 3")
	}
	if len(args[0]) <= 0 && len(args[1]) <= 0 && len(args[2]) <= 0 {
		return shim.Error("All arguments must be non-empty strings")
	}

	// Get the wallet owners names
	ownerFrom := args[0]
	ownerTo := args[1]
	amount, err := strconv.ParseFloat(args[2], 64)
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Printf("ccWallet: TRANSFER %f from %s to %s\n", amount, ownerFrom, ownerTo)

	// ============== GET WALLETS ==============

	// Get the FROM wallet balance for updating
	walletFromAsBytes, err := stub.GetState(ownerFrom)
	if err != nil {
		return shim.Error("Failed to get FROM wallet: " + err.Error())
	}
	walletFrom := wallet{}
	err = json.Unmarshal(walletFromAsBytes, &walletFrom) //similar to JSON.parse()
	if err != nil {
		return shim.Error(err.Error())
	}
	walletFrom.Balance = walletFrom.Balance - amount

	// Get the TO wallet balance for updating
	walletToAsBytes, err := stub.GetState(ownerTo)
	if err != nil {
		return shim.Error("Failed to get TO wallet: " + err.Error())
	}
	walletTo := wallet{}
	err = json.Unmarshal(walletToAsBytes, &walletTo) //similar to JSON.parse()
	if err != nil {
		return shim.Error(err.Error())
	}
	walletTo.Balance = walletTo.Balance + amount

	// ============== SET WALLETS ==============

	// Save FROM wallet to state
	walletFromJSONasBytes, err := json.Marshal(walletFrom)
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.PutState(ownerFrom, walletFromJSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Save TO wallet to state
	walletToJSONasBytes, err := json.Marshal(walletTo)
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.PutState(ownerTo, walletToJSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	// buffer is a JSON array containing QueryRecords
	var buffer bytes.Buffer
	buffer.WriteString("[")
	buffer.WriteString(string(walletFromJSONasBytes))
	buffer.WriteString(",")
	buffer.WriteString(string(walletToJSONasBytes))
	buffer.WriteString("]")

	// Return the updated wallets as bytes to update the GUI
	return shim.Success(buffer.Bytes())
}

// Deletes an entity from state
func (c *ChaincodeWallet) delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	// Get the wallet owner name
	owner := args[0]
	fmt.Printf("ccWallet: DELETE wallet for user: %s\n", owner)

	// Delete the key from the state in ledger
	err := stub.DelState(owner)
	if err != nil {
		return shim.Error("Failed to delete state")
	}

	return shim.Success(nil)
}

// Queries the wallet values from the ledger
func (c *ChaincodeWallet) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var responseBytes []byte

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting name of the person to query")
	}

	// Get the wallet owner name
	owner := args[0]
	fmt.Printf("ccWallet: QUERY: %s\n", owner)

	if owner == "all" {
		// Return all active wallets
		// Create the query string
		queryString := `{
			"selector": {
				"status": "active"
			}
		}`

		resultsIterator, err := stub.GetQueryResult(queryString)
		if err != nil {
			return shim.Error(err.Error())
		}
		defer resultsIterator.Close()

		// buffer is a JSON array containing QueryRecords
		var buffer bytes.Buffer
		buffer.WriteString("[")

		bArrayMemberAlreadyWritten := false
		for resultsIterator.HasNext() {
			queryResponse, err := resultsIterator.Next()
			if err != nil {
				return shim.Error(err.Error())
			}
			// Add a comma before array members, suppress it for the first array member
			if bArrayMemberAlreadyWritten == true {
				buffer.WriteString(",")
			}
			buffer.WriteString(string(queryResponse.Value))
			bArrayMemberAlreadyWritten = true
		}
		buffer.WriteString("]")
		responseBytes = buffer.Bytes()

	} else {
		// Get the state from the ledger
		queryResponse, err := stub.GetState(owner)
		if err != nil {
			jsonResp := "{\"Error\":\"Failed to get state for " + owner + "\"}"
			return shim.Error(jsonResp)
		}
		if queryResponse == nil {
			jsonResp := "{\"Error\":\"Nil amount for " + owner + "\"}"
			return shim.Error(jsonResp)
		}

		// buffer is a JSON array containing QueryRecords
		var buffer bytes.Buffer
		buffer.WriteString("[")
		buffer.WriteString(string(queryResponse))
		buffer.WriteString("]")
		responseBytes = buffer.Bytes()
	}

	return shim.Success(responseBytes)
}

func main() {
	err := shim.Start(new(ChaincodeWallet))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}
