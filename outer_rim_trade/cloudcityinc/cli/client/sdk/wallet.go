// --------------------------
// Copyright TangoJ Labs, LLC
// Apache 2.0 License
// --------------------------

package sdk

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-sdk-go/pkg/client/channel"
)

// *********************************************************************
// ************************** ChaincodeWallet **************************
// *********************************************************************

// Wallet structure organizes wallet balance information
type Wallet struct {
	Owner   string  `json:"owner"  binding:"required"`
	Balance float64 `json:"balance"`
	Status  string  `json:"status"`
}

// ************************** Query Functions **************************

// WalletQueryAll queries the Wallet ledger and returns all wallet balances
func (mgr *ClientManager) WalletQueryAll() ([]Wallet, error) {

	// Prepare arguments
	var args []string
	args = append(args, "query")
	args = append(args, "all")

	response, err := mgr.client.Query(channel.Request{ChaincodeID: ChaincodeWallet, Fcn: args[0], Args: [][]byte{[]byte(args[1])}})
	if err != nil {
		return nil, fmt.Errorf("failed to query: %v", err)
	}

	wallets := []Wallet{}
	err = json.Unmarshal(response.Payload, &wallets) //similar to JSON.parse()
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal: %v", err)
	}

	return wallets, nil
}

// ************************* Invoke Functions **************************

// Create a new wallet account
func (mgr *ClientManager) Create(owner string) (*Wallet, error) {

	// Prepare arguments
	var args []string
	args = append(args, "create")
	args = append(args, mgr.Username) //The new user should already have been logged in

	eventID := "eventInvoke"

	// Node.js doc description (https://fabric-shim.github.io/fabric-shim.ChaincodeProposalPayload.html):
	// TransientMap contains data (e.g. cryptographic material) that might be used to implement some form
	// of application-level confidentiality. The contents of this field are supposed to always be omitted
	// from the transaction and excluded from the ledger.
	transientDataMap := make(map[string][]byte)
	transientDataMap["result"] = []byte("transientDataMap")

	// Initialize the event object
	err := mgr.Event()
	if err != nil {
		return nil, fmt.Errorf("Transfer - failed to create Event object: %v", err)
	}

	// reg, notifier, err := mgr.event.RegisterChaincodeEvent(ccWallet, eventID)
	reg, _, err := mgr.client.RegisterChaincodeEvent(ChaincodeWallet, eventID)
	if err != nil {
		return nil, err
	}
	// defer mgr.event.Unregister(reg)
	defer mgr.client.UnregisterChaincodeEvent(reg)

	// Create a request (proposal) and send it
	response, err := mgr.client.Execute(channel.Request{ChaincodeID: ChaincodeWallet, Fcn: args[0], Args: [][]byte{[]byte(args[1])}, TransientMap: transientDataMap})
	if err != nil {
		return nil, fmt.Errorf("Transfer - failed to move funds: %v", err)
	}

	wallet := Wallet{}
	err = json.Unmarshal(response.Payload, &wallet) //similar to JSON.parse()
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal: %v", err)
	}

	// TODO: DEBUG WHY NOTIFIER NEVER RESPONDS
	// // Wait for the result of the submission
	// select {
	// case ccEvent := <-notifier:
	// 	fmt.Printf("Received CC event: %v\n", ccEvent)
	// case <-time.After(time.Second * 20):
	// 	return "", fmt.Errorf("did NOT receive CC event for eventId(%s)", eventID)
	// }

	return &wallet, nil
}

