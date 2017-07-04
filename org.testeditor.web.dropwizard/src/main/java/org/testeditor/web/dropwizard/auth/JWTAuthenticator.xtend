package org.testeditor.web.dropwizard.auth

import io.dropwizard.auth.AuthenticationException
import io.dropwizard.auth.Authenticator
import io.jsonwebtoken.SignatureException
import java.util.Optional

class JWTAuthenticator implements Authenticator<String, User> {

//	@Inject Provider<Key> keyProvider

	override authenticate(String compactJws) throws AuthenticationException {
		try {
			// TODO this is a dummy impl only...
//			val claims = Jwts.parser.setSigningKey(keyProvider.get).parseClaimsJws(compactJws)
//			val user = claims.body.subject
//			val email = claims.body.get("email") as String
			val split = compactJws.split(":")
			val user = split.head
			val email = split.last
			return Optional.of(new User(user, email))
		} catch (SignatureException e) {
			return Optional.empty
		}
	}

}
