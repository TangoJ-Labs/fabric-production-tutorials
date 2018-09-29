// App is the root parent object
class App extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            wallets: [],
            loggedin: false,
            username: '', //The currently logged in user
        };

        this.updateLoggedIn = this.updateLoggedIn.bind(this);
        this.updateUsername = this.updateUsername.bind(this);
        this.updateSomeWallets = this.updateSomeWallets.bind(this);
        this.query = this.query.bind(this);
    }

    // Pass these functions to child objects to request state update
    updateLoggedIn(loggedIn) {
        this.setState({
            loggedin: loggedIn
        }, () => 
        console.log("login update: " + this.state.loggedin)
        );

        // If the user logged out, clear the local storage
        if (loggedIn == false) {
            localStorage.clear();
            sessionStorage.clear();
        }
    }
    updateUsername(username) {
        this.setState({
            username: username
        });
    }
    updateSomeWallets(wallets) {
        // Only some updated wallets were sent.
        // Find the OTHER wallets currently in the state array and add to a new array
        var newWallets = wallets;
        var addWallet = true;
        for (var s = 0; s < this.state.wallets.length; s++) {
            // Reset the matched wallet flag
            addWallet = true;
            for (var w = 0; w < wallets.length; w++) {
                if (wallets[w]["owner"] == this.state.wallets[s]["owner"]) {
                    // A new version of this wallet was sent, so do not add the old version
                    addWallet = false;
                    break;
                }
            }
            // If a new version was not found, add the existing version to the new array
            if (addWallet) {
                newWallets.push(this.state.wallets[s]);
            }
        }

        // The new array of wallets has been created - replace the old list with the new one
        this.setState({
            wallets: newWallets
        });
    }

    // Session communicates with client to exchange session information
    getSession = () => {

        var session = $.get(
            "http://localhost:3001/session",{},
            res => {}
        );
        session.fail((xhr, status, error) => {
            console.log("ERROR GETTING SESSION");
        });
        session.done((data, textStatus, jqXHR) => {
            // Get the "user" response header to determine if the session pre-exists
            var user = data.user;
            // If the user is empty, this is a new session & the user needs to log in
            // Otherwise, set the username and bypass the login screen
            if (user != "") {
                this.updateUsername(user);
                this.updateLoggedIn(true);
                this.query();
            }
        });
    }

    // Query the ledger via the gin-gonic SDK client REST API
    query = () => {
        var query = $.get("http://localhost:3001/api/query", res => {

            this.setState({
                wallets: res
            });
        });
        query.fail((xhr, status, error) => {
            console.log("QUERY ERROR");
            // If the error is 401 (unauthorized), show the login object to re-authenticate
            if (xhr.status == 401) {
                this.updateLoggedIn(false);
            } else {
                alert("There was an issue requesting data from the server.  Please reload the page.");
            }
        });
    }

    componentDidMount() {
        // this.query();
        this.getSession();
    }

    render() {
        return (
            // All html in this example app uses the boostrap CSS (see index.html)
            <div>
                <nav class="navbar navbar-fixed-top">
                    <div class="alert alert-warning" style={{ "width":"100%", "text-align":"center" }}>Please Note: This Website Requires Cookies</div>
                </nav>
                <div class="container" style={{ "min-width":"200px", "max-width":"500px" }}>
                    
                    <h5 style={{ "margin-top":"20px", "text-align":"center" }}>TangoJLabs Hyperledger Fabric Go SDK Example</h5>
                    <Logout username={this.state.username} wallets={this.state.wallets} loggedin={this.state.loggedin} updateLoggedIn={this.updateLoggedIn} updateUsername={this.updateUsername}/>
                    <Login query={this.query} loggedin={this.state.loggedin} updateLoggedIn={this.updateLoggedIn} updateUsername={this.updateUsername}/>
                    <div class="card" style={{ "margin-top":"10px", "margin-bottom":"10px", display: this.state.loggedin ? "block":"none" }}>
                        <div class="card-body">
                            <WalletBalance username={this.state.username} wallets={this.state.wallets} />
                            <WalletDeposit updateSomeWallets={this.updateSomeWallets} />
                            <WalletTransfer username={this.state.username} wallets={this.state.wallets} updateSomeWallets={this.updateSomeWallets} />
                        </div>
                    </div>
                </div>
            </div>
        );
    }
}

