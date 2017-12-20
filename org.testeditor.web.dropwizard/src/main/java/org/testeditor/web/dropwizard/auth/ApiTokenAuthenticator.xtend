package org.testeditor.web.dropwizard.auth

import io.dropwizard.auth.AuthenticationException
import io.dropwizard.auth.Authenticator
import java.util.Optional
import org.eclipse.xtend.lib.annotations.Accessors

class ApiTokenAuthenticator implements Authenticator<String, User> {
	
	@Accessors(PUBLIC_SETTER)
	String apiToken
	
	override authenticate(String credentials) throws AuthenticationException {
		if (!apiToken.nullOrEmpty && credentials == apiToken) { 
			return Optional.of(new User('_apiToken', 'apiToken', 'api.token@example.com'))
		} else {
			return Optional.empty
		}
	}

}
