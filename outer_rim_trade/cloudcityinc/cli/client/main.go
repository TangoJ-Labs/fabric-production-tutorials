// --------------------------
// Copyright TangoJ Labs, LLC
// Apache 2.0 License
// --------------------------

package main

import (
	"fmt"
	"os"

	"./app"
	localsdk "./sdk"
	"github.com/hyperledger/fabric-sdk-go/pkg/core/config"
)

func main() {

	// debug.PrintStack()

	// Create a ClientManager and load the config file
	// Warning: User login must occur before utilizing any client functions
	mgr := localsdk.ClientManager{}
	mgr.ConfigProvider = config.FromFile(localsdk.ConfigFile)

	// Initialize the FabricSDK
	err := mgr.Initialize()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	// The ClientManager will not close until the app Service
	// is stopped (stops listening on the port)
	defer mgr.Close()

	// Initialize the channel client - use the ChaincodeUser
	// ledger initially, to access the User login abilities
	mgr.SetClient(localsdk.ChaincodeUser, localsdk.ChannelID, localsdk.Org, "cloudcityinc-sdk")
	err = mgr.Client()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// Initialize the msp client
	err = mgr.MSP()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// Launch the web application (will listen)
	application := &app.Application{
		Mgr: &mgr,
	}
	app.Serve(application)
}