// Login displays the wallet balances for all loaded wallets
class Login extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            username: '',
            password: '',
            waiting: false,
        };

        this.login = this.login.bind(this);
        this.query = this.query.bind(this);
        this.handleChange = this.handleChange.bind(this);
        this.handleSubmit = this.handleSubmit.bind(this);
    }

    updateLoggedIn(loggedIn) {
        this.props.updateLoggedIn(loggedIn);
    }
    updateUsername(username) {
        this.props.updateUsername(username);
    }

    query() {
        this.props.query();
    }

    // Send the login info to the client
    login = () => {
        // Show the "Login" spinner
        this.setState({
            waiting: true
        });
        var login = $.post(
            "http://localhost:3001/login",
            {
                username: this.state.username,
                password: this.state.password,
            },
            res => {
                // Save the logged in data to the App object
                this.updateLoggedIn(true);
                this.updateUsername(this.state.username);

                // Reset the form and hide the "Transfer" spinner
                this.setState({
                    username: '',
                    password: '',
                    waiting: false,
                });

                // Query account balances
                this.query();
            }
        );
        login.fail((xhr, status, error) => {
            alert("There was an issue logging you in.  Please try again.");

            // Reset the form and hide the "Transfer" spinner
            this.setState({
                username: '',
                password: '',
                waiting: false,
            });
        });
    }

    handleChange(event) {
        this.setState({
            [event.target.name]: event.target.value
        });
    }

    handleSubmit(event) {
        // Ensure the login values are not null
        if (this.state.username != '' && this.state.password != '') {
            this.login()
        }
        event.preventDefault();
        event.target.reset();
    }

    render() {
        return (
            <div class="card" style={{ "margin-top":"10px", "margin-bottom":"10px", display: this.props.loggedin ? "none":"block" }}>
                <div class="card-body">
                    <h5 class="card-title">Log In:</h5>
                    <form class="form-group" onSubmit={this.handleSubmit.bind(this)}>
                        <div style={{ "margin-bottom":"5px" }}>Go ahead, just type. New accounts are automatically created.</div>
                        <div style={{ "margin-bottom":"30px", "font-size":"11px" }}>(Note: Don't log in with a user created with the CLI - wallets are not automatically created when logging in via the CLI.)</div>
                        <h6>Username (case-sensitive):</h6>
                        <input name="username" type="text" class="form-control" onChange={this.handleChange} />
                        <h6>Password:</h6>
                        <input name="password" type="password" class="form-control" onChange={this.handleChange} />
                        <br></br>
                        <input type="submit" value="Log In" class="btn btn-secondary" />
                        <span class="fa fa-cog fa-spin fa-2x fa-fw" style={{ visibility: this.state.waiting ? "visible":"hidden" }}></span>
                    </form>
                </div>
            </div>
        );
    }
}

// Logout displays a small card with a logout button
class Logout extends React.Component {
    constructor(props) {
        super(props);

        this.logout = this.logout.bind(this)
    }

    updateLoggedIn(loggedIn) {
        this.props.updateLoggedIn(loggedIn);
    }
    updateUsername(username) {
        this.props.updateUsername(username);
    }

    logout() {
        this.updateLoggedIn(false);
        this.updateUsername('');

        // Notify the client to reset the user
        $.get(
            "http://localhost:3001/logout",{},
            res => {}
        );
    }

    // Wallet data comes from the parent object, so update data when parent state updates
    componentWillReceiveProps(nextProps) {
        this.setState({
            wallets: nextProps.wallets
        });  
    }

