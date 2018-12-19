let
    source = AccelaConnector.Feed("https://apis.accela.com/v4/records"),
    client_id = "",
    client_secret = "",
    redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html",
    token_uri = "https://auth.accela.com/oauth2/token",
    authorize_uri = "https://auth.accela.com/oauth2/authorize",
    grantType = "authorization_code",
    logout_uri = "https://av3.accela.com",
    scope_prefix = "https://apis.accela.com/v4/",
    scopes = {
        "records",
        "addresses",
        "parcels",
        "owners",
        "professionals",
        "inspections",
        "workflows"
    },

    Value.IfNull = (a, b) => if a <> null then a else b,

    GetScopeString = (scopes as list, optional scopePrefix as text) as text =>
        let
            prefix = Value.IfNull(scopePrefix, ""),
            addPrefix = List.Transform(scopes, each prefix & _),
            asText = Text.Combine(addPrefix, " ")
        in
            asText
in
    source