// --------------------------
// Copyright TangoJ Labs, LLC
// Apache 2.0 License
// --------------------------

package sdk

import (
	"fmt"

	"github.com/hyperledger/fabric-sdk-go/pkg/client/channel"
	"golang.org/x/crypto/bcrypt"
)

// *********************************************************************
// *************************** ChaincodeUser ***************************
// *********************************************************************

// LoginHandler run a series of processes to authenticate the user and set their CA identity:
// Query the User ledger for user:
// 	├── 1.0) Exists: verify password hash
//	│	├── 1.1) Password incorrect: -return error
//	│	└── 1.2) Password correct: create Client object with user CA identity in local credential store
//	│		├── 1.2a) CA identity exists: set identity and -return successful
//	│		└── 1.2b) CA identity missing: re-enroll user and set client object with returned CA credentials -return successful
//	│			└── 1.2bE) BUG: re-enrollment fails: register user (see (2) below)
// 	└── 2.0) Does not exist: register user with CA
// 		├── 2.0E) BUG: registration fails (user already registered) - re-enroll user and set identity with returned CA credentials -return successful
// 		└── 2.1) registration succeeds: enroll user and set identity with returned CA credentials
//			└── 2.1a) Add user account to User ledger -return successful
func (mgr *ClientManager) LoginHandler(username string, password string) error {

	// Query the User ledger for the passed username
	// Response will be the stored password hash (bcrypt)
	passHash, err := mgr.UserQuery(username)
	if err != nil {
		return fmt.Errorf("LoginHandler - Failed to query the User ledger: %v", err)
	}

	// 1.0) If the response is not blank, the user exists - compare the password hash
	if passHash != "" {
		// 1.2) If the password hashes match, try to find the stored CA identity
		if checkPasswordHash(password, passHash) {
			// Set the ClientManager parameters for the logged in user
			mgr.SetClient(ChaincodeUser, ChannelID, Org, username)
			// Initialize the client object
			err = mgr.Client()
			// 1.2b) If the identity is not found, re-enroll the user (not currently enrolled on this client)
			if err != nil {
				// Re-enroll the user on this client
				err = mgr.Reenroll(username)
				if err != nil {
					// 1.2bE) BUG: If re-enrollment fails, the user might never have been Registered (might be a bug)
					// Try to Register and Enroll with the CA
					err = registerAndEnrollUser(mgr, username)
					if err != nil {
						return fmt.Errorf("LoginHandler - Reenrollment and Registration/Enrollment failed: %v", err)
					}
				}

				// Re-enroll success - Initialize the client object
				err = mgr.Client()
				if err != nil {
					return fmt.Errorf("LoginHandler - Failed to create Client object (2.1): %v", err)
				}
			}
			// 1.2a) success - drop to return
		} else {
			// 1.1) The password hashes do not match - return an error to the user
			return fmt.Errorf("LoginHandler - Incorrect login information: %v", err)
		}
	} else {
		// 2.0 & 2.1) The user must not exist in the User ledger - Register and Enroll the user
		err = registerAndEnrollUser(mgr, username)
		if err != nil {
			// 2.0E) BUG: Registration/Enrollment failed, so maybe the user already exists in the CA
			// Re-enroll the user on this client
			err = mgr.Reenroll(username)
			if err != nil {
				return fmt.Errorf("LoginHandler - Registration/Enrollment and Reenrollment failed: %v", err)
			}
			// success - continue below to Initialize the client object
		}

		// 2.1a) The new user was added to the CA, now add the user to the User ledger
		// Use the user's desired password hashed with bcrypt
		passHash, err = hashPassword(password)
		if err != nil {
			return fmt.Errorf("LoginHandler - Failed to hash password: %v", err)
		}
		_, err := mgr.AddUser(username, passHash)
		if err != nil {
			return fmt.Errorf("LoginHandler - Failed to add user to the User ledger: %v", err)
		}

		// Set the ClientManager parameters for the logged in user
		mgr.SetClient(ChaincodeUser, ChannelID, Org, username)
		// Initialize the client object
		err = mgr.Client()
		if err != nil {
			return fmt.Errorf("LoginHandler - Failed to create Client object (2.1): %v", err)
		}
	}

	// success - return
	return nil
}

// ************************** Query Functions **************************

// UserQuery queries the User ledger for a specific user
func (mgr *ClientManager) UserQuery(username string) (string, error) {

	// Prepare arguments
	var args []string
	args = append(args, "query")
	args = append(args, username)

	response, err := mgr.client.Query(channel.Request{ChaincodeID: ChaincodeUser, Fcn: args[0], Args: [][]byte{[]byte(args[1])}})
	if err != nil {
		return "", fmt.Errorf("failed to query: %v", err)
	}

	// If the response payload bytes are nil, just return a blank string
	responseString := ""
	if response.Payload != nil {
		responseString = string(response.Payload)
	}

	return responseString, nil
}

// ************************* Invoke Functions **************************

// AddUser creates a new User ledger entry for a new user
func (mgr *ClientManager) AddUser(username string, passHash string) (string, error) {
	// Prepare arguments
	var args []string
	args = append(args, "create")
	args = append(args, username)
	args = append(args, passHash)

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
		return "", fmt.Errorf("AddUser - failed to create Event object: %v", err)
	}

	// reg, notifier, err := mgr.event.RegisterChaincodeEvent(ccUser, eventID)
	reg, _, err := mgr.client.RegisterChaincodeEvent(ChaincodeUser, eventID)
	if err != nil {
		return "", err
	}
	// defer mgr.event.Unregister(reg)
	defer mgr.client.UnregisterChaincodeEvent(reg)

	// Create a request (proposal) and send it
	response, err := mgr.client.Execute(channel.Request{ChaincodeID: ChaincodeUser, Fcn: args[0], Args: [][]byte{[]byte(args[1]), []byte(args[2])}, TransientMap: transientDataMap})
	if err != nil {
		return "", fmt.Errorf("AddUser - failed to add user: %v", err)
	}

	// The user was successfully created, so create a wallet account for the user
	// In order to make this example as modular as possible, we will not return the
	// new user's Wallet in the response (otherwise chaincode functions become interdependent)
	_, err = mgr.Create(username)
	if err != nil {
		return "", fmt.Errorf("AddUser - failed to create user wallet: %v", err)
	}

	// TODO: DEBUG WHY NOTIFIER NEVER RESPONDS
	// // Wait for the result of the submission
	// select {
	// case ccEvent := <-notifier:
	// 	fmt.Printf("Received CC event: %v\n", ccEvent)
	// case <-time.After(time.Second * 20):
	// 	return "", fmt.Errorf("did NOT receive CC event for eventId(%s)", eventID)
	// }

	return string(response.TransactionID), nil
}

func registerAndEnrollUser(mgr *ClientManager, username string) error {
	// Register the user with the CA
	tmpPassword, err := mgr.Register(username)
	if err != nil {
		return fmt.Errorf("RegisterAndEnrollUser - Failed to Register User: %v", err)
	} else if tmpPassword != "" {
		// The Registration succeeded and returned an enrollment password
		// Enroll the user with the CA to get CA credentials
		err := mgr.Enroll(username, tmpPassword)
		if err != nil {
			return fmt.Errorf("RegisterAndEnrollUser - Failed to Enroll User: %v", err)
		}
	}
	return nil
}

func hashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	return string(bytes), err
}

func checkPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}