    render() {
        // Find the current user's wallet and display the balance
        var userBalance = 0.0;
        this.props.wallets.map(function(wallet, i) {
            if (wallet["owner"] == this.props.username) {
                userBalance = wallet["balance"]
            }
        }, this);

        return (
            <div class="card" style={{ "margin-top":"10px", "margin-bottom":"10px", "height":"80px", display: this.props.loggedin ? "block":"none" }}>
                <div class="card-body">
                    <h5 style={{ "float":"left", "margin-top":"5px" }}>{this.props.username}: {userBalance.toLocaleString()}</h5>
                    <div class="btn btn-secondary" onClick={this.logout} style={{ "float":"right" }}>Log Out</div>
                </div>
            </div>
        );
    }
}

// WalletBalance displays the wallet balances for all loaded wallets
class WalletBalance extends React.Component {
    constructor(props) {
        super(props);
    }

    // Wallet data comes from the parent object, so update data when parent state updates
    componentWillReceiveProps(nextProps) {
        this.setState({
            wallets: nextProps.wallets
        });  
    }

    render() {
        // Create a temporary array to sort the wallet accounts alphabetically
        var tempWallets = this.props.wallets;
        tempWallets.sort(function(a, b) {
            return ('' + a.owner.toLowerCase()).localeCompare(b.owner.toLowerCase());
        });

        return (
            <div class="container">
                <h5>Other Wallets:</h5>
                {tempWallets.map(function(wallet, i) {
                    if (wallet["owner"] != this.props.username) {
                        return <div>{wallet["owner"]}: {wallet["balance"].toLocaleString()}</div>;
                    }
                }, this)}
            </div>
        );
    }
}

// WalletDeposit allows users to deposit to the currently logged in account
class WalletDeposit extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            amount: 0.0,
            waiting: false,
        };

        this.deposit = this.deposit.bind(this);
        this.handleChange = this.handleChange.bind(this);
        this.handleSubmit = this.handleSubmit.bind(this);
    }

    // Deposit a specific amount into the logged in user's wallet using the gin-gonic SDK client REST API
    deposit = () => {
        // Show the "Transfer" spinner
        this.setState({
            waiting: true
        });
        var deposit = $.post(
            "http://localhost:3001/api/deposit",
            {
                amount: this.state.amount
            },
            res => {
                // Request the parent update its state since the updated balances were downloaded
                this.props.updateSomeWallets([res]);
                
                // Reset the form and hide the "Transfer" spinner
                this.setState({
                    amount: 0.0,
                    waiting: false,
                });
            }
        );
        deposit.fail((xhr, status, error) => {
            console.log("DEPOSIT ERROR");
            // If the error is 401 (unauthorized), show the login object to re-authenticate
            if (xhr.status == 401) {
                this.updateLoggedIn(false);
            } else {
                alert("There was an issue with your request.  Please check your selection and try again.");
            }
            // Reset the form and hide the "Transfer" spinner
            this.setState({
                amount: 0.0,
                waiting: false,
            });
        });
    }

    handleChange(event) {
        this.setState({
            [event.target.name]: event.target.value
        });
    }

    handleSubmit(event) {
        // Ensure the transfer amount is greater than zero and no greater than 1000
        // This will also be checked on the backend
        var reset = false;
        if (this.state.amount > 0 && this.state.amount <= 1000) {
            this.deposit()
        } else if (this.state.amount > 1000) {
            reset = true;
            alert("I'm sorry, the deposit maximum is 1000.");
        } else {
            reset = true;
            alert("I'm sorry, the deposit amount must be greater than zero.");
        }
        event.preventDefault();
        event.target.reset();

        if (reset) {
            // Reset the form and hide the "Transfer" spinner
            this.setState({
                amount: 0.0,
                waiting: false,
            });
        }
    }

    render() {
        return (
            <div class="container" style={{ "margin-top":"50px" }}>
                <form class="form-group" onSubmit={this.handleSubmit.bind(this)}>
                    <h5>Deposit:</h5>
                    <h6>AMOUNT:</h6>
                    <input name="amount" type="number" step={0.1} class="form-control" onChange={this.handleChange} />
                    <br></br>
                    <input type="submit" value="Deposit" class="btn btn-primary" />
                    <span class="fa fa-cog fa-spin fa-2x fa-fw" style={{visibility: this.state.waiting ? "visible":"hidden" }}></span>
                </form>
            </div>
        );
    }
}

