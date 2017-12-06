package org.testeditor.web.dropwizard.auth

import io.dropwizard.auth.AuthFilter
import java.io.IOException
import javax.annotation.Priority
import javax.inject.Inject
import javax.ws.rs.Priorities
import javax.ws.rs.WebApplicationException
import javax.ws.rs.container.ContainerRequestContext
import javax.ws.rs.core.SecurityContext

@Priority(Priorities.AUTHENTICATION)
class ApiTokenAuthFilter extends AuthFilter<String, User> {
	
	public static val API_TOKEN_QUERY_PARAM = 'apiToken'

	override filter(ContainerRequestContext requestContext) throws IOException {
		val queryParams = requestContext.uriInfo.queryParameters
		val authorization = queryParams.getFirst(API_TOKEN_QUERY_PARAM)
		if (!authenticate(requestContext, authorization, SecurityContext.DIGEST_AUTH)) {
			throw new WebApplicationException(unauthorizedHandler.buildResponse(prefix, realm))
		}
	}

	static class Builder extends AuthFilterBuilder<String, User, ApiTokenAuthFilter> {
		
		ApiTokenAuthenticator authenticator // authenticator in parent class is private

		@Inject
		new(ApiTokenAuthenticator authenticator) {
			this.authenticator = authenticator // keep for later configuration of api token
			setAuthenticator(authenticator)
		}

		override protected ApiTokenAuthFilter newInstance() {
			return new ApiTokenAuthFilter
		}

		def Builder withApiToken(String apiToken) {
			authenticator.apiToken = apiToken
			return this
		}

	}
	

}
