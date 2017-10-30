package org.testeditor.web.dropwizard

import org.junit.Test
import org.testeditor.web.dropwizard.auth.User

import static javax.ws.rs.core.Response.Status.*

class ExampleApplicationIntegrationTest extends AbstractIntegrationTest {

    @Test
    def void canAccessHelloWorldResource() {
        // given
        val request = createRequest('helloworld').buildGet

        // when
        val response = request.submit.get

        // then
        response.status.assertEquals(OK.statusCode)
    }

    @Test
    def void retrievesCorrectUser() {
        // given
        val request = createRequest('user').buildGet

        // when
        val response = request.submit.get

        // then
        response.status.assertEquals(OK.statusCode)
        val user = response.readEntity(User)
        user.id.assertEquals('johndoe')
        user.name.assertEquals('John Doe')
        user.email.assertEquals('john@example.org')
    }

}
