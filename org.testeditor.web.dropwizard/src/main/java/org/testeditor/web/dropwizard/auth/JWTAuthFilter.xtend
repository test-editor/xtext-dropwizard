package org.testeditor.web.dropwizard.auth

import io.dropwizard.auth.AuthFilter
import java.io.IOException
import javax.annotation.Priority
import javax.inject.Inject
import javax.ws.rs.Priorities
import javax.ws.rs.WebApplicationException
import javax.ws.rs.container.ContainerRequestContext
import javax.ws.rs.core.SecurityContext

import static javax.ws.rs.core.HttpHeaders.AUTHORIZATION

@Priority(Priorities.AUTHENTICATION)
class JWTAuthFilter extends AuthFilter<String, User> {

	override filter(ContainerRequestContext requestContext) throws IOException {
		val jwt = requestContext.headers.getFirst(AUTHORIZATION)
		if (!authenticate(requestContext, jwt, SecurityContext.DIGEST_AUTH)) {
			throw new WebApplicationException(unauthorizedHandler.buildResponse(prefix, realm));
		}
	}

	static class Builder extends AuthFilterBuilder<String, User, JWTAuthFilter> {

		@Inject
		new(JWTAuthenticator authenticator) {
			setAuthenticator(authenticator)
		}

		override protected JWTAuthFilter newInstance() {
			return new JWTAuthFilter
		}
	}

}
