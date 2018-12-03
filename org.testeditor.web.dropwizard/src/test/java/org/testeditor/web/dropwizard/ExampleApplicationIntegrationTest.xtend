package org.testeditor.web.dropwizard

import io.dropwizard.testing.ConfigOverride
import java.util.List
import org.junit.Test
import org.testeditor.web.dropwizard.auth.User
import org.testeditor.web.dropwizard.testing.AbstractDropwizardIntegrationTest

import static javax.ws.rs.core.Response.Status.*

class ExampleApplicationIntegrationTest extends AbstractDropwizardIntegrationTest<ExampleConfiguration> {
	
	val validApiToken = '42'
	val invalidApiToken = '142'
	
	override protected getApplicationClass() {
		return ExampleApplication
	}

	override protected createConfiguration() {
		return (super.createConfiguration + #[
			ConfigOverride.config('apiToken', validApiToken),
			ConfigOverride.config('applicationId', 'org.testeditor.web.dropwizard')
		]).toList
	}
	
	@Test
	def void getVersions() {
		// given
		val request = createRequest('versions/all').buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
		response.readEntity(List).assertSingleElement.assertEquals('org.testeditor:org.testeditor.web.dropwizard:0.18.3')
	}

	@Test
	def void getExplicitDependenciesVersions() {
		// given
		val request = createRequest('versions/all?dependency=other').buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
		response.readEntity(List).assertSingleElement.assertEquals('org.testeditor:org.testeditor.other:0.1.0')
	}

	@Test
	def void explicitDependenciesVersionsEmpytIfNotExistent() {
		// given
		val request = createRequest('versions/all?dependency=notExistent').buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
		response.readEntity(List).assertEmpty
	}


	@Test
	def void canAccessProtectedResourceWithJWT() {
		// given
		val request = createRequest('protected-resource').buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
	}
	
	@Test
	def void cannotAccessProtectedResourceWithInvalidApiToken() {
		// given
		val request = createRequestWithApiToken('protected-resource', invalidApiToken).buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(UNAUTHORIZED.statusCode)
	}


	@Test
	def void userCannotAccessApiProtectedResource() {
		// given
		val request = createRequest('api-token-protected-resource').buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(UNAUTHORIZED.statusCode)
	}


	@Test
	def void canAccessApiProtectedResourceWithApiToken() {
		// given
		val request = createRequestWithApiToken('api-token-protected-resource', validApiToken).buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
	}

	@Test
	def void cannotAccessProtectedResourceWithApiToken() {
		// given
		val request = createRequestWithApiToken('protected-resource', validApiToken).buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(UNAUTHORIZED.statusCode)
	}

	@Test
	def void canAccessNoauthOnMethodUnauthorized() {
		// given
		val request = createRequestWithoutAuthorization('noauth-on-method').buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
	}

	@Test
	def void canAccessNoauthOnClassResourceUnauthorized() {
		// given
		val request = createRequestWithoutAuthorization('noauth-on-class').buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
	}

	@Test
	def void cannotAccessProtectedResourceUnauthorized() {
		// given
		val request = createRequestWithoutAuthorization('protected-resource').buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(UNAUTHORIZED.statusCode)
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