// Deposit to add credits to a wallet
func (mgr *ClientManager) Deposit(amount string) (*Wallet, error) {

	// Prepare arguments
	var args []string
	args = append(args, "deposit")
	args = append(args, mgr.Username)
	args = append(args, amount)

	eventID := "eventInvoke"

	// Node.js doc description (https://fabric-shim.github.io/fabric-shim.ChaincodeProposalPayload.html):
	// TransientMap contains data (e.g. cryptographic material) that might be used to implement some form
	// of application-level confidentiality. The contents of this field are supposed to always be omitted
	// from the transaction and excluded from the ledger.
	transientDataMap := make(map[string][]byte)
	transientDataMap["result"] = []byte("transientDataMap")

	// Initialize the event object
	err := mgr.Event()
	if err != nil {
		return nil, fmt.Errorf("Deposit - failed to create Event object: %v", err)
	}

	// reg, notifier, err := mgr.event.RegisterChaincodeEvent(ChaincodeWallet, eventID)
	// reg, notifier, err := mgr.client.RegisterChaincodeEvent(ChaincodeWallet, eventID)
	reg, _, err := mgr.client.RegisterChaincodeEvent(ChaincodeWallet, eventID)
	if err != nil {
		return nil, err
	}
	// defer mgr.event.Unregister(reg)
	defer mgr.client.UnregisterChaincodeEvent(reg)

	// Create a request (proposal) and send it
	response, err := mgr.client.Execute(channel.Request{ChaincodeID: ChaincodeWallet, Fcn: args[0], Args: [][]byte{[]byte(args[1]), []byte(args[2])}, TransientMap: transientDataMap})
	if err != nil {
		return nil, fmt.Errorf("Deposit - failed to move funds: %v", err)
	}

	wallet := Wallet{}
	err = json.Unmarshal(response.Payload, &wallet) //similar to JSON.parse()
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal: %v", err)
	}

	// TODO: DEBUG WHY NOTIFIER NEVER RESPONDS
	// // Wait for the result of the submission
	// select {
	// case ccEvent := <-notifier:
	// 	fmt.Printf("Received CC event: %v\n", ccEvent)
	// case <-time.After(time.Second * 20):
	// 	return nil, fmt.Errorf("did NOT receive CC event for eventId(%s)", eventID)
	// }

	return &wallet, nil
}

// Transfer to transfer between specific wallets
func (mgr *ClientManager) Transfer(params map[string]string) ([]Wallet, error) {

	// Prepare arguments
	var args []string
	args = append(args, "transfer")
	args = append(args, mgr.Username) //The "from" wallet
	args = append(args, params["to"])
	args = append(args, params["amount"])

	eventID := "eventInvoke"

	// Node.js doc description (https://fabric-shim.github.io/fabric-shim.ChaincodeProposalPayload.html):
	// TransientMap contains data (e.g. cryptographic material) that might be used to implement some form
	// of application-level confidentiality. The contents of this field are supposed to always be omitted
	// from the transaction and excluded from the ledger.
	transientDataMap := make(map[string][]byte)
	transientDataMap["result"] = []byte("transientDataMap")

	// Initialize the event object
	err := mgr.Event()
	if err != nil {
		return nil, fmt.Errorf("Transfer - failed to create Event object: %v", err)
	}

	// reg, notifier, err := mgr.event.RegisterChaincodeEvent(ccWallet, eventID)
	reg, _, err := mgr.client.RegisterChaincodeEvent(ChaincodeWallet, eventID)
	if err != nil {
		return nil, err
	}
	// defer mgr.event.Unregister(reg)
	defer mgr.client.UnregisterChaincodeEvent(reg)

	// Create a request (proposal) and send it
	response, err := mgr.client.Execute(channel.Request{ChaincodeID: ChaincodeWallet, Fcn: args[0], Args: [][]byte{[]byte(args[1]), []byte(args[2]), []byte(args[3])}, TransientMap: transientDataMap})
	if err != nil {
		return nil, fmt.Errorf("Transfer - failed to move funds: %v", err)
	}

	wallets := []Wallet{}
	err = json.Unmarshal(response.Payload, &wallets) //similar to JSON.parse()
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal: %v", err)
	}

	// TODO: DEBUG WHY NOTIFIER NEVER RESPONDS
	// // Wait for the result of the submission
	// select {
	// case ccEvent := <-notifier:
	// 	fmt.Printf("Received CC event: %v\n", ccEvent)
	// case <-time.After(time.Second * 20):
	// 	return "", fmt.Errorf("did NOT receive CC event for eventId(%s)", eventID)
	// }

	return wallets, nil
}
