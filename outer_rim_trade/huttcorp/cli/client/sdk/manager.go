// --------------------------
// Copyright TangoJ Labs, LLC
// Apache 2.0 License
// --------------------------

package sdk

import (
	"fmt"

	"github.com/hyperledger/fabric-sdk-go/pkg/client/channel"
	"github.com/hyperledger/fabric-sdk-go/pkg/client/event"
	"github.com/hyperledger/fabric-sdk-go/pkg/client/msp"
	"github.com/hyperledger/fabric-sdk-go/pkg/client/resmgmt"
	"github.com/hyperledger/fabric-sdk-go/pkg/common/providers/core"
	"github.com/hyperledger/fabric-sdk-go/pkg/fabsdk"
	"github.com/pkg/errors"
)

// ClientManager holds the needed client info to use in sdk actions
type ClientManager struct {
	initialized bool

	ChaincodeID string
	ChannelID   string
	Org         string
	Username    string

	sdk    *fabsdk.FabricSDK
	msp    *msp.Client
	admin  *resmgmt.Client
	client *channel.Client
	event  *event.Client

	ConfigProvider core.ConfigProvider
}

// SetClient ensures the correct parameters are set for network connection
func (mgr *ClientManager) SetClient(chaincodeID string, channelID string, org string, username string) error {

	// If all the arguments are not filled, return an error
	if chaincodeID == "" || channelID == "" || org == "" || username == "" {
		return errors.New("please do not leave any parameters blank")
	}

	mgr.ChaincodeID = chaincodeID
	mgr.ChannelID = channelID
	mgr.Org = org
	mgr.Username = username

	return nil
}

// SetChaincodeWallet changes the manager settings to the Wallet chaincode
func (mgr *ClientManager) SetChaincodeWallet() error {

	mgr.ChaincodeID = ChaincodeWallet
	return nil
}

// SetChaincodeUser changes the manager settings to the User chaincode
func (mgr *ClientManager) SetChaincodeUser() error {

	mgr.ChaincodeID = ChaincodeUser
	return nil
}

// Initialize the SDK with the configuration file
func (mgr *ClientManager) Initialize() error {

	// Ensure the SDK is not already initialized
	if mgr.initialized {
		return errors.New("SDK is already initialized")
	}

	// Initalize a new FABSDK using the config file
	sdk, err := fabsdk.New(mgr.ConfigProvider)
	if err != nil {
		return errors.WithMessage(err, "failed to initialize FABSDK")
	}
	mgr.sdk = sdk

	mgr.initialized = true
	fmt.Println("SDK Initialized")
	return nil
}

// Close closes the sdk (clears caches, etc.)
func (mgr *ClientManager) Close() {
	mgr.sdk.Close()
}

// MSP is used to execute MSP functions (user enrollment, etc.)
func (mgr *ClientManager) MSP() error {
	// msp, err := msp.New(mgr.sdk.Context(fabsdk.WithUser(mgr.OrgAdmin), fabsdk.WithOrg(mgr.OrgName)))
	msp, err := msp.New(mgr.sdk.Context())
	if err != nil {
		return errors.WithMessage(err, "Failed to create CA client")
	}
	mgr.msp = msp

	return nil
}

// Admin creates a resource management client to manage channels (create, update, etc.)
func (mgr *ClientManager) Admin() error {

	// Ensure the admin is not nil (if so, this might not be an admin account)
	if len(mgr.Username) < 1 {
		return errors.New("OrgAdmin was not provided")
	}

	admin, err := resmgmt.New(mgr.sdk.Context(fabsdk.WithUser(mgr.Username), fabsdk.WithOrg(mgr.Org)))
	if err != nil {
		return errors.WithMessage(err, "failed to create channel management client from Admin identity")
	}
	mgr.admin = admin

	return nil
}

// Client is used to query (and invoke, if user has permissions) the chaincode from the client interface
func (mgr *ClientManager) Client() error {

	client, err := channel.New(mgr.sdk.ChannelContext(mgr.ChannelID, fabsdk.WithUser(mgr.Username), fabsdk.WithOrg(mgr.Org)))
	if err != nil {
		return errors.WithMessage(err, "Failed to create new channel client")
	}
	mgr.client = client

	return nil
}

// Event is used to access channel events on the chaincode
func (mgr *ClientManager) Event() error {
	event, err := event.New(mgr.sdk.ChannelContext(mgr.ChannelID, fabsdk.WithUser(mgr.Username), fabsdk.WithOrg(mgr.Org)))
	if err != nil {
		return errors.WithMessage(err, "Failed to create new channel event")
	}
	mgr.event = event

	return nil
}

// Register a new user
func (mgr *ClientManager) Register(username string) (string, error) {

	attributes := []msp.Attribute{}
	// attributes := []msp.Attribute{
	// 	Name: "hf.Registrar.Roles",
	// 	Value: "validator",
	// 	ECert: true,
	// }

	// Register the new user
	enrollmentSecret, err := mgr.msp.Register(&msp.RegistrationRequest{
		Name:        username,
		Type:        "client", //can use "admin", "peer", "client" (see configtx.yaml Policies section)
		Attributes:  attributes,
		Affiliation: mgr.Org,
	})
	if err != nil {
		return "", errors.WithMessage(err, "Registration failed")
	}

	return enrollmentSecret, nil
}

// Enroll is used to get crypto material for a new user
// The user must previously have been registered by the CA admin, or authorized registration admin
func (mgr *ClientManager) Enroll(username string, password string) error { //(mspctx.SigningIdentity, error) {
	err := mgr.msp.Enroll(username, msp.WithSecret(password))
	if err != nil {
		// return nil, errors.WithMessage(err, "Enroll failed")
		return errors.WithMessage(err, "Enroll failed")
	}

	// Set the SDK user as the newly enrolled user
	mgr.Username = username

	return nil
}

// Reenroll is used to get crypto material for an existing user (or new user on this app client)
// The user must previously have been enrolled
func (mgr *ClientManager) Reenroll(username string) error {
	err := mgr.msp.Reenroll(username)
	if err != nil {
		return errors.WithMessage(err, "Reenroll failed")
	}
	return nil
}
