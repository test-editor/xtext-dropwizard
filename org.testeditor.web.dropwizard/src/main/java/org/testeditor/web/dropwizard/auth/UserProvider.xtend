package org.testeditor.web.dropwizard.auth

import javax.inject.Inject
import javax.inject.Provider
import javax.servlet.http.HttpServletRequest

import static javax.ws.rs.core.HttpHeaders.AUTHORIZATION

class UserProvider implements Provider<User> {

    @Inject
    Provider<HttpServletRequest> requestProvider

    @Inject
    JWTAuthenticator authenticator

    override get() {
        // Cannot access the Jersey context through Guice, so we'll extract the User ourselves
        val request = requestProvider.get
        val authHeader = request.getHeader(AUTHORIZATION)
        val user = authenticator.authenticate(authHeader)
        return user.get
    }

}
