package org.testeditor.web.dropwizard.auth

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import org.junit.Test

import static org.junit.Assert.*

class JWTAuthenticatorTest {

    JWTAuthenticator authenticator = new JWTAuthenticator

    static def String createToken() {
        val builder = JWT.create => [
            withClaim('id', 'johndoe')
            withClaim('name', 'John Doe')
            withClaim('email', 'john@example.org')
        ]
        return builder.sign(Algorithm.HMAC256("secret"))
    }

    @Test
    def void authenticateSimpleUser() {
        // given
        val jwt = createToken
        val header = 'Bearer ' + jwt

        // when
        val user = authenticator.authenticate(header)

        // then
        assertTrue(user.isPresent)
        user.get => [
            assertEquals("johndoe", id)
            assertEquals("John Doe", name)
            assertEquals("john@example.org", email)
        ]
    }

}
