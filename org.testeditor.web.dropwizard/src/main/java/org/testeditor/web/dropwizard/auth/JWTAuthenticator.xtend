package org.testeditor.web.dropwizard.auth

import com.auth0.jwt.JWT
import com.auth0.jwt.interfaces.DecodedJWT
import io.dropwizard.auth.AuthenticationException
import io.dropwizard.auth.Authenticator
import java.util.Optional

class JWTAuthenticator implements Authenticator<String, User> {

	static val HEADER_PREFIX = "Bearer "

	override authenticate(String authHeader) throws AuthenticationException {
		val token = extractToken(authHeader)
		val jwt = JWT.decode(token)
		val user = createUser(jwt)
		return Optional.of(user)
	}

	private def String extractToken(String header) throws AuthenticationException {
		if (header.startsWith(HEADER_PREFIX)) {
			return header.substring(HEADER_PREFIX.length)
		} else {
			throw new AuthenticationException("Invalid authorization header.")
		}
	}

	private def User createUser(DecodedJWT jwt) {
		val id = jwt.getClaim('id').asString
		val name = jwt.getClaim('name').asString
		val email = jwt.getClaim('email').asString
		return new User(id, name, email)
	}

}
