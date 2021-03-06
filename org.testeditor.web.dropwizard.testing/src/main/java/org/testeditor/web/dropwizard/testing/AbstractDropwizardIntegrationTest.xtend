package org.testeditor.web.dropwizard.testing

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import de.xtendutils.junit.AssertionHelper
import io.dropwizard.Application
import io.dropwizard.Configuration
import io.dropwizard.testing.ConfigOverride
import io.dropwizard.testing.junit.DropwizardAppRule
import java.util.List
import javax.ws.rs.client.Invocation.Builder
import org.junit.Rule
import org.junit.rules.RuleChain

import static io.dropwizard.testing.ConfigOverride.config

/**
 * Reusable abstract base class for Dropwizard integration tests.
 */
abstract class AbstractDropwizardIntegrationTest<C extends Configuration> {

	protected val dropwizardAppRule = createDropwizardAppRule

	@Rule
	public RuleChain ruleChain = RuleChain.outerRule(dropwizardAppRule)

	protected extension val AssertionHelper = AssertionHelper.instance
	protected String token = createToken()

	protected def DropwizardAppRule<C> createDropwizardAppRule() {
		return new DropwizardAppRule<C>(applicationClass, null, createConfiguration)
	}

	/**
	 * Implement this method for the Dropwizard application that shall be tested.
	 */
	protected def Class<? extends Application<C>> getApplicationClass()

	protected def List<ConfigOverride> createConfiguration() {
		val result = newLinkedList
		result += config('server.applicationConnectors[0].port', '0')
		result += config('server.adminConnectors[0].port', '0')
		return result
	}

	protected def String createToken() {
		val builder = JWT.create => [
			withClaim('id', 'johndoe')
			withClaim('name', 'John Doe')
			withClaim('email', 'john@example.org')
		]
		return builder.sign(Algorithm.HMAC256("secret"))
	}

	protected def Builder createRequest(String relativePath) {
		val builder = createRequestWithoutAuthorization(relativePath)
		builder.header('Authorization', '''Bearer «token»''')
		return builder
	}

	protected def Builder createRequestWithApiToken(String relativePath, String apiToken) {
		val uri = '''«relativePath.createUri»?apiToken=«apiToken»'''
		val builder = dropwizardAppRule.client.target(uri).request
		return builder
	}

	protected def Builder createRequestWithoutAuthorization(String relativePath) {
		val builder = dropwizardAppRule.client.target(relativePath.createUri).request
		return builder
	}
	
	protected def String createUri(String relativePath) {
		return '''http://localhost:«dropwizardAppRule.localPort»/«relativePath»'''
	}

}
