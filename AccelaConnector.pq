// This file contains your Data Connector logic
section AccelaConnector;

[DataSource.Kind="AccelaConnector", Publish="AccelaConnector.UI"]
shared AccelaConnector.Feed = Value.ReplaceType(AccelaConnector.Feed, type function (url as Uri.Type) as any);

    client_id = "";
    client_secret = "";
    redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html";
    token_uri = "https://auth.accela.com/oauth2/token";
    authorize_uri = "https://auth.accela.com/oauth2/authorize";
    grantType = "authorization_code";
    logout_uri = "https://av3.accela.com";

    scope_prefix = "https://apis.accela.com/v4/";
    scopes = {
        "records",
        "addresses",
        "parcels",
        "owners",
        "professionals",
        "inspections",
        "workflows"
    };

    Value.IfNull = (a, b) => if a <> null then a else b;

    GetScopeString = (scopes as list, optional scopePrefix as text) as text =>
        let
            prefix = Value.IfNull(scopePrefix, ""),
            addPrefix = List.Transform(scopes, each prefix & _),
            asText = Text.Combine(addPrefix, " ")
        in
            asText;


StartLogin = (resourceUrl, state, display) as record;

StartLogin = (resourceUrl, state, display) =>
    let
        uthorizeUrl = authorize_uri & "?" & Uri.BuildQueryString([
            client_id = client_id,  
            redirect_uri = redirect_uri,      
            scope = GetScopeString(scopes),
            response_type = "code",
            environment= "TEST",
            agency_name= "",
            state = ""
        ])
    in
        [
            LoginUri = authorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = 720,
            WindowWidth = 1024,
            Context = null
        ];

FinishLogin = (context, callbackUri, state) as record

FinishLogin = (context, callbackUri, state) =>
    let
        parts = Uri.Parts(callbackUri)[Query],
        result = if (Record.HasFields(parts, {"error", "error_description"})) then 
                    error Error.Record(parts[error], parts[error_description], parts)
                 else
                    TokenMethod("authorization_code", "code", parts[code])
    in
        result;

TokenMethod = (grantType, tokenField, code) =>
    let
        queryString = [
            client_id = client_id,
            client_secret = client_secret,
            scope = GetScopeString(scopes),
            grant_type = grantType,
            redirect_uri = redirect_uri
        ],
        queryWithCode = Record.AddField(queryString, tokenField, code),

        tokenResponse = Web.Contents(token_uri, [
            Content = Text.ToBinary(Uri.BuildQueryString(queryWithCode)),
            Headers = [
                #"Content-type" = "application/x-www-form-urlencoded",
                #"Accept" = "application/json"
                #"x-accela-appid" = client_id
            ],
            ManualStatusHandling = {400} 
        ]),
        body = Json.Document(tokenResponse),
        result = if (Record.HasFields(body, {"error", "error_description"})) then 
                    error Error.Record(body[error], body[error_description], body)
                 else
                    body
    in
        result;

Refresh = (resourceUrl, refresh_token) => TokenMethod("refresh_token", "refresh_token", refresh_token);

Logout = (token) => logout_uri;

AccelaConnector = [
    Authentication = [
        OAuth = [
            StartLogin=StartLogin,
            FinishLogin=FinishLogin,
            Refresh=Refresh,
            Logout=Logout
        ]
    ],
    Label = "Accela"
];

AccelaConnector.UI = [
    Beta = true,
    ButtonText = {"AccelaConnector.Feed", "Connect to Accela"},
    SourceImage = AccelaConnector.Icons,
    SourceTypeImage = AccelaConnector.Icons
];

AccelaConnector.Icons = [
    Icon16 = { Extension.Contents("AccelaConnector16.png"), Extension.Contents("AccelaConnector20.png"), Extension.Contents("AccelaConnector24.png"), Extension.Contents("AccelaConnector32.png") },
    Icon32 = { Extension.Contents("AccelaConnector32.png"), Extension.Contents("AccelaConnector40.png"), Extension.Contents("AccelaConnector48.png"), Extension.Contents("AccelaConnector64.png") }
];
