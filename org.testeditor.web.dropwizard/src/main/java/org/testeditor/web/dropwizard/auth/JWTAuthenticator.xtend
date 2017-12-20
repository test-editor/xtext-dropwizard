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
		return token.map[extractUser]
	}

	private def Optional<String> extractToken(String header) {
		if (header.startsWith(HEADER_PREFIX)) {
			return Optional.of(header.substring(HEADER_PREFIX.length))
		}
		return Optional.empty
	}

	private def User extractUser(String token) throws AuthenticationException {
		try {
			val jwt = JWT.decode(token)
			return createUser(jwt)
		} catch (Exception e) {
			throw new AuthenticationException("Invalid authorization header.", e)
		}
	}
	
	private def User createUser(DecodedJWT jwt) {
		val id = jwt.getClaim('id').asString
		val name = jwt.getClaim('name').asString
		val email = jwt.getClaim('email').asString
		return new User(id, name, email)
	}

}