// WalletTransfer requests a transfer of a specific amount between wallets
class WalletTransfer extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            to: '',
            amount: 0.0,
            waiting: false,
        };

        this.transfer = this.transfer.bind(this);
        this.handleChange = this.handleChange.bind(this);
        this.handleSubmit = this.handleSubmit.bind(this);
    }

    // Transfer a specific amount between wallets using the gin-gonic SDK client REST API
    transfer = () => {
        // Show the "Transfer" spinner
        this.setState({
            waiting: true
        });
        var transfer = $.post(
            "http://localhost:3001/api/transfer",
            {
                to: this.state.to,
                amount: this.state.amount
            },
            res => {
                // Request the parent update its state since the updated balances were downloaded
                this.props.updateSomeWallets(res);
                
                // Reset the form and hide the "Transfer" spinner
                this.setState({
                    to: '',
                    amount: 0.0,
                    waiting: false,
                });
            }
        );
        transfer.fail((xhr, status, error) => {
            console.log("TRANSFER ERROR");
            // If the error is 401 (unauthorized), show the login object to re-authenticate
            if (xhr.status == 401) {
                this.updateLoggedIn(false);
            } else {
                alert("There was an issue with your request.  Please check your selection and try again.");
            }
            // Reset the form and hide the "Transfer" spinner
            this.setState({
                to: '',
                amount: 0.0,
                waiting: false,
            });
        });
    }

    handleChange(event) {
        this.setState({
            [event.target.name]: event.target.value
        });
    }

    handleSubmit(event) {
        // Ensure the transfer values are not empty
        var reset = false;
        if (this.state.to != '' && this.state.amount != 0) {
            // Ensure the transfer amount is greater than zero
            // This will also be checked on the backend
            if (this.state.amount > 0) {
                this.transfer()
            } else {
                reset = true;
                alert("I'm sorry, the transfer amount must be greater than zero.");
            }
        } else {
            reset = true;
            alert("Please enter the amount you would like to transfer.");
        }
        event.preventDefault();
        event.target.reset();

        if (reset) {
            // Reset the form and hide the "Transfer" spinner
            this.setState({
                to: '',
                amount: 0.0,
                waiting: false,
            });
        }
    }

    render() {
        return (
            <div class="container" style={{ "margin-top":"50px" }}>
                <form class="form-group" onSubmit={this.handleSubmit.bind(this)}>
                    <h5>Transfer:</h5>
                    <h6>TO:</h6>
                    <select name="to" type="text" class="form-control" onChange={this.handleChange}>
                        <option></option>
                        {this.props.wallets.map(function(wallet, i) {
                            // Do not add the currently logged in user as an option for credit transfer
                            if (wallet["owner"] != this.props.username) {
                                return <option value={wallet["owner"]}>{wallet["owner"]}</option>;
                            }
                        }, this)}
                    </select>
                    <h6>AMOUNT:</h6>
                    <input name="amount" type="number" step={0.1} class="form-control" onChange={this.handleChange} />
                    <br></br>
                    <input type="submit" value="Transfer" class="btn btn-primary" />
                    <span class="fa fa-cog fa-spin fa-2x fa-fw" style={{visibility: this.state.waiting ? "visible":"hidden" }}></span>
                </form>
            </div>
        );
    }
}

ReactDOM.render(<App />, document.getElementById("app"));