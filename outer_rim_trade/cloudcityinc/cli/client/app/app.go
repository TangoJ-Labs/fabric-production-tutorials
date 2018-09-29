// --------------------------
// Copyright TangoJ Labs, LLC
// Apache 2.0 License
// --------------------------

package app

import (
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/gin-contrib/sessions"
	"github.com/gin-contrib/sessions/cookie"
	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"

	localsdk "../sdk"
)

// Application is used to host the client interface
type Application struct {
	Mgr *localsdk.ClientManager
}

// Login json binds login attempt details
type Login struct {
	Username string `json:"username" form:"username" binding:"required"`
	Password string `json:"password" form:"password" binding:"required"`
}

// Serve loads the needed pages and listens on port
func Serve(app *Application) {

	// Set the router as the default one shipped with Gin
	router := gin.Default()
	//-v-v-v-v-v- SESSION -v-v-v-v-v-
	cookie := cookie.NewStore([]byte(os.Getenv("SESSION_KEY")))
	cookie.Options(sessions.Options{
		Path:     "/",
		Secure:   false,
		HttpOnly: true,
	})
	router.Use(sessions.Sessions("mysession", cookie))
	//-^-^-^-^-^- SESSION -^-^-^-^-^-

	router.NoRoute(func(c *gin.Context) {
		c.JSON(404, gin.H{"code": "PAGE_NOT_FOUND", "message": "Page not found - contact admin@tangojlabs.com"})
	})

	// Serve frontend static files
	router.Use(static.Serve("/", static.LocalFile("./app/assets", true)))

	// The login/logout do not need authorization (API requests below need authorization)
	root := router.Group("/")
	root.GET("/session", app.Session)
	root.POST("/login", app.Login)
	root.GET("/logout", app.Logout)

	// Setup route group for the API requests
	api := router.Group("/api")
	api.Use(AuthRequired())
	api.GET("/query", app.Query)
	api.POST("/deposit", app.Deposit)
	api.POST("/transfer", app.Transfer)

	// Start and run the server
	router.Run(":3001")
}

//-v-v-v-v-v- SESSION -v-v-v-v-v-

// AuthRequired returns a function with the session context
func AuthRequired() gin.HandlerFunc {
	return func(c *gin.Context) {
		session := sessions.Default(c)
		user := session.Get("user")
		if user == nil {
			// Pass an unauthorized error and the app will display the login
			// object to allow the user to re-authenticate
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid session token"})
		} else {
			// Continue down the chain to handler etc
			c.Next()
		}
	}
}

// Session checks for a user session and sets the client identity if the user is verified
func (app *Application) Session(c *gin.Context) {
	session := sessions.Default(c)

	// In a production environment, the username should not be used to
	// set the client identity - the browser cookie could be manipulated.
	// In production, pass a key pair to the cookie in the browser and when
	// the page is requested, verify the key in the session, the use the key
	// to look up the appropriate user via a secure database connected to the app backend.
	user := session.Get("user")
	if user == nil {
		// The request was successful, but this is a new user session
		// Do not set the client identity - wait for the user to use
		// the login feature to set the client (app) identity
		c.JSON(http.StatusOK, gin.H{"user": ""})
	} else {
		// The session is still valid - set the client identity
		// In production, you would use the passed key to look up
		// a user via a secure database with user/session key

		// Convert to string
		username := fmt.Sprintf("%v", user)
		app.Mgr.SetClient(localsdk.ChaincodeUser, localsdk.ChannelID, localsdk.Org, username)

		c.Header("Content-Type", "application/json")
		c.JSON(http.StatusOK, gin.H{"user": username})
	}
}

//-^-^-^-^-^- SESSION -^-^-^-^-^-

// Login processes a new login request and registers / enrolls a user with the CA if needed
func (app *Application) Login(c *gin.Context) {

	json := Login{
		Username: c.PostForm("username"),
		Password: c.PostForm("password"),
	}

	// Ensure the login credentials are not blank
	if strings.Trim(json.Username, " ") == "" || strings.Trim(json.Password, " ") == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "please fill in both username and password boxes"})
		return
	}

	err := app.Mgr.LoginHandler(json.Username, json.Password)
	if err != nil {
		fmt.Println(err)
		c.JSON(http.StatusUnauthorized, gin.H{"status": "unauthorized"})
		return
	}

	//-v-v-v-v-v- SESSION -v-v-v-v-v-
	// The user logged in successfully, so set the session user to the passed username
	session := sessions.Default(c)
	session.Set("user", json.Username)
	err = session.Save()
	if err != nil {
		fmt.Println(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate session token"})
	}
	//-^-^-^-^-^- SESSION -^-^-^-^-^-

	c.JSON(http.StatusOK, gin.H{"status": "login success"})
}

// Logout replaces the current user with an empty string to prevent accidental
// unauthorized access if an error occurs during a subsequent login attempt
func (app *Application) Logout(c *gin.Context) {
	app.Mgr.SetClient(localsdk.ChaincodeUser, localsdk.ChannelID, localsdk.Org, "")

	//-v-v-v-v-v- SESSION -v-v-v-v-v-
	// Clear the session data
	session := sessions.Default(c)
	session.Clear()
	session.Save()
	//-^-^-^-^-^- SESSION -^-^-^-^-^-
	fmt.Println("LOGGED OUT")
}

// *************** API FUNCTIONS ***************

// Query retrieves a list of wallets
func (app *Application) Query(c *gin.Context) {

	wallets, err := app.Mgr.WalletQueryAll()
	if err != nil {
		c.Header("Content-Type", "application/json")
		c.JSON(http.StatusBadRequest, err)
	} else {
		c.Header("Content-Type", "application/json")
		c.JSON(http.StatusOK, wallets)
	}
}

// Deposit adds credits to an account
func (app *Application) Deposit(c *gin.Context) {

	// Ensure that the amount being deposited is greater than zero and no greater than 1000
	amount, err := strconv.ParseFloat(c.PostForm("amount"), 64)
	if err != nil {
		fmt.Println(err)
		c.JSON(http.StatusBadRequest, err)
	}
	if amount > 0.0 && amount <= 1000.0 {
		// Invoke the deposit
		wallet, err := app.Mgr.Deposit(c.PostForm("amount"))
		if err != nil {
			c.Header("Content-Type", "application/json")
			c.JSON(http.StatusBadRequest, err)
		} else {
			c.Header("Content-Type", "application/json")
			c.JSON(http.StatusOK, wallet)
		}

	} else {
		c.Header("Content-Type", "application/json")
		c.JSON(http.StatusBadRequest, err)
	}

}

// Transfer moves credits from one account to another
func (app *Application) Transfer(c *gin.Context) {

	// Ensure that the amount being transferred is greater than zero
	amount, err := strconv.ParseFloat(c.PostForm("amount"), 64)
	if err != nil {
		fmt.Println(err)
		c.JSON(http.StatusBadRequest, err)
	}
	if amount > 0.0 {
		// Convert the parameters to a map
		// A "from" field is not needed because the outgoing wallet
		// is always the currently logged in user
		paramMap := map[string]string{
			"to":     c.PostForm("to"),
			"amount": c.PostForm("amount"),
		}

		// Invoke the transfer
		wallets, err := app.Mgr.Transfer(paramMap)
		if err != nil {
			c.Header("Content-Type", "application/json")
			c.JSON(http.StatusBadRequest, err)
		} else {
			c.Header("Content-Type", "application/json")
			c.JSON(http.StatusOK, wallets)
		}

	} else {
		c.Header("Content-Type", "application/json")
		c.JSON(http.StatusBadRequest, err)
	}

}
